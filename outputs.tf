output "dataset_ids" {
  value = {
    for k, v in google_bigquery_dataset.datasets : k => v.dataset_id
  }
}

output "bucket_names" {
  value = {
    for k, v in google_storage_bucket.buckets : k => v.name
  }
}

output "project_id" {
  value = var.project_id
}
