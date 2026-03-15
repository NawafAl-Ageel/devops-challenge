output "reviewer_roles" {
  description = "List of roles assigned to the reviewer"
  value = [
    "roles/viewer",
    "roles/container.clusterViewer",
    "roles/iap.tunnelResourceAccessor",
    "roles/compute.osLogin",
    "roles/monitoring.viewer",
    "roles/logging.viewer",
  ]
}
