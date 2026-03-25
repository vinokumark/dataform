project_id  = "qwiklabs-gcp-02-848fd3d15653"
region      = "EU"

datasets = {
  "APT"       = { labels = { domain = "billing" } }
  "ARIBA"     = { labels = { domain = "procurement" } }
  "DATASET2"  = { labels = { domain = "finance" } }
  "REPORTING" = { labels = { domain = "reporting" } }
}

buckets = {
  "my-gcp-project-dev-tfstate" = {
    location      = "EU"
    storage_class = "STANDARD"
    labels        = { env = "dev", purpose = "tfstate" }
    versioning    = true
    force_destroy = false
  }
  "my-gcp-project-dev-dataform" = {
    location      = "EU"
    storage_class = "STANDARD"
    labels        = { env = "dev", purpose = "dataform" }
    versioning    = false
    force_destroy = false
  }
}
