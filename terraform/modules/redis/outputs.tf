output "redis_host" {
  description = "The IP address of the Redis instance"
  value       = google_redis_instance.cache.host
}

output "redis_port" {
  description = "The port of the Redis instance"
  value       = google_redis_instance.cache.port
}

output "redis_instance_name" {
  description = "The name of the Redis instance"
  value       = google_redis_instance.cache.name
}
