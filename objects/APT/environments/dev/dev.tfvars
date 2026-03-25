project_id      = "qwiklabs-gcp-02-50ee4d1ce04f"
region          = "EU"
environment     = "dev"
tfstate_bucket  = "qwiklabs-gcp-test-tfstate"
dataset_labels  = { env = "dev" }

apt_tables = [
  { id = "PRC_APT_L1_COMPANY",      clustflag = false, timePartitioned = false, rangePartitioned = false },
  { id = "PRC_APT_L1_COMPANY_COPY", clustflag = false, timePartitioned = false, rangePartitioned = false },
  { id = "PRC_APT_L1_COMPANY_COPY1", clustflag = false, timePartitioned = false, rangePartitioned = false },

]

apt_views = [
  { id = "VW_APT_COMPANY_SUMMARY" },
]

apt_routines = [
  { id = "PRC_APT_L1_COMPANY", hasArgs = false },
]
