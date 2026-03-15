###############################################################################
# Static IP for the Application Load Balancer
###############################################################################
resource "google_compute_global_address" "app_lb_ip" {
  name    = "demo-app-static-ip"
  project = var.project_id
}

output "app_lb_ip" {
  description = "The static IP address for the application load balancer"
  value       = google_compute_global_address.app_lb_ip.address
}
