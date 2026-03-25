terraform {
  required_version = "~> 1.0.8"
  backend "gcs" {}
}

variable "project_id" { type = string }
variable "region"     { type = string }

variable "datasets" {
  type = map(object({ labels = map(string) }))
}

variable "buckets" {
  type = map(object({
    location      = string
    storage_class = string
    labels        = map(string)
    versioning    = optional(bool, false)
    force_destroy = optional(bool, false)
  }))
  default = {}
}

# ── BigQuery datasets ────────────────────────────────────────────────────────
resource "google_bigquery_dataset" "datasets" {
  for_each   = var.datasets
  project    = var.project_id
  dataset_id = each.key
  location   = var.region
  labels     = each.value.labels
  delete_contents_on_destroy = false
}

# ── GCS buckets ──────────────────────────────────────────────────────────────
resource "google_storage_bucket" "buckets" {
  for_each      = var.buckets
  project       = var.project_id
  name          = each.key
  location      = each.value.location
  storage_class = each.value.storage_class
  labels        = each.value.labels
  force_destroy = each.value.force_destroy

  versioning {
    enabled = each.value.versioning
  }

  uniform_bucket_level_access = true
}
