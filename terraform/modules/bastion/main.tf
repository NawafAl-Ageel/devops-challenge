###############################################################################
# Bastion Host Service Account
###############################################################################
resource "google_service_account" "bastion_sa" {
  account_id   = "${var.environment}-bastion-sa"
  display_name = "Bastion Host Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "bastion_gke_access" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.bastion_sa.email}"
}

resource "google_project_iam_member" "bastion_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.bastion_sa.email}"
}

resource "google_project_iam_member" "bastion_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.bastion_sa.email}"
}

resource "google_project_iam_member" "bastion_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.bastion_sa.email}"
}

###############################################################################
# Bastion Host VM (Ubuntu 20.04 - No Public IP)
###############################################################################
resource "google_compute_instance" "bastion" {
  name         = "${var.environment}-bastion-host"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["bastion"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-2004-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    # No access_config block = no public IP
  }

  service_account {
    email  = google_service_account.bastion_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  allow_stopping_for_update = true
}
