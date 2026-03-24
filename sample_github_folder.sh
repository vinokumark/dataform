#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Run this script to create the full sample folder structure
# from your repo root
# chmod +x create_sample.sh && ./create_sample.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

echo "Creating sample folder structure..."

# ── root infra files ──────────────────────────────────────────────────────────
mkdir -p environments/dev environments/tst environments/prd
mkdir -p events
mkdir -p templates/dataset_template/environments/dev
mkdir -p templates/dataset_template/environments/tst
mkdir -p templates/dataset_template/environments/prd

# ── root backend configs ──────────────────────────────────────────────────────
cat > environments/dev/dev.tfbackend << 'EOF'
bucket = "my-tfstate-bucket"
prefix = "infra/dev"
EOF

cat > environments/tst/tst.tfbackend << 'EOF'
bucket = "my-tfstate-bucket"
prefix = "infra/tst"
EOF

cat > environments/prd/prd.tfbackend << 'EOF'
bucket = "my-tfstate-bucket"
prefix = "infra/prd"
EOF

# ── root tfvars ───────────────────────────────────────────────────────────────
cat > environments/dev/dev.tfvars << 'EOF'
project_id  = "my-gcp-project-dev"
region      = "EU"

datasets = {
  "APT"       = { labels = { domain = "billing"  } }
  "ARIBA"     = { labels = { domain = "procurement" } }
  "DATASET2"  = { labels = { domain = "finance"  } }
  "REPORTING" = { labels = { domain = "reporting" } }
}
EOF

cat > environments/tst/tst.tfvars << 'EOF'
project_id  = "my-gcp-project-tst"
region      = "EU"

datasets = {
  "APT"       = { labels = { domain = "billing"  } }
  "ARIBA"     = { labels = { domain = "procurement" } }
  "DATASET2"  = { labels = { domain = "finance"  } }
  "REPORTING" = { labels = { domain = "reporting" } }
}
EOF

cat > environments/prd/prd.tfvars << 'EOF'
project_id  = "my-gcp-project-prd"
region      = "EU"

datasets = {
  "APT"       = { labels = { domain = "billing"  } }
  "ARIBA"     = { labels = { domain = "procurement" } }
  "DATASET2"  = { labels = { domain = "finance"  } }
  "REPORTING" = { labels = { domain = "reporting" } }
}
EOF

# ── root main.tf ──────────────────────────────────────────────────────────────
cat > main.tf << 'EOF'
terraform {
  required_version = "~> 1.0.8"
  backend "gcs" {}
}

variable "project_id" { type = string }
variable "region"     { type = string }
variable "datasets" {
  type = map(object({ labels = map(string) }))
}

resource "google_bigquery_dataset" "datasets" {
  for_each   = var.datasets
  project    = var.project_id
  dataset_id = each.key
  location   = var.region
  labels     = each.value.labels
  delete_contents_on_destroy = false
}
EOF

# ── root outputs.tf ───────────────────────────────────────────────────────────
cat > outputs.tf << 'EOF'
output "dataset_ids" {
  value = {
    for k, v in google_bigquery_dataset.datasets : k => v.dataset_id
  }
}

output "project_id" {
  value = var.project_id
}
EOF

# ── bigQuery schema folder ────────────────────────────────────────────────────
mkdir -p bigQuery/APT/tables
mkdir -p bigQuery/APT/views
mkdir -p bigQuery/APT/routines
mkdir -p bigQuery/ARIBA/tables
mkdir -p bigQuery/ARIBA/views
mkdir -p bigQuery/DATASET2/tables
mkdir -p bigQuery/DATASET2/views
mkdir -p bigQuery/REPORTING/tables
mkdir -p bigQuery/REPORTING/views

# APT table schema
cat > bigQuery/APT/tables/PRC_APT_L1_COMPANY.json << 'EOF'
[
  { "name": "COMPANY_ID",   "type": "STRING",    "mode": "REQUIRED" },
  { "name": "COMPANY_NAME", "type": "STRING",    "mode": "NULLABLE" },
  { "name": "CREATED_AT",   "type": "TIMESTAMP", "mode": "REQUIRED" }
]
EOF

# APT view SQL
cat > bigQuery/APT/views/VW_APT_COMPANY_SUMMARY.sql << 'EOF'
SELECT
  COMPANY_ID,
  COMPANY_NAME,
  DATE(CREATED_AT) AS created_date
