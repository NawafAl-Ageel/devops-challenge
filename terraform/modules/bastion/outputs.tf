output "bastion_name" {
  description = "The name of the bastion host"
  value       = google_compute_instance.bastion.name
}

output "bastion_internal_ip" {
  description = "The internal IP of the bastion host"
  value       = google_compute_instance.bastion.network_interface[0].network_ip
}

output "bastion_zone" {
  description = "The zone of the bastion host"
  value       = google_compute_instance.bastion.zone
}

output "bastion_service_account_email" {
  description = "The email of the bastion service account"
  value       = google_service_account.bastion_sa.email
}
