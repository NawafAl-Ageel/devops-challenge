output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The self link of the VPC"
  value       = google_compute_network.vpc.self_link
}

output "restricted_subnet_id" {
  description = "The ID of the restricted subnet"
  value       = google_compute_subnetwork.restricted.id
}

output "restricted_subnet_name" {
  description = "The name of the restricted subnet"
  value       = google_compute_subnetwork.restricted.name
}

output "restricted_subnet_cidr" {
  description = "The CIDR of the restricted subnet"
  value       = google_compute_subnetwork.restricted.ip_cidr_range
}

output "management_subnet_id" {
  description = "The ID of the management subnet"
  value       = google_compute_subnetwork.management.id
}

output "management_subnet_name" {
  description = "The name of the management subnet"
  value       = google_compute_subnetwork.management.name
}

output "management_subnet_cidr" {
  description = "The CIDR of the management subnet"
  value       = google_compute_subnetwork.management.ip_cidr_range
}

output "pods_range_name" {
  description = "The name of the pods secondary range"
  value       = google_compute_subnetwork.restricted.secondary_ip_range[0].range_name
}

output "services_range_name" {
  description = "The name of the services secondary range"
  value       = google_compute_subnetwork.restricted.secondary_ip_range[1].range_name
}