FROM `${projectid}.${datasetname}.PRC_APT_L1_COMPANY`
WHERE COMPANY_ID IS NOT NULL
EOF

# APT routine SQL
cat > bigQuery/APT/routines/PRC_APT_L1_COMPANY.sql << 'EOF'
BEGIN
  DELETE FROM `${projectid}.${datasetname}.PRC_APT_L1_COMPANY`
  WHERE CREATED_AT < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY);
END
EOF

# ARIBA table schema
cat > bigQuery/ARIBA/tables/ARIBA_CONTRACTS.json << 'EOF'
[
  { "name": "CONTRACT_ID",   "type": "STRING",    "mode": "REQUIRED" },
  { "name": "VENDOR_NAME",   "type": "STRING",    "mode": "NULLABLE" },
  { "name": "CONTRACT_DATE", "type": "DATE",      "mode": "NULLABLE" }
]
EOF

# DATASET2 view that references APT (cross-dataset dependency)
cat > bigQuery/DATASET2/tables/DATASET2_MAIN.json << 'EOF'
[
  { "name": "ID",         "type": "STRING",    "mode": "REQUIRED" },
  { "name": "COMPANY_ID", "type": "STRING",    "mode": "NULLABLE" },
  { "name": "AMOUNT",     "type": "NUMERIC",   "mode": "NULLABLE" }
]
EOF

cat > bigQuery/DATASET2/views/VW_DATASET2_WITH_COMPANY.sql << 'EOF'
SELECT
  d.ID,
  d.AMOUNT,
  c.COMPANY_NAME
FROM `${projectid}.${datasetname}.DATASET2_MAIN` d
LEFT JOIN `${projectid}.${aptdatasetname}.PRC_APT_L1_COMPANY` c
  ON d.COMPANY_ID = c.COMPANY_ID
EOF

# REPORTING view that references multiple datasets
cat > bigQuery/REPORTING/views/VW_REPORTING_SUMMARY.sql << 'EOF'
SELECT
  c.COMPANY_NAME,
  d.AMOUNT,
  d.ID
FROM `${projectid}.${aptdatasetname}.PRC_APT_L1_COMPANY` c
JOIN `${projectid}.${dataset2datasetname}.DATASET2_MAIN` d
  ON c.COMPANY_ID = d.COMPANY_ID
EOF

# ── objects/ folders ──────────────────────────────────────────────────────────

