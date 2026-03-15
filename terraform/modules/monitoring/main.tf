###############################################################################
# Notification Channel
###############################################################################
resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.environment}-email-notification"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = var.notification_email
  }
}

###############################################################################
# Uptime Check - Application Health
###############################################################################
resource "google_monitoring_uptime_check_config" "app_health" {
  display_name = "${var.environment}-app-uptime-check"
  timeout      = "10s"
  period       = "60s"
  project      = var.project_id

  http_check {
    path         = "/"
    port         = 80
    use_ssl      = false
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.app_lb_ip
    }
  }
}

###############################################################################
# Alert Policy - Application Unavailable
###############################################################################
resource "google_monitoring_alert_policy" "app_unavailable" {
  display_name = "${var.environment}-app-unavailable-alert"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Application Uptime Check Failed"

    condition_threshold {
      filter          = "resource.type = \"uptime_url\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.labels.check_id = \"${google_monitoring_uptime_check_config.app_health.uptime_check_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.project_id"]
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "The application deployed on GKE is not responding to health checks. Please investigate the application pods and load balancer configuration."
    mime_type = "text/markdown"
  }
}

###############################################################################
# Alert Policy - GKE Node CPU High
###############################################################################
resource "google_monitoring_alert_policy" "gke_node_cpu" {
  display_name = "${var.environment}-gke-node-high-cpu"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "GKE Node CPU > 80%"

    condition_threshold {
      filter          = "resource.type = \"k8s_node\" AND metric.type = \"kubernetes.io/node/cpu/allocatable_utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    auto_close = "1800s"
  }
}
