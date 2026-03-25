variable "project_id" { type = string }
variable "dataset_id" { type = string }
variable "location"   { type = string }

variable "dataset_labels" {
  type    = map(string)
  default = {}
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "tables" {
  type = list(object({
    table_id        = string
    schema          = string
    labels          = map(string)
    expiration_time = optional(number)
    clustering      = optional(list(string), [])
    time_partitioning = optional(object({
      type                     = string
      field                    = optional(string)
      expiration_ms            = optional(number)
      require_partition_filter = optional(bool, false)
    }))
    range_partitioning = optional(object({
      field = string
      range = object({
        start    = number
        end      = number
        interval = number
      })
    }))
  }))
  default = []
}

variable "views" {
  type = list(object({
    view_id        = string
    use_legacy_sql = optional(bool, false)
    labels         = optional(map(string), {})
    query          = string
  }))
  default = []
}

variable "routines" {
  type = list(object({
    routine_id      = string
    routine_type    = string
    language        = string
    definition_body = string
    description     = optional(string, "")
    return_type     = optional(string)
    arguments       = optional(list(object({
      name      = string
      data_type = string
    })), [])
  }))
  default = []
}

variable "access" {
  type    = list(any)
  default = []
}