create_object_folder() {
  NAME_UPPER=$1   # APT
  NAME_LOWER=$2   # apt
  DEPENDS_ON=$3   # optional — dataset name to depend on

  mkdir -p objects/$NAME_LOWER/environments/dev
  mkdir -p objects/$NAME_LOWER/environments/tst
  mkdir -p objects/$NAME_LOWER/environments/prd

  # .depends_on — only create if dependency provided
  if [ -n "$DEPENDS_ON" ]; then
    echo "$DEPENDS_ON" > objects/$NAME_LOWER/.depends_on
    echo "Created .depends_on for $NAME_LOWER → $DEPENDS_ON"
  fi

  # backend.tf
  cat > objects/$NAME_LOWER/backend.tf << TFEOF
terraform {
  required_version = "~> 1.0.8"
  backend "gcs" {}
}
TFEOF

  # data.tf
  cat > objects/$NAME_LOWER/data.tf << TFEOF
data "terraform_remote_state" "infra" {
  backend = "gcs"
  config = {
    bucket = var.tfstate_bucket
    prefix = "infra/\${var.environment}"
  }
}

locals {
  dataset_id = data.terraform_remote_state.infra.outputs.dataset_ids["$NAME_UPPER"]
  project_id = data.terraform_remote_state.infra.outputs.project_id
}
TFEOF

  # variables.tf
  cat > objects/$NAME_LOWER/variables.tf << TFEOF
variable "project_id"      { type = string }
variable "region"          { type = string }
variable "environment"     { type = string }
variable "tfstate_bucket"  { type = string }
variable "dataset_labels"  { type = map(string) }

variable "${NAME_LOWER}_tables" {
  type = list(object({
    id               = string
    clustflag        = optional(bool, false)
    clustering       = optional(list(string), [])
    timePartitioned  = optional(bool, false)
    rangePartitioned = optional(bool, false)
  }))
  default = []
}

variable "${NAME_LOWER}_views" {
  type = list(object({ id = string }))
  default = []
}

variable "${NAME_LOWER}_routines" {
  type = list(object({
    id      = string
    hasArgs = optional(bool, false)
  }))
  default = []
}
TFEOF

  # tfbackend files
  for ENV in dev tst prd; do
    cat > objects/$NAME_LOWER/environments/$ENV/$ENV.tfbackend << TFEOF
bucket = "my-tfstate-bucket"
prefix = "objects/$NAME_LOWER/$ENV"
TFEOF
  done

  # tfvars files
  cat > objects/$NAME_LOWER/environments/dev/dev.tfvars << TFEOF
project_id      = "my-gcp-project-dev"
region          = "EU"
environment     = "dev"
tfstate_bucket  = "my-tfstate-bucket"
dataset_labels  = { env = "dev" }

${NAME_LOWER}_tables   = []
${NAME_LOWER}_views    = []
${NAME_LOWER}_routines = []
TFEOF

  cat > objects/$NAME_LOWER/environments/tst/tst.tfvars << TFEOF
project_id      = "my-gcp-project-tst"
region          = "EU"
environment     = "tst"
tfstate_bucket  = "my-tfstate-bucket"
dataset_labels  = { env = "tst" }

${NAME_LOWER}_tables   = []
${NAME_LOWER}_views    = []
${NAME_LOWER}_routines = []
TFEOF

  cat > objects/$NAME_LOWER/environments/prd/prd.tfvars << TFEOF
project_id      = "my-gcp-project-prd"
region          = "EU"
environment     = "prd"
tfstate_bucket  = "my-tfstate-bucket"
dataset_labels  = { env = "prd" }

${NAME_LOWER}_tables   = []
${NAME_LOWER}_views    = []
${NAME_LOWER}_routines = []
TFEOF

  echo "✓ Created objects/$NAME_LOWER/"
}

# create all dataset folders
# apt   → no dependency  → Group A
# ariba → no dependency  → Group A
# dataset2 → depends on apt → Group B
# reporting → always last  → Group C (hardcoded in cicd.yml)
create_object_folder "APT"       "apt"       ""
create_object_folder "ARIBA"     "ariba"     ""
create_object_folder "DATASET2"  "dataset2"  "apt"
create_object_folder "REPORTING" "reporting" ""

# ── apt main.tf with actual table/view/routine resources ──────────────────────
cat > objects/apt/main.tf << 'EOF'
module "bq_apt" {
  source = "../../modules/bq"

  project_id          = local.project_id
  dataset_id          = local.dataset_id
  location            = var.region
  dataset_labels      = var.dataset_labels
  deletion_protection = true

  tables = [for t in var.apt_tables : {
    table_id  = upper(t.id)
    schema    = file("../../bigQuery/APT/tables/${upper(t.id)}.json")
    labels    = {}
    expiration_time    = null
    clustering         = try(t.clustflag == true ? t.clustering : [], [])
    time_partitioning  = try(
      t.timePartitioned == true
        ? jsondecode(file("../../bigQuery/APT/tables/${upper(t.id)}_timePartitioning.json"))[0]
        : null, null)
    range_partitioning = try(
      t.rangePartitioned == true
        ? jsondecode(file("../../bigQuery/APT/tables/${upper(t.id)}_rangePartitioning.json"))[0]
        : null, null)
  }]

  views = [for v in var.apt_views : {
    view_id        = upper(v.id)
    use_legacy_sql = false
    labels         = {}
    query = templatefile(
      "../../bigQuery/APT/views/${upper(v.id)}.sql",
      { projectid = local.project_id, datasetname = local.dataset_id }
    )
  }]

  routines = [for r in var.apt_routines : {
    routine_id      = upper(r.id)
    routine_type    = "PROCEDURE"
    language        = "SQL"
    definition_body = templatefile(
      "../../bigQuery/APT/routines/${upper(r.id)}.sql",
      { projectid = local.project_id, datasetname = local.dataset_id }
    )
    description = ""
    return_type = null
    arguments   = try(r.hasArgs == true
      ? jsondecode(file("../../bigQuery/APT/routines/${upper(r.id)}_args.json"))
      : [], [])
  }]

