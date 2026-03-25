data "terraform_remote_state" "infra" {
  backend = "gcs"
  config = {
    bucket = var.tfstate_bucket
    prefix = "infra/${var.environment}"
  }
}

locals {
  dataset_id = data.terraform_remote_state.infra.outputs.dataset_ids["REPORTING"]
  project_id = data.terraform_remote_state.infra.outputs.project_id
}
