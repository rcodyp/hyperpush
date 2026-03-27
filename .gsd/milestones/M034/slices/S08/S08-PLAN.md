# S08: Hosted rollout completion and first-green evidence

**Goal:** Finish the hosted rollout evidence path by preserving a fresh pre-push baseline, creating the missing candidate tags on the rolled-out commit, and capturing one authoritative `first-green` remote-evidence bundle for milestone closeout.
**Demo:** After this: Remote `main`, `v0.1.0`, and `ext-v0.3.0` now have the hosted workflow evidence S05 expects, with a preserved first-green bundle for milestone closeout.

## Tasks
- [x] **T01: Captured a fresh s08-prepush red hosted-evidence bundle, kept first-green unused, and marked the stale v0.1.0 directory as incomplete noise.** — The repo already has a misleading occupied `v0.1.0` evidence directory that is missing the files the archive helper requires. This task makes the final capture deterministic before any outward action: confirm the stale directory is incomplete, keep `first-green` unused, and archive one fresh red baseline under a dedicated non-final label so later tasks can distinguish real rollout progress from label-collision noise.

## Failure Modes

| Dependency | On error | On timeout | On malformed response |
|------------|----------|-----------|----------------------|
| `scripts/verify-m034-s06-remote-evidence.sh` | Fail closed and inspect the wrapper contract instead of inventing manual archive state. | Treat a hung stop-after replay as a verifier regression and keep the last generated logs. | Treat missing `manifest.json`, `status.txt`, or `remote-runs.json` as archive drift. |
| Existing evidence directories under `.tmp/m034-s06/evidence/` | Preserve them as historical context unless they clearly block the planned label strategy. | N/A | Treat partial bundles like `v0.1.0/` as evidence hygiene problems, not as proof. |
| Hosted run query inside the stop-after replay | Keep the resulting red bundle and use it as the pre-push baseline instead of retrying blindly. | Capture the timeout in the archived logs and stop. | Treat missing workflow entries or wrong refs as baseline truth, not as a local script success. |

## Load Profile

- **Shared resources**: local `.tmp/m034-s06/evidence/` archive tree and one stop-after `verify-m034-s05.sh` replay.
- **Per-operation cost**: one archive-helper execution plus a bounded scan of the occupied evidence labels.
- **10x breakpoint**: repeated archive-helper reruns would mostly create label churn, so the task should claim exactly one disposable pre-push label and keep `first-green` untouched.

## Negative Tests

- **Malformed inputs**: occupied label missing `manifest.json`, missing `status.txt`, or a pre-existing `first-green` directory.
- **Error paths**: archive helper returns non-zero but fails to leave a red bundle, or the stop-after replay drifts into `public-http` / `s01-live-proof`.
- **Boundary conditions**: the new pre-push label must be unique, the stale `v0.1.0` directory must stay clearly non-authoritative, and the final `first-green` label must still be available when the task ends.

## Steps

1. Inspect `.tmp/m034-s06/evidence/v0.1.0/` and record which required archive files are missing so the stale directory is treated as noise, not truth.
2. Confirm `.tmp/m034-s06/evidence/first-green/` does not exist and reserve that label for the final green capture.
3. Run `bash scripts/verify-m034-s06-remote-evidence.sh s08-prepush` through the repo-root `.env` context, expect a red result, and keep the archived bundle as the authoritative pre-tag baseline.
4. If the wrapper or contract tests drift, repair them in this task before any outward tag creation is attempted.

## Must-Haves

- [ ] The task leaves one fresh non-final pre-push bundle at `.tmp/m034-s06/evidence/s08-prepush/`.
- [ ] `first-green` remains unused when the task finishes.
- [ ] The stale `v0.1.0` directory is explicitly recognized as incomplete and non-authoritative.
- [ ] Any wrapper/test drift discovered here is fixed before later tasks rely on the archive contract.
  - Estimate: 45m
  - Files: scripts/verify-m034-s06-remote-evidence.sh, scripts/verify-m034-s05.sh, scripts/tests/verify-m034-s06-contract.test.mjs, .tmp/m034-s06/evidence/v0.1.0, .tmp/m034-s06/evidence/s08-prepush/manifest.json, .tmp/m034-s06/evidence/first-green
  - Verify: node --test scripts/tests/verify-m034-s06-contract.test.mjs
