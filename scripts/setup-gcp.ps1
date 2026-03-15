###############################################################################
# setup-gcp.ps1
# Initial GCP project setup script for Windows PowerShell.
# Run this BEFORE terraform apply.
# Creates the GCS bucket for Terraform remote state and enables APIs.
#
# Usage: .\scripts\setup-gcp.ps1 -ProjectId "your-project-id" [-Region "us-central1"]
###############################################################################
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,

    [Parameter(Mandatory=$false)]
    [string]$Region = "us-central1"
)

$BucketName = "devops-challenge-tfstate-bucket"

Write-Host "============================================="
Write-Host " GCP Project Setup"
Write-Host "============================================="
Write-Host "Project: $ProjectId"
Write-Host "Region:  $Region"
Write-Host "Bucket:  $BucketName"
Write-Host "============================================="

# Set project
Write-Host "[1/3] Setting project..."
gcloud config set project $ProjectId

# Enable required APIs
Write-Host "[2/3] Enabling required APIs..."
gcloud services enable `
  compute.googleapis.com `
  container.googleapis.com `
  artifactregistry.googleapis.com `
  redis.googleapis.com `
  servicenetworking.googleapis.com `
  iap.googleapis.com `
  monitoring.googleapis.com `
  logging.googleapis.com `
  cloudresourcemanager.googleapis.com `
  iam.googleapis.com `
  --project=$ProjectId

# Create GCS bucket for Terraform state
Write-Host "[3/3] Creating Terraform state bucket..."
$bucketExists = gsutil ls -b "gs://$BucketName" 2>$null
if ($bucketExists) {
    Write-Host "Bucket $BucketName already exists."
} else {
    gsutil mb -p $ProjectId -l $Region -b on "gs://$BucketName"
    gsutil versioning set on "gs://$BucketName"
    Write-Host "Bucket $BucketName created with versioning enabled."
}

Write-Host ""
Write-Host "============================================="
Write-Host " Setup Complete!"
Write-Host "============================================="
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. cd terraform\"
Write-Host "  2. Copy terraform.tfvars.example to terraform.tfvars"
Write-Host "  3. terraform init"
Write-Host "  4. terraform plan"
Write-Host "  5. terraform apply"
