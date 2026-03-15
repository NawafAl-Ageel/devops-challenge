###############################################################################
# IAM - Reviewer Access (Least Privilege)
###############################################################################

# Viewer role - allows reviewing the deployed environment
resource "google_project_iam_member" "reviewer_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "user:${var.reviewer_email}"
}

# GKE cluster viewer - allows viewing GKE cluster details
resource "google_project_iam_member" "reviewer_gke_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "user:${var.reviewer_email}"
}

# IAP-secured Tunnel User - allows SSH to bastion via IAP
resource "google_project_iam_member" "reviewer_iap_tunnel" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "user:${var.reviewer_email}"
}

# Compute OS Login - allows OS Login via IAP
resource "google_project_iam_member" "reviewer_os_login" {
  project = var.project_id
  role    = "roles/compute.osLogin"
  member  = "user:${var.reviewer_email}"
}

# Monitoring viewer - allows viewing monitoring dashboards and alerts
resource "google_project_iam_member" "reviewer_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "user:${var.reviewer_email}"
}

# Logging viewer - allows viewing logs
resource "google_project_iam_member" "reviewer_logging_viewer" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "user:${var.reviewer_email}"
}
