project_id      = "qwiklabs-gcp-02-50ee4d1ce04f"
region          = "EU"
environment     = "dev"
tfstate_bucket  = "qwiklabs-gcp-test-tfstate"
dataset_labels  = { env = "dev" }

ariba_tables = [
  { id = "ARIBA_CONTRACTS", clustflag = false, timePartitioned = false, rangePartitioned = false },
]

ariba_views    = []
ariba_routines = []
