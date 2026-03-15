terraform {
  backend "gcs" {
    bucket = "devops-challenge-tfstate-bucket"
    prefix = "terraform/state"
  }
}
