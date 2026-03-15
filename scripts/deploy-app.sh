#!/bin/bash
###############################################################################
# deploy-app.sh
# Run this script FROM the bastion host after Terraform has been applied.
# It builds the Docker image, pushes to Artifact Registry, and deploys to GKE.
###############################################################################
set -euo pipefail

# ---- Configuration (set these before running) ----
PROJECT_ID="${PROJECT_ID:?Please set PROJECT_ID}"
REGION="${REGION:-us-central1}"
REPO_NAME="${REPO_NAME:-prod-docker-repo}"
CLUSTER_NAME="${CLUSTER_NAME:-prod-gke-cluster}"
REDIS_HOST="${REDIS_HOST:?Please set REDIS_HOST from Terraform output}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/demo-app:${IMAGE_TAG}"

echo "============================================="
echo " DevOps Challenge - Application Deployment"
echo "============================================="
echo "Project:  ${PROJECT_ID}"
echo "Region:   ${REGION}"
echo "Image:    ${IMAGE_URI}"
echo "Cluster:  ${CLUSTER_NAME}"
echo "Redis:    ${REDIS_HOST}"
echo "============================================="

# Step 1: Authenticate Docker with Artifact Registry
echo "[1/6] Configuring Docker authentication..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

# Step 2: Clone the demo application
echo "[2/6] Cloning demo application..."
if [ -d "DevOps-Challenge-Demo-Code" ]; then
  rm -rf DevOps-Challenge-Demo-Code
fi
git clone https://github.com/atefhares/DevOps-Challenge-Demo-Code.git
cp /tmp/Dockerfile DevOps-Challenge-Demo-Code/ 2>/dev/null || true

# Step 3: Build Docker image
echo "[3/6] Building Docker image..."
cd DevOps-Challenge-Demo-Code
if [ ! -f Dockerfile ]; then
  cat > Dockerfile << 'DOCKERFILE'
FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8000/ || exit 1

RUN useradd -m appuser
USER appuser

ENV ENVIRONMENT=PROD \
    HOST=0.0.0.0 \
    PORT=8000 \
    REDIS_PORT=6379 \
    REDIS_DB=0

CMD ["python", "hello.py"]
DOCKERFILE
fi
docker build -t "${IMAGE_URI}" .
cd ..

# Step 4: Push Docker image to Artifact Registry
echo "[4/6] Pushing Docker image to Artifact Registry..."
docker push "${IMAGE_URI}"

# Step 5: Connect to GKE cluster
echo "[5/6] Connecting to GKE cluster..."
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --internal-ip

# Step 6: Deploy to Kubernetes
echo "[6/6] Deploying application to GKE..."

# Apply namespace
kubectl apply -f /tmp/k8s/namespace.yaml 2>/dev/null || \
  kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f -

# Create/update ConfigMap with actual Redis host
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: demo-app
data:
  REDIS_HOST: "${REDIS_HOST}"
  REDIS_PORT: "6379"
EOF

# Apply deployment with actual image
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: demo-app
  labels:
    app: demo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
        - name: demo-app
          image: ${IMAGE_URI}
          ports:
            - containerPort: 8000
              protocol: TCP
          env:
            - name: ENVIRONMENT
              value: "PROD"
            - name: HOST
              value: "0.0.0.0"
            - name: PORT
              value: "8000"
            - name: REDIS_HOST
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: REDIS_HOST
            - name: REDIS_PORT
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: REDIS_PORT
            - name: REDIS_DB
              value: "0"
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "256Mi"
          livenessProbe:
            httpGet:
              path: /
              port: 8000
            initialDelaySeconds: 15
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /
              port: 8000
            initialDelaySeconds: 5
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 3
      restartPolicy: Always
EOF

# Apply service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: demo-app-service
  namespace: demo-app
  labels:
    app: demo-app
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
    cloud.google.com/backend-config: '{"default": "demo-app-backend-config"}'
spec:
  type: NodePort
  selector:
    app: demo-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
EOF

# Apply BackendConfig
cat <<EOF | kubectl apply -f -
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: demo-app-backend-config
  namespace: demo-app
spec:
  healthCheck:
    checkIntervalSec: 15
    timeoutSec: 5
    healthyThreshold: 2
    unhealthyThreshold: 3
    type: HTTP
    requestPath: /
    port: 8000
EOF

# Apply Ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-app-ingress
  namespace: demo-app
  annotations:
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ingress.global-static-ip-name: "demo-app-static-ip"
spec:
  defaultBackend:
    service:
      name: demo-app-service
      port:
        number: 80
EOF

# Apply HPA
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: demo-app-hpa
  namespace: demo-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: demo-app
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
EOF

echo ""
echo "============================================="
echo " Deployment Complete!"
echo "============================================="
echo ""
echo "Waiting for pods to be ready..."
kubectl rollout status deployment/demo-app -n demo-app --timeout=120s

echo ""
echo "Pod Status:"
kubectl get pods -n demo-app

echo ""
echo "Service Status:"
kubectl get svc -n demo-app

echo ""
echo "Ingress Status (may take 5-10 minutes for LB to be ready):"
kubectl get ingress -n demo-app

echo ""
echo "Static IP for the application:"
echo "  http://$(gcloud compute addresses describe demo-app-static-ip --global --format='value(address)' --project=${PROJECT_ID})"
echo ""
echo "NOTE: The GCP HTTP Load Balancer may take 5-10 minutes to fully provision."
