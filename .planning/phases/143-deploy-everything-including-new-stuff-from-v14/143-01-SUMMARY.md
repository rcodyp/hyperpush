---
phase: 143-deploy-everything-including-new-stuff-from-v14
plan: 01
subsystem: infra
tags: [fly.io, docker, rust, cargo-chef, cloudflare-r2, registry, meshpkg]

# Dependency graph
requires:
  - phase: 140-package-registry-backend-and-website
    provides: registry/src/main.rs and compiler/meshpkg/src/main.rs source files
provides:
  - registry/Dockerfile (multi-stage cargo-chef Rust build for Fly.io)
  - registry/.dockerignore (excludes target/ from Docker build context)
  - registry/fly.toml (Fly.io app config for mesh-registry service)
  - registry/src/main.rs with_secure(true) production session cookie fix
  - compiler/meshpkg/src/main.rs DEFAULT_REGISTRY pointing to api.packages.meshlang.dev
affects:
  - 143-deploy-everything-including-new-stuff-from-v14 Plan 04 (actual fly deploy uses these artifacts)

# Tech tracking
tech-stack:
  added: [cargo-chef docker pattern, fly.toml, debian:bookworm-slim runtime image]
  patterns: [multi-stage cargo-chef Rust Dockerfile for Fly.io, .dockerignore excluding target/ to prevent bloat]

key-files:
  created:
    - registry/Dockerfile
    - registry/.dockerignore
    - registry/fly.toml
  modified:
    - registry/src/main.rs
    - compiler/meshpkg/src/main.rs

key-decisions:
  - "with_secure(true) is correct for Fly.io because TLS terminates at the edge proxy — HTTPS-only cookie flag works correctly"
  - "cargo-chef multi-stage pattern used for layer caching — dependency compilation cached separately from source build"
  - "auto_stop_machines=false and min_machines_running=1 — registry must be always-on (no cold starts for package installs)"
  - "primary_region=iad (US East) per CONTEXT.md discretion for Fly.io region"
  - "Cargo.lock excluded from .dockerignore — cargo-chef regenerates lockfile in build context"

patterns-established:
  - "Registry Docker context is registry/ directory only — isolated workspace avoids sqlite3 link conflict with main mesh workspace"
  - "Binary name mesh-registry from Cargo.toml [[bin]] name field"

requirements-completed: [DEPLOY-143]

# Metrics
duration: 1min
completed: 2026-03-01
---

# Phase 143 Plan 01: Pre-deploy Code Fixes and Infrastructure Artifacts Summary

**Dockerfile/fly.toml deployment artifacts created, with_secure(true) and api.packages.meshlang.dev production fixes applied — registry ready for cloud provisioning**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-01T17:26:14Z
- **Completed:** 2026-03-01T17:27:05Z
- **Tasks:** 2 of 3 completed (Task 3 is a human-action checkpoint)
- **Files modified:** 5

## Accomplishments
- Fixed `with_secure(false)` to `with_secure(true)` in registry/src/main.rs — sessions are now HTTPS-only for production
- Updated `DEFAULT_REGISTRY` constant in compiler/meshpkg/src/main.rs from placeholder `registry.meshlang.dev` to `api.packages.meshlang.dev`
- Created multi-stage cargo-chef Dockerfile for Fly.io deployment (planner → builder → debian:bookworm-slim runtime)
- Created .dockerignore excluding target/ to prevent 500MB+ build context upload
- Created fly.toml with force_https, always-on config (no cold starts for package registry)

## Task Commits

Each task was committed atomically:

1. **Task 1: Production code fixes — with_secure and DEFAULT_REGISTRY URL** - `fdd5f87f` (fix)
2. **Task 2: Create Dockerfile, .dockerignore, and fly.toml for registry** - `b9193d68` (chore)
3. **Task 3: Provision cloud infrastructure and set secrets** - CHECKPOINT (human-action required)

## Files Created/Modified
- `registry/src/main.rs` - Changed with_secure(false) to with_secure(true) for production HTTPS session cookies
- `compiler/meshpkg/src/main.rs` - Updated DEFAULT_REGISTRY to https://api.packages.meshlang.dev
- `registry/Dockerfile` - Multi-stage cargo-chef build: planner, builder, debian:bookworm-slim runtime; exposes port 3000
- `registry/.dockerignore` - Excludes target/, Cargo.lock, .env, .env.* from Docker build context
- `registry/fly.toml` - App=mesh-registry, region=iad, port=3000, force_https=true, min_machines_running=1, auto_stop_machines=false

## Decisions Made
- with_secure(true) is correct for Fly.io because TLS terminates at the edge proxy before reaching the container; the internal connection is HTTP but external clients always use HTTPS
- cargo-chef multi-stage pattern chosen for Docker layer caching — dependency compilation is cached separately from source changes, dramatically reducing rebuild times
- auto_stop_machines=false and min_machines_running=1 selected because the package registry must respond instantly to meshpkg install commands without cold start delays
- primary_region=iad (US East) per CONTEXT.md Claude's discretion

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

Task 3 is a `checkpoint:human-action` gate. The user must manually provision:
1. Cloudflare R2 bucket "mesh-packages" and generate API credentials
2. GitHub OAuth App with callback URL https://api.packages.meshlang.dev/auth/callback
3. Fly.io app (fly launch --name mesh-registry --region iad --no-deploy)
4. Fly Postgres (fly postgres create + fly postgres attach)
5. All 9 Fly secrets (STORAGE_*, GITHUB_*, SESSION_SECRET)
6. DNS CNAME record for api.packages.meshlang.dev → mesh-registry.fly.dev
7. fly certs add api.packages.meshlang.dev --app mesh-registry

Full step-by-step commands are in 143-01-PLAN.md Task 3 `<what-needs-doing>` section.

**Verification commands after provisioning:**
```bash
fly secrets list --app mesh-registry
# Should show 10 secrets: DATABASE_URL, STORAGE_ENDPOINT, STORAGE_BUCKET,
# STORAGE_ACCESS_KEY_ID, STORAGE_SECRET_ACCESS_KEY, STORAGE_REGION,
# GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, GITHUB_CALLBACK_URL, SESSION_SECRET

npx wrangler r2 bucket list
# Should show mesh-packages bucket

fly certs list --app mesh-registry
# Should show api.packages.meshlang.dev (pending or issued)
```

**Resume signal:** Type "provisioned" when all secrets are set and DNS records are created.

## Next Phase Readiness
- Code artifacts and Fly.io config are complete — all 5 files ready for deployment
- Blocked on human provisioning of Fly.io app, Fly Postgres, Cloudflare R2, GitHub OAuth App, DNS, and secrets
- Once Task 3 checkpoint is cleared, Plan 04 can proceed with `fly deploy`

---
*Phase: 143-deploy-everything-including-new-stuff-from-v14*
*Completed: 2026-03-01*
