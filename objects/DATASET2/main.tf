# dataset2 depends on apt (see .depends_on file)
# views reference apt tables — apt must deploy first

data "terraform_remote_state" "infra_for_apt" {
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
  apt_dataset_id = data.terraform_remote_state.infra_for_apt.outputs.dataset_ids["APT"]
}

module "bq_dataset2" {
  source = "../../modules/bq"

  project_id          = local.project_id
  dataset_id          = local.dataset_id
  location            = var.region
  dataset_labels      = var.dataset_labels
  deletion_protection = true

  tables = [for t in var.dataset2_tables : {
    table_id           = upper(t.id)
    schema             = file("../../bigQuery/DATASET2/tables/${upper(t.id)}.json")
    labels             = {}
    expiration_time    = null
    clustering         = []
    time_partitioning  = null
    range_partitioning = null
  }]

  views = [for v in var.dataset2_views : {
    view_id        = upper(v.id)
    use_legacy_sql = false
    labels         = {}
    query = templatefile(
      "../../bigQuery/DATASET2/views/${upper(v.id)}.sql",
      {
        projectid          = local.project_id
        datasetname        = local.dataset_id
        aptdatasetname     = local.apt_dataset_id  # cross-dataset reference
      }
    )
  }]

  routines = []
  access   = []
}
