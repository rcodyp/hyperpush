---
phase: 144-update-github-actions-to-deploy-all-services-on-release-branch-push-with-post-deploy-health-checks
plan: 01
subsystem: infra
tags: [github-actions, fly.io, ci-cd, deploy, health-checks, flyctl]

# Dependency graph
requires:
  - phase: 143-deploy-everything-including-new-stuff-from-v14
    provides: Live Fly.io apps mesh-registry and mesh-packages with confirmed endpoints

provides:
  - Fully automated Fly.io deploy of mesh-registry and mesh-packages on every v* tag push
  - Post-deploy health checks polling all three production endpoints after deploys complete
  - Docs site auto-redeploy on tag push (no more manual workflow_dispatch)

affects:
  - Future release workflows (push v* tag triggers all four deploys automatically)

# Tech tracking
tech-stack:
  added: [flyctl-actions/setup-flyctl@master, superfly/flyctl-actions]
  patterns:
    - "Two parallel Fly.io deploy jobs followed by a health-check needs-both job"
    - "cancel-in-progress: false on deploy concurrency group prevents torn mid-flight deploys"
    - "curl --retry with --retry-connrefused for Fly.io VM warmup window handling"

key-files:
  created:
    - .github/workflows/deploy-services.yml
  modified:
    - .github/workflows/deploy.yml

key-decisions:
  - "cancel-in-progress: false on deploy-fly concurrency group — never cancel a mid-flight Fly.io deploy"
  - "flyctl deploy --remote-only required — remote builder handles Docker; local Actions runner has no production Docker daemon configured"
  - "working-directory per deploy job (registry/ vs packages-website/) — fly.toml must be in the CWD of the flyctl command"
  - "curl --retry 5 --retry-delay 10 --retry-connrefused for registry and packages checks; --retry 3 --retry-delay 5 for docs (GitHub Pages has faster propagation)"
  - "No permissions block on deploy-services.yml — no write operations required (FLY_API_TOKEN via secrets)"

patterns-established:
  - "Tag-triggered parallel Fly.io deploy: two sibling jobs (one per app) + one health-check job with needs: [both]"
  - "Health checks use raw curl with retry — no marketplace actions, zero external dependency"

requirements-completed: [CI-144]

# Metrics
duration: 1min
completed: 2026-03-01
---

# Phase 144 Plan 01: GitHub Actions Fly.io Auto-Deploy + Post-Deploy Health Checks Summary

**New deploy-services.yml workflow auto-deploys mesh-registry and mesh-packages to Fly.io on every v* tag push, then polls all three production endpoints with curl retry to confirm the release is live.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-01T22:00:54Z
- **Completed:** 2026-03-01T22:01:49Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `.github/workflows/deploy-services.yml` with three jobs: parallel `deploy-registry` + `deploy-packages-website` (Wave 1), then `health-check` gated on both (Wave 2)
- Both Fly.io deploy jobs use `flyctl deploy --remote-only` from correct `working-directory` (registry/ and packages-website/)
- Health check polls api.packages.meshlang.dev, packages.meshlang.dev, and meshlang.dev with curl retry handling VM warmup
- Updated `deploy.yml` to add `tags: ['v*']` trigger so docs auto-redeploy on every release tag push
- Concurrency group `deploy-fly-${{ github.ref_name }}` with `cancel-in-progress: false` prevents parallel deploys of same tag without ever cancelling in-flight work

## Task Commits

Each task was committed atomically:

1. **Task 1: Create .github/workflows/deploy-services.yml** - `67465d99` (feat)
2. **Task 2: Add tag-push trigger to deploy.yml** - `c0a55602` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `.github/workflows/deploy-services.yml` - New workflow: Fly.io parallel deploy of registry + packages-website on tag push, health-check job polls all three endpoints
- `.github/workflows/deploy.yml` - Added `tags: ['v*']` to push trigger so docs auto-redeploy on release

## Decisions Made

- `cancel-in-progress: false` on deploy concurrency — a cancelled mid-flight Fly.io deploy leaves the app in a broken state; safer to let it finish
- `flyctl deploy --remote-only` in both deploy jobs — remote builder handles the Docker build; the Actions runner has no production Docker daemon
- Per-job `working-directory` (registry/ or packages-website/) so flyctl picks up the correct `fly.toml`
- curl retry counts differ by endpoint: registry + packages use `--retry 5 --retry-delay 10` (Fly.io VM warmup); docs use `--retry 3 --retry-delay 5` (GitHub Pages propagates faster)
- `workflow_dispatch` trigger added alongside `push: tags: ['v*']` for manual testing of the deploy pipeline without a real release

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

The `FLY_API_TOKEN` GitHub secret must be present in the repository for the `flyctl deploy` steps to authenticate with Fly.io. The workflow references `${{ secrets.FLY_API_TOKEN }}` — if this secret is not yet set, the workflow will fail at the deploy step with an auth error. Add it via: GitHub repo Settings > Secrets and variables > Actions > New repository secret.

## Next Phase Readiness

- Release automation is now complete: pushing a `v*` tag triggers `release.yml` (binaries + GitHub Release), `deploy-services.yml` (Fly.io deploys for registry and packages), and `deploy.yml` (docs to GitHub Pages) — all automatically
- No blockers for future releases

---
*Phase: 144-update-github-actions-to-deploy-all-services-on-release-branch-push-with-post-deploy-health-checks*
*Completed: 2026-03-01*

## Self-Check: PASSED

- FOUND: .github/workflows/deploy-services.yml
- FOUND: .github/workflows/deploy.yml
- FOUND: 144-01-SUMMARY.md
- FOUND: commit 67465d99 (Task 1: create deploy-services.yml)
- FOUND: commit c0a55602 (Task 2: add tag trigger to deploy.yml)
