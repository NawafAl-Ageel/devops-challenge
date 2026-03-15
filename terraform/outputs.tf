###############################################################################
# Outputs
###############################################################################

output "vpc_name" {
  description = "The name of the VPC"
  value       = module.vpc.vpc_name
}

output "restricted_subnet_name" {
  description = "The name of the restricted subnet"
  value       = module.vpc.restricted_subnet_name
}

output "management_subnet_name" {
  description = "The name of the management subnet"
  value       = module.vpc.management_subnet_name
}

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster (private)"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "bastion_name" {
  description = "The name of the bastion host"
  value       = module.bastion.bastion_name
}

output "bastion_internal_ip" {
  description = "The internal IP of the bastion host"
  value       = module.bastion.bastion_internal_ip
}

output "bastion_zone" {
  description = "The zone of the bastion host"
  value       = module.bastion.bastion_zone
}

output "artifact_registry_url" {
  description = "The URL of the Artifact Registry repository"
  value       = module.artifact_registry.repository_url
}

output "redis_host" {
  description = "The IP address of the Redis instance"
  value       = module.redis.redis_host
}

output "redis_port" {
  description = "The port of the Redis instance"
  value       = module.redis.redis_port
}

output "ssh_to_bastion_command" {
  description = "Command to SSH into bastion via IAP"
  value       = "gcloud compute ssh ${module.bastion.bastion_name} --zone=${module.bastion.bastion_zone} --tunnel-through-iap --project=${var.project_id}"
}

output "connect_to_gke_command" {
  description = "Command to run on bastion to connect to GKE"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region=${var.region} --project=${var.project_id} --internal-ip"
}
