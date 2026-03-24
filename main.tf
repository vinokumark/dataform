terraform {
  required_version = "~> 1.0.8"
  backend "gcs" {}
}

variable "project_id" { type = string }
variable "region"     { type = string }
variable "datasets" {
  type = map(object({ labels = map(string) }))
}

resource "google_bigquery_dataset" "datasets" {
  for_each   = var.datasets
  project    = var.project_id
  dataset_id = each.key
  location   = var.region
  labels     = each.value.labels
  delete_contents_on_destroy = false
}
