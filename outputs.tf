output "dataset_ids" {
  value = {
    for k, v in google_bigquery_dataset.datasets : k => v.dataset_id
  }
}

output "project_id" {
  value = var.project_id
}
