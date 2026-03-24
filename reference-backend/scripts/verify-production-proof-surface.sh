#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

PROOF_PAGE="website/docs/docs/production-backend-proof/index.md"
README_FILE="README.md"
RUNBOOK_FILE="reference-backend/README.md"
SIDEBAR_FILE="website/docs/.vitepress/config.mts"
GETTING_STARTED_FILE="website/docs/docs/getting-started/index.md"
GENERIC_DOCS=(
  "website/docs/docs/getting-started/index.md"
  "website/docs/docs/web/index.md"
  "website/docs/docs/databases/index.md"
  "website/docs/docs/concurrency/index.md"
  "website/docs/docs/tooling/index.md"
  "website/docs/docs/testing/index.md"
)
PROOF_LINK="/docs/production-backend-proof/"
RUNBOOK_REF="reference-backend/README.md"
RUNBOOK_LINK="https://github.com/snowdamiz/mesh-lang/blob/main/reference-backend/README.md"
CANONICAL_PUBLIC_PROOF_COMMANDS=(
  'cargo run -p meshc -- build reference-backend'
  'cargo run -p meshc -- fmt --check reference-backend'
  'cargo run -p meshc -- test reference-backend'
  'DATABASE_URL=${DATABASE_URL:?set DATABASE_URL} cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_migration_status_and_apply -- --ignored --nocapture'
  'DATABASE_URL=${DATABASE_URL:?set DATABASE_URL} cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_deploy_artifact_smoke -- --ignored --nocapture'
  'DATABASE_URL=${DATABASE_URL:?set DATABASE_URL} cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_crash_recovers_job -- --ignored --nocapture'
  'DATABASE_URL=${DATABASE_URL:?set DATABASE_URL} cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_restart_is_visible_in_health -- --ignored --nocapture'
  'DATABASE_URL=${DATABASE_URL:?set DATABASE_URL} cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_process_restart_recovers_inflight_job -- --ignored --nocapture'
  'bash reference-backend/scripts/verify-production-proof-surface.sh'
)
RECOVERY_RUNBOOK_STRINGS=(
  'Supervision and recovery'
  'restart_count'
  'last_exit_reason'
  'recovered_jobs'
  'last_recovery_at'
  'last_recovery_job_id'
  'last_recovery_count'
  'recovery_active'
  'Worker crash proof'
  'Process restart proof'
)
PROOF_PAGE_RECOVERY_STRINGS=(
  'restart_count'
  'last_exit_reason'
  'recovered_jobs'
  'last_recovery_at'
  'last_recovery_job_id'
  'last_recovery_count'
  'recovery_active'
  'Worker crash recovery'
  'Whole-process restart recovery'
  'Recovery window visibility'
)

phase() {
  printf '[proof-docs] %s\n' "$*"
}

fail() {
  printf '[proof-docs] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "required command missing from PATH: $command_name"
  fi
}

require_file() {
  local relative_path="$1"
  if [[ ! -f "$ROOT/$relative_path" ]]; then
    fail "missing file: $relative_path"
  fi
}

require_contains() {
  local relative_path="$1"
  local needle="$2"
  local description="$3"
  if ! rg -Fq "$needle" "$ROOT/$relative_path"; then
    fail "$relative_path missing ${description}: $needle"
  fi
}

require_not_contains() {
  local relative_path="$1"
  local needle="$2"
  local description="$3"
  if rg -Fq "$needle" "$ROOT/$relative_path"; then
    fail "$relative_path still contains ${description}: $needle"
  fi
}

phase "checking prerequisites"
require_command rg

phase "checking canonical files exist"
require_file "$PROOF_PAGE"
require_file "$README_FILE"
require_file "$RUNBOOK_FILE"
require_file "$SIDEBAR_FILE"

for doc in "${GENERIC_DOCS[@]}"; do
  require_file "$doc"
done

phase "checking generic docs route to the canonical proof surface"
for doc in "${GENERIC_DOCS[@]}"; do
  require_contains "$doc" "$PROOF_LINK" "production proof link"
  require_contains "$doc" "$RUNBOOK_REF" "reference backend runbook reference"
done

phase "checking landing page and sidebar route to the proof surface"
require_contains "$README_FILE" "$PROOF_LINK" "production proof link"
require_contains "$README_FILE" "$RUNBOOK_REF" "reference backend runbook reference"
require_contains "$SIDEBAR_FILE" "$PROOF_LINK" "production proof sidebar entry"

phase "checking proof page points at the real runbook and verifier"
require_contains "$PROOF_PAGE" "$RUNBOOK_REF" "reference backend runbook reference"
require_contains "$PROOF_PAGE" "$RUNBOOK_LINK" "reference backend runbook link"
require_contains "$PROOF_PAGE" "bash reference-backend/scripts/verify-production-proof-surface.sh" "doc truth verification command"

phase "checking the runbook exposes the recovery contract"
for needle in "${RECOVERY_RUNBOOK_STRINGS[@]}"; do
  require_contains "$RUNBOOK_FILE" "$needle" "recovery runbook wording"
done

phase "checking the proof page exposes the recovery-aware public contract"
for needle in "${PROOF_PAGE_RECOVERY_STRINGS[@]}"; do
  require_contains "$PROOF_PAGE" "$needle" "recovery proof wording"
done

phase "checking the runbook and proof page share the same authoritative command list"
for needle in "${CANONICAL_PUBLIC_PROOF_COMMANDS[@]}"; do
  require_contains "$RUNBOOK_FILE" "$needle" "canonical public proof command"
  require_contains "$PROOF_PAGE" "$needle" "canonical public proof command"
done

phase "checking stale phrases are gone"
require_not_contains "$GETTING_STARTED_FILE" "mesh-lang.org/install.sh" "stale install URL"
require_not_contains "$README_FILE" "placeholder link" "placeholder documentation wording"
require_not_contains "$README_FILE" "### Production Ready" "implicit production-ready heading"

phase "production proof surface verified"
