# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Install act
# ─────────────────────────────────────────────────────────────────────────────

# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Windows (via scoop)
scoop install act

# verify
act --version


# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — Install Docker (act requires Docker)
# ─────────────────────────────────────────────────────────────────────────────
# macOS: https://docs.docker.com/desktop/mac/install/
# Linux: sudo apt-get install docker.io
# verify
docker --version


# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — Create local secrets file (mock values — no real GCP needed)
# ─────────────────────────────────────────────────────────────────────────────
cat > .secrets << 'EOF'
GCP_SA_KEY_JSON={"type":"service_account","project_id":"mock-project","private_key_id":"mock","private_key":"mock","client_email":"mock@mock.iam.gserviceaccount.com","client_id":"mock","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token"}
EOF

# NOTE: GCP calls will fail with mock key
# but detect + pre-commit + dependency logic will run correctly
# that is what we are testing locally


# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — Create act config for self-hosted runner
# ─────────────────────────────────────────────────────────────────────────────
cat > .actrc << 'EOF'
-P self-hosted=catthehacker/ubuntu:act-latest
--secret-file .secrets
--env-file .env
EOF

# act maps self-hosted → ubuntu docker image
# catthehacker/ubuntu:act-latest is the recommended image for act


# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — Create local env file
# ─────────────────────────────────────────────────────────────────────────────
cat > .env << 'EOF'
TF_VERSION=1.0.8
ACT=true
EOF

# ACT=true flag is used inside cicd.yml to skip GCP auth steps locally


# ─────────────────────────────────────────────────────────────────────────────
# STEP 6 — Create mock PR event files for different scenarios
# ─────────────────────────────────────────────────────────────────────────────

# Scenario 1 — only objects changed (apt folder)
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

# Scenario 2 — infra + objects changed
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

# Scenario 3 — PR merged (apply flow)
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

mkdir -p events


# ─────────────────────────────────────────────────────────────────────────────
# STEP 7 — Run act commands
# ─────────────────────────────────────────────────────────────────────────────

# list all jobs in workflow
act pull_request --list

# test ONLY detect job (most important — tests path detection logic)
act pull_request \
  -j detect \
  -e events/pr_objects_only.json \
  --verbose

# test detect + pre-commit only (no GCP needed)
act pull_request \
  -j detect \
  -j pre-commit \
  -e events/pr_objects_only.json

# test full plan flow (GCP calls will fail with mock key — expected)
# but detect + group building logic will run correctly
act pull_request \
  -e events/pr_objects_only.json \
  --verbose 2>&1 | tee act_output.log

# test merged PR (apply flow) — detect logic only
act pull_request \
  -j detect \
  -e events/pr_merged.json \
  --verbose


# ─────────────────────────────────────────────────────────────────────────────
# STEP 8 — Test detect script in isolation (no Docker needed)
# run this bash snippet directly to validate detection logic
# ─────────────────────────────────────────────────────────────────────────────

# simulate changed files for different scenarios
test_detect() {
  CHANGED=$1
  echo "=== Testing detect with: ==="
  echo "$CHANGED"
  echo ""

  # infra detection
  INFRA=$(echo "$CHANGED" \
    | grep -v '^objects/' \
    | grep -E '\.tf$|\.tfvars$' \
    | wc -l)
  INFRA_CHANGED=$([ "$INFRA" -gt "0" ] && echo "true" || echo "false")

  # object folders
  FOLDERS=$(echo "$CHANGED" \
    | grep '^objects/' \
    | cut -d'/' -f2 \
    | sort -u \
    | jq -R . | jq -sc .)

  # group detection
  REPORTING_DATASETS='["reporting"]'
  GROUP_A=()
  GROUP_B=()
  GROUP_C=()

  for folder in $(echo "$FOLDERS" | jq -r '.[]'); do
    # check if reporting
    if echo "$REPORTING_DATASETS" | jq -e --arg f "$folder" 'contains([$f])' > /dev/null; then
      GROUP_C+=("$folder")
    # check .depends_on
    elif [ -f "objects/$folder/.depends_on" ]; then
      GROUP_B+=("$folder")
    else
      GROUP_A+=("$folder")
    fi
  done

  echo "infra_changed:  $INFRA_CHANGED"
  echo "object_folders: $FOLDERS"
  echo "group_a:        $(echo ${GROUP_A[@]} | jq -R 'split(" ")')"
  echo "group_b:        $(echo ${GROUP_B[@]} | jq -R 'split(" ")')"
  echo "group_c:        $(echo ${GROUP_C[@]} | jq -R 'split(" ")')"
  echo ""
}

# test scenario 1 — only objects changed
test_detect "objects/apt/main.tf
objects/ariba/main.tf"

# test scenario 2 — infra + objects
test_detect "main.tf
variables.tf
objects/apt/main.tf"

# test scenario 3 — reporting only
test_detect "objects/reporting/main.tf"

# test scenario 4 — mixed with dependency
# (assumes objects/dataset2/.depends_on exists)
test_detect "objects/apt/main.tf
objects/dataset2/main.tf
objects/reporting/main.tf"
