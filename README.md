# DevOps Challenge - GCP Infrastructure & Application Deployment

## Architecture Overview

This project provisions a **secure, production-grade GCP infrastructure** using Terraform and deploys a Python web application on a private GKE cluster, exposed via a GCP HTTP Load Balancer.

### Architecture Diagram

```
                    ┌──────────────────────────────────────────────────────────┐
                    │                     GCP Project                          │
                    │                                                          │
Internet ──────────►│  ┌─────────────────────┐                                │
       HTTP(S) LB   │  │   Global Static IP   │                                │
                    │  │   + HTTP LB (Ingress) │                                │
                    │  └──────────┬────────────┘                                │
                    │             │                                             │
                    │  ┌──────────┴──────────────────────────────────────────┐  │
                    │  │                  Custom VPC                          │  │
                    │  │                                                      │  │
                    │  │  ┌──────────────────────┐  ┌─────────────────────┐  │  │
                    │  │  │  Restricted Subnet    │  │ Management Subnet   │  │  │
                    │  │  │  (10.0.1.0/24)        │  │ (10.0.2.0/24)       │  │  │
                    │  │  │                        │  │                     │  │  │
                    │  │  │  ┌──────────────────┐  │  │  ┌───────────────┐ │  │  │
                    │  │  │  │ Private GKE       │  │  │  │ Bastion Host  │ │  │  │
                    │  │  │  │ Cluster           │  │  │  │ (Ubuntu 20.04)│ │  │  │
                    │  │  │  │ (Regional)        │◄─┼──┼──│ No Public IP  │ │  │  │
                    │  │  │  │                    │  │  │  │ IAP SSH Only  │ │  │  │
                    │  │  │  │  ┌──────────────┐ │  │  │  └───────────────┘ │  │  │
                    │  │  │  │  │ demo-app pods│ │  │  │                     │  │  │
                    │  │  │  │  │ (2 replicas) │ │  │  └─────────────────────┘  │  │
                    │  │  │  │  └──────────────┘ │  │                           │  │
                    │  │  │  └──────────────────┘  │                           │  │
                    │  │  └──────────────────────┘                             │  │
                    │  │                                                      │  │
                    │  │  Cloud NAT ◄── Cloud Router                          │  │
                    │  └──────────────────────────────────────────────────────┘  │
                    │                                                          │
                    │  ┌──────────────────┐  ┌─────────────────────────────┐   │
                    │  │ Memorystore Redis │  │ Artifact Registry           │   │
                    │  │ (STANDARD_HA)     │  │ (Docker Repository)         │   │
                    │  └──────────────────┘  └─────────────────────────────┘   │
                    │                                                          │
                    │  ┌──────────────────┐  ┌─────────────────────────────┐   │
                    │  │ Cloud Monitoring  │  │ GCS (Terraform State)       │   │
                    │  │ Alerts & Uptime   │  │ Remote Backend              │   │
                    │  └──────────────────┘  └─────────────────────────────┘   │
                    └──────────────────────────────────────────────────────────┘
```

## Components

| Component | Description |
|---|---|
| **VPC** | Custom VPC with restricted and management subnets |
| **GKE Cluster** | Private regional cluster with private nodes and private endpoint |
| **Bastion Host** | Ubuntu 20.04 VM in management subnet, no public IP, IAP SSH only |
| **Artifact Registry** | Docker repository for container images |
| **Memorystore Redis** | STANDARD_HA Redis 7.0 cluster via Private Service Access |
| **Cloud NAT** | Outbound internet for private nodes |
| **Monitoring** | Uptime checks, alert policies, email notifications |
| **IAM** | Least-privilege roles for reviewer access |
| **Load Balancer** | GCP HTTP(S) LB via GKE Ingress with static IP |

## Project Structure

```
.
├── README.md
├── .gitignore
├── app/
│   ├── Dockerfile              # Multi-stage Docker build for the demo app
│   └── .dockerignore
├── k8s/
│   ├── namespace.yaml          # Kubernetes namespace
│   ├── deployment.yaml         # App deployment (2 replicas)
│   ├── service.yaml            # NodePort service with NEG
│   ├── ingress.yaml            # GCE Ingress for HTTP LB
│   ├── configmap.yaml          # Redis connection config
│   ├── hpa.yaml                # Horizontal Pod Autoscaler
│   └── backendconfig.yaml      # GCP BackendConfig for health checks
├── scripts/
│   ├── setup-gcp.sh            # Initial GCP setup (state bucket, APIs)
│   └── deploy-app.sh           # Build, push, deploy the application
└── terraform/
    ├── backend.tf              # GCS remote state backend
    ├── provider.tf             # Google provider configuration
    ├── versions.tf             # Terraform & provider versions
    ├── variables.tf            # Root variables
    ├── main.tf                 # Module orchestration
    ├── outputs.tf              # Root outputs
    ├── static_ip.tf            # Global static IP for LB
    ├── terraform.tfvars.example
    └── modules/
        ├── vpc/                # VPC, subnets, firewall, NAT, router
        ├── gke/                # Private GKE cluster & node pool
        ├── bastion/            # Bastion host VM with startup script
        ├── artifact_registry/  # Docker repository
        ├── redis/              # Memorystore Redis with PSA
        ├── iam/                # Reviewer IAM bindings
        └── monitoring/         # Uptime checks & alert policies
```

