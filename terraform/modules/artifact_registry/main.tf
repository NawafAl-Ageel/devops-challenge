###############################################################################
# Artifact Registry Repository
###############################################################################
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "${var.environment}-docker-repo"
  description   = "Docker repository for application images"
  format        = "DOCKER"
  project       = var.project_id

  cleanup_policy_dry_run = false
}
