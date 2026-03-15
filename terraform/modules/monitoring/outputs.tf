output "notification_channel_id" {
  description = "The ID of the notification channel"
  value       = google_monitoring_notification_channel.email.name
}

output "uptime_check_id" {
  description = "The ID of the uptime check"
  value       = google_monitoring_uptime_check_config.app_health.uptime_check_id
}