## Prerequisites

- **GCP Project** with billing enabled
- **gcloud CLI** installed and authenticated
- **Terraform** >= 1.5.0 installed
- **Docker** (on bastion or locally for testing)
- Sufficient IAM permissions (Owner or Editor role on the project)

## Deployment Guide

### Step 1: Initial GCP Setup

```bash
# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# Run the setup script (creates state bucket & enables APIs)
chmod +x scripts/setup-gcp.sh
./scripts/setup-gcp.sh YOUR_PROJECT_ID us-central1
```

### Step 2: Configure Terraform Variables

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual values
```

**Required variables:**
- `project_id` - Your GCP project ID
- `reviewer_email` - Email for reviewer IAM access (default: atef.mahmoud@devoteam.com)
- `notification_email` - Email for monitoring alerts

### Step 3: Deploy Infrastructure with Terraform

```bash
cd terraform/

# Initialize Terraform
terraform init

# Review the plan
terraform plan -out=tfplan

# Apply the infrastructure
terraform apply tfplan

# Note the outputs - you'll need them for app deployment
terraform output
```

### Step 4: Deploy the Application

SSH into the bastion host via IAP and deploy the application:

```bash
# SSH into bastion via IAP (from your local machine)
gcloud compute ssh prod-bastion-host \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --project=YOUR_PROJECT_ID

# On the bastion host, set environment variables
export PROJECT_ID="YOUR_PROJECT_ID"
export REGION="us-central1"
export REDIS_HOST="<redis_host from terraform output>"
export REPO_NAME="prod-docker-repo"
export CLUSTER_NAME="prod-gke-cluster"

# Copy and run the deploy script
# (You can SCP the script or paste it directly)
chmod +x deploy-app.sh
./deploy-app.sh
```

### Step 5: Verify Deployment

```bash
# Check pods are running
kubectl get pods -n demo-app

# Check service and ingress
kubectl get svc,ingress -n demo-app

# Get the external IP (may take 5-10 min for LB provisioning)
kubectl get ingress -n demo-app -w

# Or check the static IP
gcloud compute addresses describe demo-app-static-ip --global --format='value(address)'
```

Access the application at `http://<STATIC_IP>`

## Security Design

### Network Security
- **Private GKE cluster**: Both control plane and nodes have no public endpoints
- **Bastion host**: No public IP; accessible only via **IAP tunnel** (SSH)
- **Firewall rules**: Default-deny ingress with explicit allow rules for:
  - IAP SSH (35.235.240.0/20) → bastion
  - Bastion → GKE nodes (ports 443, 10250)
  - Internal VPC communication
  - GCP health check ranges → GKE nodes
- **Cloud NAT**: Provides outbound internet for private nodes without public IPs

### IAM (Least Privilege)
The reviewer (`atef.mahmoud@devoteam.com`) is granted:
| Role | Purpose |
|---|---|
| `roles/viewer` | View project resources |
| `roles/container.clusterViewer` | View GKE cluster details |
| `roles/iap.tunnelResourceAccessor` | SSH to bastion via IAP |
| `roles/compute.osLogin` | OS Login for bastion SSH |
| `roles/monitoring.viewer` | View monitoring dashboards |
| `roles/logging.viewer` | View application logs |

### Workload Security
- **Workload Identity** enabled on GKE
- **Shielded VMs** for both GKE nodes and bastion
- **OS Login** enabled on bastion (no SSH keys needed)
- GKE nodes use a **dedicated service account** with minimal permissions

## Monitoring & Alerting

- **Uptime Check**: HTTP health check against the application LB every 60 seconds
- **Alert Policies**:
  - Application unavailability (uptime check failure for 5+ minutes)
  - GKE node CPU utilization > 80%
- **Notifications**: Email alerts to configured address
- **GKE Logging**: System components + workload logs enabled
- **Managed Prometheus**: Enabled for metric collection

## Terraform Remote State

State is stored in a **GCS bucket** with versioning enabled:
- Bucket: `devops-challenge-tfstate-bucket`
- Prefix: `terraform/state`
- Versioning: Enabled (for state recovery)

## Cleanup

```bash
# Destroy all infrastructure
cd terraform/
terraform destroy

# Delete the state bucket (optional)
gsutil rm -r gs://devops-challenge-tfstate-bucket
```

## Design Decisions

1. **Regional GKE cluster** over zonal for higher availability
2. **IAP for SSH** instead of public SSH keys — more secure and auditable
3. **Cloud NAT** for outbound connectivity — private nodes can pull images and updates
4. **Memorystore STANDARD_HA** for Redis — automatic failover for production reliability
5. **BackendConfig + NEG** for health checks — native GCP integration with the HTTP LB
6. **Modular Terraform** — each component is a reusable module with clear interfaces
7. **Shielded VMs** everywhere — protection against rootkits and boot-level attacks
8. **OS Login** on bastion — centralized SSH access management via IAM

## License

MIT
