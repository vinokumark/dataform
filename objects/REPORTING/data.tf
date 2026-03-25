data "terraform_remote_state" "infra" {
  backend = "gcs"
  config = {
    bucket = var.tfstate_bucket
    prefix = "infra/${var.environment}"
  }
  defaults = {
    dataset_ids  = { APT = "", ARIBA = "", DATASET2 = "", REPORTING = "" }
    project_id   = ""
    bucket_names = {}
  }
}

locals {
  dataset_id        = data.terraform_remote_state.infra.outputs.dataset_ids["REPORTING"]
  project_id        = data.terraform_remote_state.infra.outputs.project_id
  apt_dataset_id    = data.terraform_remote_state.infra.outputs.dataset_ids["APT"]
  dataset2_dataset_id = data.terraform_remote_state.infra.outputs.dataset_ids["DATASET2"]
}
