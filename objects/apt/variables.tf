variable "project_id"      { type = string }
variable "region"          { type = string }
variable "environment"     { type = string }
variable "tfstate_bucket"  { type = string }
variable "dataset_labels"  { type = map(string) }

variable "apt_tables" {
  type = list(object({
    id               = string
    clustflag        = optional(bool, false)
    clustering       = optional(list(string), [])
    timePartitioned  = optional(bool, false)
    rangePartitioned = optional(bool, false)
  }))
  default = []
}

variable "apt_views" {
  type = list(object({ id = string }))
  default = []
}

variable "apt_routines" {
  type = list(object({
    id      = string
    hasArgs = optional(bool, false)
  }))
  default = []
}