bash -c 'set -euo pipefail; test -f .env; set -a; source .env; set +a; rm -rf .tmp/m034-s06/evidence/s08-prepush; if bash scripts/verify-m034-s06-remote-evidence.sh s08-prepush; then echo "expected pre-push bundle to stay red before tags exist" >&2; exit 1; fi'
python3 - <<'PY'
import json
from pathlib import Path
stale = Path('.tmp/m034-s06/evidence/v0.1.0')
assert not (stale / 'manifest.json').exists()
assert not (stale / 'status.txt').exists()
prepush = Path('.tmp/m034-s06/evidence/s08-prepush')
assert (prepush / 'manifest.json').exists()
assert (prepush / 'remote-runs.json').exists()
assert (prepush / 'status.txt').read_text().strip() == 'failed'
manifest = json.loads((prepush / 'manifest.json').read_text())
assert manifest['stopAfterPhase'] == 'remote-evidence'
assert manifest['s05ExitCode'] != 0
assert not Path('.tmp/m034-s06/evidence/first-green').exists()
PY
- [x] **T02: Created the candidate tags on the rolled-out SHA and captured the hosted blockers preventing a truthful first-green archive.** — This is the only outward-facing step in the slice. It must not happen speculatively. The task first proves the intended commit and tag names locally, asks the user for explicit approval to create and push `v0.1.0` and `ext-v0.3.0`, then watches the resulting hosted `push` runs until the candidate-tag workflows either go green or produce concrete failure evidence for the next iteration.

## Failure Modes

| Dependency | On error | On timeout | On malformed response |
|------------|----------|-----------|----------------------|
| `git` tag/push to `origin` | Stop immediately, keep the exact stderr, and do not claim any hosted evidence progress. | Treat a stalled push as an external transport blocker and preserve the last attempted ref state. | Treat an unexpected remote SHA or missing remote tag as failure, even if a local tag exists. |
| GitHub Actions hosted runs | Poll until the expected run exists on the expected tag or a bounded wait expires, then keep the run metadata for inspection. | Preserve the last observed run status and URL rather than looping forever. | Treat wrong `headBranch`, wrong `headSha`, or missing required jobs as failure, not as eventual-consistency success. |
| User confirmation gate | Do not create or push tags until the user explicitly approves the exact outward action. | N/A | Treat ambiguous confirmation as "no" and stop cleanly. |

## Load Profile

- **Shared resources**: remote git refs, GitHub Actions queues, and the `.tmp/m034-s08/tag-rollout/` monitoring files.
- **Per-operation cost**: two tag pushes plus repeated `gh run list/view` polling for `release.yml`, `deploy-services.yml`, and `publish-extension.yml`.
- **10x breakpoint**: hosted polling dominates first, so the task should use bounded waits and durable JSON snapshots instead of ad hoc terminal-only checks.

## Negative Tests

- **Malformed inputs**: wrong target SHA, missing local version/tag derivation, or absent user approval.
- **Error paths**: push rejected, tag already exists remotely with the wrong SHA, hosted run fails, or hosted run is green on the wrong ref.
- **Boundary conditions**: the task must prove both remote tags exist and each candidate workflow run points at the same intended rollout commit before T03 can archive `first-green`.

## Steps

