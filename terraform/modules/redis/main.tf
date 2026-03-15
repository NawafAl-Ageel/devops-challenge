###############################################################################
# Memorystore Redis Instance
###############################################################################
resource "google_redis_instance" "cache" {
  name               = "${var.environment}-redis"
  tier               = "STANDARD_HA"
  memory_size_gb     = var.memory_size_gb
  region             = var.region
  project            = var.project_id
  authorized_network = var.vpc_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  redis_version      = "REDIS_7_0"

  display_name = "${var.environment} Redis Cache"

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 2
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  depends_on = [google_service_networking_connection.private_service_connection]
}

###############################################################################
# Private Service Access (required for Memorystore)
###############################################################################
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.environment}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}
