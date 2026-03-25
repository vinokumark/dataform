module "bq_ariba" {
  source = "../../modules/bq"

  project_id          = local.project_id
  dataset_id          = local.dataset_id
  location            = var.region
  dataset_labels      = var.dataset_labels
  deletion_protection = true

  tables = [for t in var.ariba_tables : {
    table_id           = upper(t.id)
    schema             = file("../../bigQuery/ARIBA/tables/${upper(t.id)}.json")
    labels             = {}
    expiration_time    = null
    clustering         = try(t.clustflag == true ? t.clustering : [], [])
    time_partitioning  = try(
      t.timePartitioned == true
        ? jsondecode(file("../../bigQuery/ARIBA/tables/${upper(t.id)}_timePartitioning.json"))[0]
        : null, null)
    range_partitioning = try(
      t.rangePartitioned == true
        ? jsondecode(file("../../bigQuery/ARIBA/tables/${upper(t.id)}_rangePartitioning.json"))[0]
        : null, null)
  }]

  views = [for v in var.ariba_views : {
    view_id        = upper(v.id)
    use_legacy_sql = false
    labels         = {}
    query = templatefile(
      "../../bigQuery/ARIBA/views/${upper(v.id)}.sql",
      { projectid = local.project_id, datasetname = local.dataset_id }
    )
  }]

  routines = [for r in var.ariba_routines : {
    routine_id      = upper(r.id)
    routine_type    = "PROCEDURE"
    language        = "SQL"
    definition_body = templatefile(
      "../../bigQuery/ARIBA/routines/${upper(r.id)}.sql",
      { projectid = local.project_id, datasetname = local.dataset_id }
    )
    description = ""
    return_type = null
    arguments   = try(r.hasArgs == true
      ? jsondecode(file("../../bigQuery/ARIBA/routines/${upper(r.id)}_args.json"))
      : [], [])
  }]

  access = []
}
