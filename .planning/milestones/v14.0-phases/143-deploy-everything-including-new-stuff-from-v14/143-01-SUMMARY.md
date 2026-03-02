---
phase: 143-deploy-everything-including-new-stuff-from-v14
plan: 01
subsystem: infra
tags: [fly.io, docker, cargo-chef, cloudflare-r2, registry, postgres, github-oauth]

# Dependency graph
requires:
  - phase: 140-package-registry-backend-and-website
    provides: Registry Rust source (registry/src/), session config, config.rs AppConfig env vars
  - phase: 139-package-manifest-and-meshpkg-cli
    provides: meshpkg binary source (compiler/meshpkg/src/main.rs), DEFAULT_REGISTRY constant

provides:
  - Production-ready registry Docker image (ubuntu:24.04 runtime, cargo-chef multi-stage build)
  - Fly.io deployment configuration for mesh-registry app
  - Live infrastructure: Fly.io app + Fly Postgres + Cloudflare R2 bucket + all 10 secrets set
  - DNS and TLS: api.packages.meshlang.dev with Let's Encrypt cert verified
  - Correct production URLs: with_secure(true) in session config, api.packages.meshlang.dev in meshpkg

affects:
  - 143-04 (registry deploy — this plan is the prerequisite for fly deploy)
  - compiler/meshpkg (DEFAULT_REGISTRY now points to live endpoint)

# Tech tracking
tech-stack:
  added:
    - cargo-chef (lukemathwalker/cargo-chef:latest-rust-1) for dependency layer caching in Docker
    - ubuntu:24.04 as runtime base (GLIBC 2.38 required by compiled binary)
    - Fly.io managed Postgres (DATABASE_URL auto-set via fly postgres attach)
    - Cloudflare R2 (S3-compatible object storage for package tarballs)
    - GitHub OAuth App (production callback to api.packages.meshlang.dev)
  patterns:
    - Multi-stage cargo-chef Docker build: chef -> planner -> builder -> runtime
    - Fly.io secrets for all environment variables (never in fly.toml)
    - Auto-stop disabled (auto_stop_machines = 'off') for always-on registry availability

key-files:
  created:
    - registry/Dockerfile
    - registry/.dockerignore
    - registry/fly.toml
  modified:
    - registry/src/main.rs
    - compiler/meshpkg/src/main.rs

key-decisions:
  - "ubuntu:24.04 chosen over debian:bookworm-slim — GLIBC 2.38 required by cargo-chef builder output; bookworm-slim only provides GLIBC 2.35 causing linker error at startup"
  - "auto_stop_machines = 'off' (string) — fly launch generates string format; boolean false causes fly deploy parse error"
  - "cargo-chef multi-stage build — dependency layer cached independently from source; only source changes rebuild from COPY . ."
  - "with_secure(true) correct for Fly.io — TLS terminates at Fly edge proxy, HTTPS-only cookie works end-to-end"

patterns-established:
  - "Fly.io deploy pattern: Dockerfile in service root, fly.toml references it via dockerfile = 'Dockerfile', build context is service directory only"
  - ".dockerignore must exclude target/ for Rust projects — prevents 500MB+ accidental build context upload"

requirements-completed: [DEPLOY-143]

# Metrics
duration: 35min
completed: 2026-03-01
---

# Phase 143 Plan 01: Pre-Deploy Code Fixes and Infrastructure Provisioning Summary

**Cargo-chef multi-stage Docker image for mesh-registry deployed to Fly.io (iad) with Fly Postgres, Cloudflare R2, GitHub OAuth, and api.packages.meshlang.dev TLS cert live returning 200**

## Performance

- **Duration:** ~35 min (code tasks ~1 min; provisioning by user)
- **Started:** 2026-03-01T17:26:14Z
- **Completed:** 2026-03-01T19:45:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Fixed two production correctness issues: `with_secure(true)` for HTTPS-only session cookies on Fly.io, and `DEFAULT_REGISTRY` URL updated to `https://api.packages.meshlang.dev` in meshpkg binary
- Created `registry/Dockerfile` (cargo-chef multi-stage, ubuntu:24.04 runtime), `registry/.dockerignore` (excludes target/), and `registry/fly.toml` with force_https and always-on configuration
- Full cloud infrastructure provisioned by user: Fly.io app `mesh-registry` + Fly Postgres attached (DATABASE_URL auto-set) + Cloudflare R2 bucket `mesh-packages` + GitHub OAuth App with production callback; all 10 secrets set; DNS CNAME and Let's Encrypt TLS cert issued; registry returns `200 []` on `GET /api/v1/packages`

## Task Commits

Each task was committed atomically:

1. **Task 1: Production code fixes — with_secure and DEFAULT_REGISTRY URL** - `fdd5f87f` (fix)
2. **Task 2: Create Dockerfile, .dockerignore, and fly.toml for registry** - `b9193d68` (chore)
3. **Task 3: Provision cloud infrastructure — ubuntu:24.04 and fly.toml from fly launch** - `a6d16ef4` (fix)

