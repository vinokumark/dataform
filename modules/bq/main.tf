resource "google_bigquery_table" "tables" {
  for_each = { for t in var.tables : t.table_id => t }

  project             = var.project_id
  dataset_id          = var.dataset_id
  table_id            = each.value.table_id
  schema              = each.value.schema
  labels              = each.value.labels
  expiration_time     = each.value.expiration_time
  deletion_protection = var.deletion_protection
  clustering          = length(coalesce(each.value.clustering, [])) > 0 ? each.value.clustering : null

  dynamic "time_partitioning" {
    for_each = each.value.time_partitioning != null ? [each.value.time_partitioning] : []
    content {
      type                     = time_partitioning.value.type
      field                    = time_partitioning.value.field
      expiration_ms            = time_partitioning.value.expiration_ms
      require_partition_filter = time_partitioning.value.require_partition_filter
    }
  }

  dynamic "range_partitioning" {
    for_each = each.value.range_partitioning != null ? [each.value.range_partitioning] : []
    content {
      field = range_partitioning.value.field
      range {
        start    = range_partitioning.value.range.start
        end      = range_partitioning.value.range.end
        interval = range_partitioning.value.range.interval
      }
    }
  }
}

resource "google_bigquery_table" "views" {
  for_each = { for v in var.views : v.view_id => v }

  project             = var.project_id
  dataset_id          = var.dataset_id
  table_id            = each.value.view_id
  labels              = each.value.labels
  deletion_protection = var.deletion_protection

  view {
    query          = each.value.query
    use_legacy_sql = each.value.use_legacy_sql
  }
}

resource "google_bigquery_routine" "routines" {
  for_each = { for r in var.routines : r.routine_id => r }

  project         = var.project_id
  dataset_id      = var.dataset_id
  routine_id      = each.value.routine_id
  routine_type    = each.value.routine_type
  language        = each.value.language
  definition_body = each.value.definition_body
  description     = each.value.description
  return_type     = each.value.return_type

  dynamic "arguments" {
    for_each = each.value.arguments
    content {
      name      = arguments.value.name
      data_type = arguments.value.data_type
    }
  }
}
