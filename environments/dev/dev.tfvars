project_id  = "qwiklabs-gcp-02-50ee4d1ce04f"
region      = "EU"

datasets = {
  "APT"       = { labels = { domain = "billing" } }
  "ARIBA"     = { labels = { domain = "procurement" } }
  "DATASET2"  = { labels = { domain = "finance" } }
  "REPORTING" = { labels = { domain = "reporting" } }
}

buckets = {
  "qwiklabs-gcp-test-tfstate" = {
    location      = "EU"
    storage_class = "STANDARD"
    labels        = { env = "dev", purpose = "tfstate" }
    versioning    = true
    force_destroy = false
  }
  "qwiklabs-gcp-test-dataform" = {
    location      = "EU"
    storage_class = "STANDARD"
    labels        = { env = "dev", purpose = "dataform" }
    versioning    = false
    force_destroy = false
  }
}
