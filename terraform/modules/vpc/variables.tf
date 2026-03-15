variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "restricted_subnet_cidr" {
  description = "CIDR range for the restricted subnet (GKE nodes)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "management_subnet_cidr" {
  description = "CIDR range for the management subnet (bastion)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.8.0.0/20"
}