  access = []
}
EOF

# ── dataset2 main.tf — references apt dataset in view ─────────────────────────
cat > objects/dataset2/main.tf << 'EOF'
# dataset2 depends on apt (see .depends_on file)
# views reference apt tables — apt must deploy first

data "terraform_remote_state" "infra_for_apt" {
  backend = "gcs"
  config = {
    bucket = var.tfstate_bucket
    prefix = "infra/${var.environment}"
  }
}

locals {
  apt_dataset_id = data.terraform_remote_state.infra_for_apt.outputs.dataset_ids["APT"]
}

module "bq_dataset2" {
  source = "../../modules/bq"

  project_id          = local.project_id
  dataset_id          = local.dataset_id
  location            = var.region
  dataset_labels      = var.dataset_labels
  deletion_protection = true

  tables = [for t in var.dataset2_tables : {
    table_id           = upper(t.id)
    schema             = file("../../bigQuery/DATASET2/tables/${upper(t.id)}.json")
    labels             = {}
    expiration_time    = null
    clustering         = []
    time_partitioning  = null
    range_partitioning = null
  }]

  views = [for v in var.dataset2_views : {
    view_id        = upper(v.id)
    use_legacy_sql = false
    labels         = {}
    query = templatefile(
      "../../bigQuery/DATASET2/views/${upper(v.id)}.sql",
      {
        projectid          = local.project_id
        datasetname        = local.dataset_id
        aptdatasetname     = local.apt_dataset_id  # cross-dataset reference
      }
    )
  }]

  routines = []
  access   = []
}
EOF

# ── act event files ───────────────────────────────────────────────────────────
cat > events/pr_objects_only.json << 'EOF'
{
  "action": "opened",
  "pull_request": {
    "number": 1,
    "base": { "ref": "main" },
    "head": { "ref": "feat/new-table" },
    "merged": false
  },
  "repository": {
    "name": "your-repo",
    "owner": { "login": "your-org" }
  }
}
EOF

cat > events/pr_infra_and_objects.json << 'EOF'
{
  "action": "opened",
  "pull_request": {
    "number": 2,
    "base": { "ref": "main" },
    "head": { "ref": "feat/new-dataset" },
    "merged": false
  },
  "repository": {
    "name": "your-repo",
    "owner": { "login": "your-org" }
  }
}
EOF

cat > events/pr_merged.json << 'EOF'
{
  "action": "closed",
  "pull_request": {
    "number": 3,
    "base": { "ref": "main" },
    "head": { "ref": "feat/new-table" },
    "merged": true
  },
  "repository": {
    "name": "your-repo",
    "owner": { "login": "your-org" }
  }
}
EOF

# ── .secrets and .env for act ─────────────────────────────────────────────────
cat > .secrets << 'EOF'
GCP_SA_KEY_JSON={"type":"service_account","project_id":"mock-project","private_key_id":"mock","private_key":"-----BEGIN RSA PRIVATE KEY-----\nmock\n-----END RSA PRIVATE KEY-----","client_email":"mock@mock.iam.gserviceaccount.com","client_id":"123","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token"}
EOF

cat > .env << 'EOF'
TF_VERSION=1.0.8
ACT=true
EOF

# ── .actrc for self-hosted runner mapping ─────────────────────────────────────
cat > .actrc << 'EOF'
-P self-hosted=catthehacker/ubuntu:act-latest
--secret-file .secrets
--env-file .env
EOF

# ── .gitignore ────────────────────────────────────────────────────────────────
cat >> .gitignore << 'EOF'
.secrets
.env
.actrc
*.tfstate
*.tfstate.backup
.terraform/
EOF

echo ""
echo "✓ Sample folder structure created"
echo ""
echo "Final structure:"
echo ""
find . -not -path './.git/*' \
       -not -path './.terraform/*' \
       -not -name '*.tfstate' \
  | sort | sed 's|[^/]*/|  |g'
echo ""
echo "Next steps:"
echo "  1. Copy cicd.yml to .github/workflows/cicd.yml"
echo "  2. Run: act pull_request -j detect -e events/pr_objects_only.json --verbose"
echo "  3. Run: act pull_request -e events/pr_objects_only.json --verbose"
