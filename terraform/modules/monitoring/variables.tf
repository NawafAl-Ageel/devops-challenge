variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "notification_email" {
  description = "Email address for alert notifications"
  type        = string
}

variable "app_lb_ip" {
  description = "The IP address of the application load balancer"
  type        = string
  default     = ""
}