1. Confirm local `HEAD`, remote `main`, and the derived tags from `compiler/meshc/Cargo.toml` plus `tools/editors/vscode-mesh/package.json` all line up with the intended rollout commit.
2. Present the exact outward action (`git tag` / `git push origin v0.1.0 ext-v0.3.0`) and wait for explicit user confirmation before mutating any remote state.
3. Create and push the tags, then poll `gh run list/view` for `release.yml`, `deploy-services.yml`, and `publish-extension.yml`, persisting the latest successful or failing run payloads under `.tmp/m034-s08/tag-rollout/`.
4. Stop only when the remote tags exist and the monitored run payloads show completed green runs on the expected branch/tag and `headSha`, or when a concrete hosted blocker is captured for follow-up.

## Must-Haves

- [ ] No remote tag creation or push happens before explicit user confirmation.
- [ ] `origin` ends the task with both `v0.1.0` and `ext-v0.3.0` present on the intended rollout commit.
- [ ] Durable run snapshots exist for `release.yml`, `deploy-services.yml`, and `publish-extension.yml`.
- [ ] The task distinguishes wrong-ref/stale-run failures from genuinely green candidate-tag runs.
  - Estimate: 1h
  - Files: compiler/meshc/Cargo.toml, compiler/meshpkg/Cargo.toml, tools/editors/vscode-mesh/package.json, .tmp/m034-s08/tag-rollout/tag-refs.txt, .tmp/m034-s08/tag-rollout/workflow-status.json, .tmp/m034-s08/tag-rollout/release-v0.1.0-view.json, .tmp/m034-s08/tag-rollout/deploy-services-v0.1.0-view.json, .tmp/m034-s08/tag-rollout/publish-extension-ext-v0.3.0-view.json
  - Verify: bash -c 'set -euo pipefail; test -s .tmp/m034-s08/tag-rollout/tag-refs.txt; grep -F "refs/tags/v0.1.0" .tmp/m034-s08/tag-rollout/tag-refs.txt; grep -F "refs/tags/ext-v0.3.0" .tmp/m034-s08/tag-rollout/tag-refs.txt'
python3 - <<'PY'
import json
from pathlib import Path
summary = json.loads(Path('.tmp/m034-s08/tag-rollout/workflow-status.json').read_text())
expected = {
    'release.yml': 'v0.1.0',
    'deploy-services.yml': 'v0.1.0',
    'publish-extension.yml': 'ext-v0.3.0',
}
for workflow, ref_name in expected.items():
    entry = summary[workflow]
    assert entry['headBranch'] == ref_name, (workflow, entry)
    assert entry['status'] == 'completed', (workflow, entry)
    assert entry['conclusion'] == 'success', (workflow, entry)
    assert entry['headSha'], (workflow, entry)
PY
  - Blocker: `deploy-services.yml` is red on `v0.1.0` because the `packages-website` runtime Docker layer reruns `npm install --omit=dev --ignore-scripts` and fails with a Vite / Svelte peer-dependency `ERESOLVE` conflict. `release.yml` is red on `v0.1.0` because multiple `Verify release assets (...)` jobs fail: Unix installer smoke builds cannot find `libmesh_rt.a`, macOS checksum generation assumes `sha256sum`, and the Windows checksum step has broken PowerShell `Select-Object -First 1,` syntax. T03 cannot truthfully claim `.tmp/m034-s06/evidence/first-green/` until those hosted regressions are fixed.
- [ ] **T03: Capture the authoritative `first-green` hosted-evidence bundle and validate its manifest** — Once the candidate-tag runs are actually green, the slice still is not done until the repo-owned wrapper preserves that truth under the reserved `first-green` label. This task performs the one final stop-after capture, reruns the contract tests if earlier tasks touched the wrapper, and validates the archived manifest and copied verifier artifacts so milestone closeout can rely on the bundle directly.

## Failure Modes