**Plan metadata:** `21570cee` (docs: checkpoint noted); finalized in `a6d16ef4`

## Files Created/Modified

- `registry/Dockerfile` - Multi-stage cargo-chef build; ubuntu:24.04 runtime for GLIBC 2.38 compatibility
- `registry/.dockerignore` - Excludes target/, Cargo.lock, .env files from build context
- `registry/fly.toml` - Fly.io app config: app=mesh-registry, port=3000, force_https=true, auto_stop='off', min_machines=1, [[vm]] 1gb shared CPU
- `registry/src/main.rs` - Changed `.with_secure(false)` to `.with_secure(true)` for production HTTPS session cookies
- `compiler/meshpkg/src/main.rs` - Changed `DEFAULT_REGISTRY` from `https://registry.meshlang.dev` to `https://api.packages.meshlang.dev`

## Decisions Made

- **ubuntu:24.04 over debian:bookworm-slim:** The cargo-chef builder (rust:1 base) produces a binary linked against GLIBC 2.38; debian:bookworm-slim only provides GLIBC 2.35, causing a runtime linker error. ubuntu:24.04 ships GLIBC 2.38 and resolves the incompatibility.
- **auto_stop_machines = 'off' (string):** `fly launch` generates string-quoted `'off'` for this field. The string form is the correct Fly.io v2 config format; boolean `false` causes a parse error on deploy.
- **with_secure(true) confirmed correct:** Fly.io terminates TLS at the edge proxy and forwards HTTP internally to the container on port 3000. The HTTPS-only cookie flag works correctly because the client always connects over HTTPS.
- **cargo-chef multi-stage pattern:** Dependency compilation layer cached separately from source — only source changes trigger full rebuild, dramatically reducing image build times.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Changed Dockerfile runtime base from debian:bookworm-slim to ubuntu:24.04**
- **Found during:** Task 3 (infrastructure provisioning — deploy attempt failed with linker error)
- **Issue:** The cargo-chef builder produces a binary linked against GLIBC 2.38 (from rust:1 base image). debian:bookworm-slim provides only GLIBC 2.35, causing `/usr/local/bin/mesh-registry: /lib/x86_64-linux-gnu/libc.so.6: version GLIBC_2.38 not found` at container startup.
- **Fix:** Changed `FROM debian:bookworm-slim AS runtime` to `FROM ubuntu:24.04 AS runtime` — ubuntu:24.04 ships GLIBC 2.38.
- **Files modified:** registry/Dockerfile
- **Verification:** Deploy succeeded; `GET https://api.packages.meshlang.dev/api/v1/packages` returns `200 []`
- **Committed in:** `a6d16ef4` (Task 3 fix commit)

**2. [Rule 1 - Bug] fly.toml format updated from fly launch output**
- **Found during:** Task 3 (fly launch execution)
- **Issue:** `fly launch` regenerates fly.toml with its canonical format: single-quoted strings, `auto_stop_machines = 'off'` (string not boolean), and appended `[[vm]]` spec block.
- **Fix:** Accepted fly launch output as the authoritative fly.toml (correct format for Fly.io v2 config parser). The semantics match the original plan (auto_stop=off, port=3000, force_https=true, min_machines=1).
- **Files modified:** registry/fly.toml
- **Committed in:** `a6d16ef4` (Task 3 fix commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs discovered during deploy attempt)
**Impact on plan:** Both fixes were required for successful deployment. No scope creep.

## Issues Encountered

- GLIBC version mismatch between cargo-chef builder and debian:bookworm-slim runtime — resolved by switching to ubuntu:24.04 which ships the matching GLIBC version.

## User Setup Required

Task 3 was a `checkpoint:human-action` gate. The user provisioned all cloud infrastructure:
- Cloudflare R2 bucket `mesh-packages` created with API token (Object Read & Write)
- GitHub OAuth App created with production callback URL `https://api.packages.meshlang.dev/auth/callback`
- Fly.io app `mesh-registry` provisioned in `iad` region via `fly launch`
- Fly Postgres `mesh-registry-db` attached (DATABASE_URL auto-set as Fly secret)
- 9 additional Fly secrets set: STORAGE_ENDPOINT, STORAGE_BUCKET, STORAGE_ACCESS_KEY_ID, STORAGE_SECRET_ACCESS_KEY, STORAGE_REGION, GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, GITHUB_CALLBACK_URL, SESSION_SECRET
- DNS CNAME: `api.packages.meshlang.dev` CNAME to `o2501o9.mesh-registry.fly.dev`
- Let's Encrypt TLS cert issued and verified by Fly.io

## Next Phase Readiness

- Registry infrastructure is fully live — `GET https://api.packages.meshlang.dev/api/v1/packages` returns `200 []`
- All secrets set, Postgres attached, R2 configured — ready for Plan 04 (`fly deploy` with full registry image)
- meshpkg binary now points to the correct production endpoint — will work correctly once distributed via release.yml

---
*Phase: 143-deploy-everything-including-new-stuff-from-v14*
*Completed: 2026-03-01*
