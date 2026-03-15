###############################################################################
# Enable Required APIs
###############################################################################
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "redis.googleapis.com",
    "servicenetworking.googleapis.com",
    "iap.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

###############################################################################
# VPC Module
###############################################################################
module "vpc" {
  source = "./modules/vpc"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  depends_on = [google_project_service.apis]
}

###############################################################################
# GKE Module
###############################################################################
module "gke" {
  source = "./modules/gke"

  project_id             = var.project_id
  region                 = var.region
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  subnet_id              = module.vpc.restricted_subnet_id
  pods_range_name        = module.vpc.pods_range_name
  services_range_name    = module.vpc.services_range_name
  management_subnet_cidr = module.vpc.management_subnet_cidr
  num_nodes              = var.gke_num_nodes
  machine_type           = var.gke_machine_type

  depends_on = [module.vpc]
}

###############################################################################
# Bastion Host Module
###############################################################################
module "bastion" {
  source = "./modules/bastion"

  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  environment  = var.environment
  subnet_id    = module.vpc.management_subnet_id
  machine_type = var.bastion_machine_type

  depends_on = [module.vpc]
}

###############################################################################
# Artifact Registry Module
###############################################################################
module "artifact_registry" {
  source = "./modules/artifact_registry"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  depends_on = [google_project_service.apis]
}

###############################################################################
# Redis (Memorystore) Module
###############################################################################
module "redis" {
  source = "./modules/redis"

  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  memory_size_gb = var.redis_memory_size_gb

  depends_on = [module.vpc, google_project_service.apis]
}

###############################################################################
# IAM Module
###############################################################################
module "iam" {
  source = "./modules/iam"

  project_id     = var.project_id
  reviewer_email = var.reviewer_email
}

###############################################################################
# Monitoring Module (conditional on notification_email)
###############################################################################
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.notification_email != "" ? 1 : 0

  project_id         = var.project_id
  environment        = var.environment
  notification_email = var.notification_email
  app_lb_ip          = google_compute_global_address.app_lb_ip.address

  depends_on = [module.gke, google_compute_global_address.app_lb_ip]
}
