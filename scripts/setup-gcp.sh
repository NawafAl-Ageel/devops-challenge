#!/bin/bash
###############################################################################
# setup-gcp.sh
# Initial GCP project setup script. Run this BEFORE terraform apply.
# Creates the GCS bucket for Terraform remote state.
###############################################################################
set -euo pipefail

PROJECT_ID="${1:?Usage: ./setup-gcp.sh <PROJECT_ID> [REGION]}"
REGION="${2:-us-central1}"
BUCKET_NAME="devops-challenge-tfstate-bucket"

echo "============================================="
echo " GCP Project Setup"
echo "============================================="
echo "Project: ${PROJECT_ID}"
echo "Region:  ${REGION}"
echo "Bucket:  ${BUCKET_NAME}"
echo "============================================="

# Authenticate (if not already)
echo "[1/4] Checking authentication..."
gcloud auth list --filter=status:ACTIVE --format="value(account)" || {
  echo "Please authenticate first: gcloud auth login"
  exit 1
}

# Set project
echo "[2/4] Setting project..."
gcloud config set project "${PROJECT_ID}"

# Enable required APIs
echo "[3/4] Enabling required APIs..."
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  redis.googleapis.com \
  servicenetworking.googleapis.com \
  iap.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  --project="${PROJECT_ID}"

# Create GCS bucket for Terraform state
echo "[4/4] Creating Terraform state bucket..."
if gsutil ls -b "gs://${BUCKET_NAME}" 2>/dev/null; then
  echo "Bucket ${BUCKET_NAME} already exists."
else
  gsutil mb -p "${PROJECT_ID}" -l "${REGION}" -b on "gs://${BUCKET_NAME}"
  gsutil versioning set on "gs://${BUCKET_NAME}"
  echo "Bucket ${BUCKET_NAME} created with versioning enabled."
fi

echo ""
echo "============================================="
echo " Setup Complete!"
echo "============================================="
echo ""
echo "Next steps:"
echo "  1. cd terraform/"
echo "  2. Copy terraform.tfvars.example to terraform.tfvars and fill in your values"
echo "  3. terraform init"
echo "  4. terraform plan"
echo "  5. terraform apply"
