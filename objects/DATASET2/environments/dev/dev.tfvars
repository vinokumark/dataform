project_id      = "qwiklabs-gcp-02-50ee4d1ce04f"
region          = "EU"
environment     = "dev"
tfstate_bucket  = "qwiklabs-gcp-test-tfstate"
dataset_labels  = { env = "dev" }

dataset2_tables = [
  { id = "DATASET2_MAIN", clustflag = false, timePartitioned = false, rangePartitioned = false },
]

dataset2_views = [
  { id = "VW_DATASET2_WITH_COMPANY" },
]

dataset2_routines = []
