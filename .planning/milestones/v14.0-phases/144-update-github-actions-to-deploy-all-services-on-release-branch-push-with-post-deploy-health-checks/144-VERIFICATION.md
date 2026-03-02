---
phase: 144-update-github-actions-to-deploy-all-services-on-release-branch-push-with-post-deploy-health-checks
verified: 2026-03-01T23:00:00Z
status: passed
score: 4/4 must-haves verified
re_verification: false
---

# Phase 144: GitHub Actions Auto-Deploy + Post-Deploy Health Checks — Verification Report

**Phase Goal:** Automate Fly.io deployments of mesh-registry and mesh-packages on every v* tag push, with a post-deploy health-check job that confirms all three production endpoints are up. Also extend deploy.yml to trigger on push: tags: ['v*'] so docs auto-redeploy on release without manual intervention.
**Verified:** 2026-03-01T23:00:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth                                                                                                                        | Status     | Evidence                                                                                                                                        |
| --- | ---------------------------------------------------------------------------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Pushing a v* tag causes both mesh-registry and mesh-packages to be re-deployed to Fly.io automatically                      | VERIFIED   | deploy-services.yml line 4-5: `push: tags: ['v*']`; deploy-registry job (line 13) and deploy-packages-website job (line 29) both present        |
| 2   | After both Fly.io deploys complete, the workflow polls all three live endpoints and fails if any are unreachable             | VERIFIED   | health-check job (line 45) has `needs: [deploy-registry, deploy-packages-website]`; all three endpoints curl'd with --retry on lines 52-66      |
| 3   | Pushing a v* tag also re-deploys the docs site to GitHub Pages automatically                                                 | VERIFIED   | deploy.yml line 6: `tags: ['v*']` added under push trigger; commit c0a55602 confirms 1-line addition; concurrency cancel-in-progress: false     |
| 4   | A concurrent deploy cannot be preempted or cancelled mid-flight — only one deploy runs at a time per tag                    | VERIFIED   | deploy-services.yml lines 8-10: `concurrency: group: deploy-fly-${{ github.ref_name }}` with `cancel-in-progress: false`                       |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact                                   | Expected                                       | Status     | Details                                                                                             |
| ------------------------------------------ | ---------------------------------------------- | ---------- | --------------------------------------------------------------------------------------------------- |
| `.github/workflows/deploy-services.yml`    | Fly.io parallel deploy + post-deploy health checks | VERIFIED | 67 lines; three jobs: deploy-registry, deploy-packages-website, health-check; valid YAML confirmed |
| `.github/workflows/deploy.yml`             | Docs auto-deploy on tag push                   | VERIFIED   | Line 6 `tags: ['v*']` present alongside existing `branches: [main]`; full build+deploy jobs intact |

**Both artifacts:** Exist (Level 1), Substantive (Level 2 — real flyctl commands, real curl health checks, correct structure), Wired (Level 3 — both files are GitHub Actions workflows consumed directly by GitHub's CI system on trigger).

### Key Link Verification

| From                                  | To                          | Via                                              | Status     | Evidence                                                  |
| ------------------------------------- | --------------------------- | ------------------------------------------------ | ---------- | --------------------------------------------------------- |
| deploy-services.yml deploy-registry   | Fly.io mesh-registry        | `flyctl deploy --remote-only` + `working-directory: registry` | WIRED | Lines 24-25: correct working-directory and --remote-only flag |
| deploy-services.yml deploy-packages-website | Fly.io mesh-packages   | `flyctl deploy --remote-only` + `working-directory: packages-website` | WIRED | Lines 39-41: correct working-directory and --remote-only flag |
| health-check job                      | All three production endpoints | `curl -sf --retry` with --retry-connrefused   | WIRED | Lines 52-66: three curl steps, all three endpoints present, retry counts match plan spec |
| deploy-services.yml                   | FLY_API_TOKEN secret        | `${{ secrets.FLY_API_TOKEN }}` env on deploy steps | WIRED | Lines 27, 43: both deploy jobs reference the secret       |

### Requirements Coverage

| Requirement | Source Plan  | Description                                                                    | Status     | Evidence                                                                       |
| ----------- | ------------ | ------------------------------------------------------------------------------ | ---------- | ------------------------------------------------------------------------------ |
| CI-144      | 144-01-PLAN  | Automate Fly.io deploys on tag push with post-deploy health checks             | SATISFIED  | deploy-services.yml created with all specified jobs; deploy.yml updated         |

**Note on CI-144 in REQUIREMENTS.md:** CI-144 does not appear in `.planning/REQUIREMENTS.md`. The REQUIREMENTS.md covers v14.0 functional requirements (CRYPTO, ENCODE, DTIME, HTTP, TEST, PKG, REG prefix families — 47 total). CI-144 is an infrastructure/automation requirement introduced at the phase level, not formally registered in REQUIREMENTS.md. This is not a gap — REQUIREMENTS.md explicitly covers "v14.0 Requirements" only; CI-144 is a post-v14.0 automation phase requirement. The ROADMAP.md entry at line 415 (`**Requirements**: CI-144`) is the authoritative registration point for this ID.

### Anti-Patterns Found

None. Both workflow files were scanned for TODO, FIXME, XXX, HACK, PLACEHOLDER, empty implementations, and console.log stubs. No issues found.

### Human Verification Required

#### 1. FLY_API_TOKEN secret presence

**Test:** Navigate to the repository's GitHub Settings > Secrets and variables > Actions. Confirm a secret named `FLY_API_TOKEN` exists.
**Expected:** Secret is present with a valid Fly.io deploy token (value starting with `FlyV1 `).
**Why human:** GitHub Actions secrets are not readable from the codebase — only their reference in workflow YAML is verifiable programmatically. The SUMMARY.md documents this as a user setup requirement.

#### 2. End-to-end trigger on live tag push

**Test:** Push a test `v*` tag (e.g., `git tag v14.0.1-test && git push origin v14.0.1-test`) and observe the Actions tab.
**Expected:** Three workflows fire: `release.yml`, `deploy-services.yml` (3 jobs: deploy-registry, deploy-packages-website, health-check), and `deploy.yml`. Health-check job passes on all three endpoints.
**Why human:** Cannot verify that GitHub's trigger wiring actually fires without performing a real tag push against the live repository.

### Gaps Summary

None. All four observable truths are verified. Both artifacts exist, are substantive, and are correctly wired. All key links confirmed present with exact patterns required by the PLAN must_haves.

The only outstanding item is confirmation that the `FLY_API_TOKEN` GitHub secret is present — the workflow correctly references `${{ secrets.FLY_API_TOKEN }}` but the secret value itself cannot be verified from the codebase.

---

_Verified: 2026-03-01T23:00:00Z_
_Verifier: Claude (gsd-verifier)_
