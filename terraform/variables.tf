variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "authorized_source_ranges" {
  description = "CIDR ranges authorized to access the bastion via IAP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "reviewer_email" {
  description = "Email of the reviewer who needs access to the environment"
  type        = string
  default     = "atef.mahmoud@devoteam.com"
}

variable "gke_num_nodes" {
  description = "Number of GKE nodes"
  type        = number
  default     = 2
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "bastion_machine_type" {
  description = "Machine type for the bastion host"
  type        = string
  default     = "e2-micro"
}

variable "redis_memory_size_gb" {
  description = "Memory size in GB for Redis instance"
  type        = number
  default     = 1
}

variable "notification_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}
