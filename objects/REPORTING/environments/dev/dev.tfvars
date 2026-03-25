project_id      = "qwiklabs-gcp-02-50ee4d1ce04f"
region          = "EU"
environment     = "dev"
tfstate_bucket  = "qwiklabs-gcp-test-tfstate"
dataset_labels  = { env = "dev" }

reporting_tables = []

reporting_views = [
  { id = "VW_REPORTING_SUMMARY" },
]

reporting_routines = []
