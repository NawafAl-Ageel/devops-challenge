#!/bin/bash
set -euo pipefail

PROJECT_ID="mc-nawaf-ag-sandbox1"
REGION="us-central1"
REPO_NAME="prod-docker-repo"
CLUSTER_NAME="prod-gke-cluster"
REDIS_HOST="10.249.0.4"
IMAGE_TAG="latest"
IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/demo-app:${IMAGE_TAG}"

echo "===== Step 1: Configure Docker auth ====="
sudo gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

echo "===== Step 2: Clone app ====="
rm -rf /tmp/app
git clone https://github.com/atefhares/DevOps-Challenge-Demo-Code.git /tmp/app

echo "===== Step 3: Create Dockerfile ====="
cat > /tmp/app/Dockerfile << 'DFILE'
FROM python:3.9-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD curl -f http://localhost:8000/ || exit 1
RUN useradd -m appuser
USER appuser
ENV ENVIRONMENT=PROD HOST=0.0.0.0 PORT=8000 REDIS_PORT=6379 REDIS_DB=0
CMD ["python", "hello.py"]
DFILE

echo "===== Step 4: Build Docker image ====="
cd /tmp/app
sudo docker build -t "${IMAGE_URI}" .

echo "===== Step 5: Push to Artifact Registry ====="
sudo docker push "${IMAGE_URI}"

echo "===== Step 6: Connect to GKE ====="
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --internal-ip

echo "===== Step 7: Deploy to Kubernetes ====="

kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f -

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
echo "===== Waiting for rollout ====="
kubectl rollout status deployment/demo-app -n demo-app --timeout=120s

echo ""
echo "===== Pod Status ====="
kubectl get pods -n demo-app

echo ""
echo "===== Services ====="
kubectl get svc -n demo-app

echo ""
echo "===== Ingress ====="
kubectl get ingress -n demo-app

echo ""
echo "===== DEPLOYMENT COMPLETE ====="
echo "App will be available at: http://136.110.186.14"
echo "(Load balancer may take 5-10 minutes to fully provision)"