| Dependency | On error | On timeout | On malformed response |
|------------|----------|-----------|----------------------|
| `scripts/verify-m034-s06-remote-evidence.sh` | Fail closed and inspect the copied `phase-report.txt` / `remote-runs.json` instead of fabricating a green bundle. | Treat timeout as a verifier regression and preserve the partial archive staging logs if any exist. | Treat missing manifest fields, wrong `current-phase`, or missing workflow summaries as archive failure. |
| `.env` / authenticated hosted checks | Stop with the missing key names only; never echo secret values. | N/A | Treat auth or credential drift as a hard blocker because the final bundle must come from the canonical wrapper. |
| Hosted workflow state from T02 | Refuse to claim `first-green` if any required workflow is still red or tied to the wrong ref. | Keep the last saved T02 status snapshot and stop. | Treat incomplete `workflow-status.json` or green-but-stale runs as failure. |

## Load Profile

- **Shared resources**: one final stop-after S05 replay plus the archived evidence directory `.tmp/m034-s06/evidence/first-green/`.
- **Per-operation cost**: contract tests, one authenticated archive-helper run, and one manifest validation pass.
- **10x breakpoint**: repeated claims of the reserved label would destroy the first-green proof, so this task must run exactly once after T02 says the hosted runs are ready.

## Negative Tests

- **Malformed inputs**: reserved label already exists, missing `.env`, or incomplete T02 workflow snapshots.
- **Error paths**: wrapper exits non-zero, copied bundle lacks `remote-runs.json`, or any `remoteRunsSummary` entry stays red.
- **Boundary conditions**: `first-green` must end with `status.txt=ok`, `current-phase.txt=stopped-after-remote-evidence`, `s05ExitCode=0`, and every summarized workflow marked `ok`.

## Steps

1. Reconfirm that `.tmp/m034-s06/evidence/first-green/` is absent and that T02’s saved workflow snapshots are all green on the expected refs.
2. Run the repo-owned wrapper exactly once with `bash scripts/verify-m034-s06-remote-evidence.sh first-green` from the `.env`-loaded repo root, and rerun the Node contract tests if T01 changed the wrapper or its tests.
3. Validate the archived `status.txt`, `current-phase.txt`, `phase-report.txt`, `manifest.json`, and `remote-runs.json` so closeout can trust the bundle without another hosted query.
4. Leave the bundle in place as the single authoritative first-green archive; do not overwrite it with follow-up retries.

## Must-Haves

- [ ] The final archive uses the reserved `first-green` label exactly once.
- [ ] The wrapper remains the sole owner of the final hosted-evidence proof path.
- [ ] `manifest.json` and `remote-runs.json` both show all required workflows green.
- [ ] The task leaves a durable bundle that milestone validation can read without reconstructing hosted state.
  - Estimate: 45m
  - Files: scripts/verify-m034-s06-remote-evidence.sh, scripts/tests/verify-m034-s05-contract.test.mjs, scripts/tests/verify-m034-s06-contract.test.mjs, .tmp/m034-s08/tag-rollout/workflow-status.json, .tmp/m034-s06/evidence/first-green/manifest.json, .tmp/m034-s06/evidence/first-green/remote-runs.json, .tmp/m034-s06/evidence/first-green/phase-report.txt
  - Verify: node --test scripts/tests/verify-m034-s05-contract.test.mjs scripts/tests/verify-m034-s06-contract.test.mjs
bash -c 'set -euo pipefail; test -f .env; set -a; source .env; set +a; bash scripts/verify-m034-s06-remote-evidence.sh first-green'
python3 - <<'PY'
import json
from pathlib import Path
root = Path('.tmp/m034-s06/evidence/first-green')
assert (root / 'status.txt').read_text().strip() == 'ok'
assert (root / 'current-phase.txt').read_text().strip() == 'stopped-after-remote-evidence'
phase_report = (root / 'phase-report.txt').read_text()
for needle in ['candidate-tags\tpassed', 'remote-evidence\tpassed']:
    assert needle in phase_report, needle
manifest = json.loads((root / 'manifest.json').read_text())
assert manifest['s05ExitCode'] == 0
assert manifest['stopAfterPhase'] == 'remote-evidence'
for entry in manifest['remoteRunsSummary']:
    assert entry['status'] == 'ok', entry
PY
