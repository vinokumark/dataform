module "bq_reporting" {
  source = "../../modules/bq"

  project_id          = local.project_id
  dataset_id          = local.dataset_id
  location            = var.region
  dataset_labels      = var.dataset_labels
  deletion_protection = true

  tables = [for t in var.reporting_tables : {
    table_id           = upper(t.id)
    schema             = file("../../bigQuery/REPORTING/tables/${upper(t.id)}.json")
    labels             = {}
    expiration_time    = null
    clustering         = try(t.clustflag == true ? t.clustering : [], [])
    time_partitioning  = try(
      t.timePartitioned == true
        ? jsondecode(file("../../bigQuery/REPORTING/tables/${upper(t.id)}_timePartitioning.json"))[0]
        : null, null)
    range_partitioning = try(
      t.rangePartitioned == true
        ? jsondecode(file("../../bigQuery/REPORTING/tables/${upper(t.id)}_rangePartitioning.json"))[0]
        : null, null)
  }]

  views = [for v in var.reporting_views : {
    view_id        = upper(v.id)
    use_legacy_sql = false
    labels         = {}
    query = templatefile(
      "../../bigQuery/REPORTING/views/${upper(v.id)}.sql",
      { projectid = local.project_id, datasetname = local.dataset_id }
    )
  }]

  routines = [for r in var.reporting_routines : {
    routine_id      = upper(r.id)
    routine_type    = "PROCEDURE"
    language        = "SQL"
    definition_body = templatefile(
      "../../bigQuery/REPORTING/routines/${upper(r.id)}.sql",
      { projectid = local.project_id, datasetname = local.dataset_id }
    )
    description = ""
    return_type = null
    arguments   = try(r.hasArgs == true
      ? jsondecode(file("../../bigQuery/REPORTING/routines/${upper(r.id)}_args.json"))
      : [], [])
  }]

  access = []
}
