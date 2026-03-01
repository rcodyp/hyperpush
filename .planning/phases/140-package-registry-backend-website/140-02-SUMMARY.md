---
phase: 140-package-registry-backend-website
plan: "02"
subsystem: api
tags: [axum, sqlx, postgres, r2, aws-sdk-s3, flate2, tar, sha256, tokio-util, streaming]

# Dependency graph
requires:
  - phase: 140-package-registry-backend-website
    plan: "01"
    provides: "AppState, AppError, db::packages, db::tokens, storage::r2 — all query functions and R2Client ready"

provides:
  - "POST /api/v1/packages: authenticated publish with SHA-256 verification, namespace check, dedup (409), README.md extraction from tar.gz"
  - "GET /api/v1/packages/{name}/{version}/download: streaming tarball proxy from R2 via ReaderStream (no buffering)"
  - "GET /api/v1/packages?search={q}: PostgreSQL FTS via tsvector when query present, full list fallback"
  - "GET /api/v1/packages/{name}: package metadata with {latest: {version, sha256}, readme, description, owner, download_count}"
  - "GET /api/v1/packages/{name}/{version}: version metadata with {sha256}"
  - "Axum 0.8 router with {param} path syntax, 50MB DefaultBodyLimit on publish, CorsLayer + TraceLayer"

affects:
  - "140-03-PLAN.md"
  - "140-04-PLAN.md"

# Tech tracking
tech-stack:
  added:
    - "flate2 = 1 (gzip decompression for README extraction from tar.gz)"
    - "tar = 0.4 (tarball entry walking for README extraction)"
  patterns:
    - "Runtime sqlx::query_as() throughout (no compile-time macros, no live DB during scaffold)"
    - "DB-first insert pattern: version_exists() fast 409 + UNIQUE constraint serializes concurrent duplicates"
    - "R2 upload after DB insert: idempotent via object_exists() sha256 key check"
    - "Streaming via Body::from_stream(ReaderStream::new(s3_resp.body.into_async_read()))"
    - "Namespace enforcement: package_name.starts_with(format!('{owner}/'))"

key-files:
  created:
    - "registry/src/routes/publish.rs"
    - "registry/src/routes/download.rs"
    - "registry/src/routes/search.rs"
    - "registry/src/routes/metadata.rs"
  modified:
    - "registry/src/routes/mod.rs"
    - "registry/src/routes/auth.rs"
    - "registry/Cargo.toml"

key-decisions:
  - "Runtime sqlx::query_as() for user UUID lookup in publish (no sqlx::query! macro — no live DB)"
  - "extract_readme_from_tarball: case-insensitive file_name.to_lowercase() == 'readme.md' to handle README.md/readme.md/Readme.md variants"
  - "DefaultBodyLimit::max(50MB) applied via .layer() on the publish route chain — not globally"
  - "Axum 0.8 path syntax {name} and {version} throughout (not :name/:version)"

patterns-established:
  - "Route handlers use State<Arc<AppState>> extractor for pool + s3 + config"
  - "AppError variants map to HTTP status codes via IntoResponse in error.rs"
  - "Path extractor tuple destructuring: Path((name, version)): Path<(String, String)>"

requirements-completed: [REG-01, REG-04]

# Metrics
duration: 3min
completed: 2026-03-01
---

# Phase 140 Plan 02: API Routes Summary

**Five Axum API routes for the mesh package registry: authenticated publish with SHA-256 + README.md extraction, streaming R2 download, PostgreSQL FTS search, and package/version metadata with readme field for the website**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-01T05:20:56Z
- **Completed:** 2026-03-01T05:24:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Publish handler validates Bearer token (Argon2id hash lookup), enforces namespace scoping (github_login/...), verifies SHA-256 against X-Package-SHA256 header, extracts README.md case-insensitively from tar.gz using flate2+tar, uses TOCTOU-safe DB-first insert pattern, conditionally uploads to R2
- Download handler streams tarball bytes from R2 via ReaderStream without buffering the full body, increments download counter
- Search handler: PostgreSQL FTS via tsvector plainto_tsquery when ?search= present, falls back to full list sorted by download_count+recency
- Metadata handlers: version_handler returns {sha256}, package_handler returns {latest: {version, sha256}, readme, description, owner, download_count} — readme field satisfies REG-04 requirement for per-package website display
- Full Axum 0.8 router wired with {param} path syntax, 50MB DefaultBodyLimit on publish route, CorsLayer::permissive() + TraceLayer

## Task Commits

Each task was committed atomically:

1. **Task 1: Publish handler with auth, SHA-256, dedup, namespace, README extraction** - `703c11c6` (feat)
2. **Task 2: Download/search/metadata routes + full Axum router wiring** - `4829e5d4` (feat)

## Files Created/Modified

- `registry/src/routes/publish.rs` - POST /api/v1/packages: Bearer auth, namespace check, SHA-256 verify, flate2+tar README extraction, DB-first insert, conditional R2 upload
- `registry/src/routes/download.rs` - GET download: R2 streaming via ReaderStream, download counter increment
- `registry/src/routes/search.rs` - GET /api/v1/packages: FTS search via tsvector or full list fallback
- `registry/src/routes/metadata.rs` - version_handler (sha256) + package_handler (latest + readme)
- `registry/src/routes/mod.rs` - Full Axum 0.8 router with all 5 API routes + auth routes, 50MB limit, CORS+trace layers
- `registry/src/routes/auth.rs` - Complete GitHub OAuth + session + token management (linter pre-populated Plan 03 work)
- `registry/Cargo.toml` - Added flate2 = "1" and tar = "0.4" workspace deps

## Decisions Made

- Used runtime `sqlx::query_as::<_, UserIdRow>()` for user UUID lookup in publish handler — consistent with Plan 01 decision to avoid compile-time macros (no live DB, no `.sqlx/` cache)
- `extract_readme_from_tarball`: case-insensitive match via `file_name.to_lowercase() == "readme.md"` handles README.md, readme.md, Readme.md variants
- `DefaultBodyLimit::max(50 * 1024 * 1024)` applied via `.layer()` on the publish route chain (not globally)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced sqlx::query!() macro with runtime query in publish.rs**
- **Found during:** Task 1 (publish handler)
- **Issue:** Plan's publish handler code used `sqlx::query!("SELECT id FROM users WHERE github_login = $1", owner)` compile-time macro. No `.sqlx/` offline cache exists in registry/, so this would fail with "no cached data for this query" even under SQLX_OFFLINE=true.
- **Fix:** Replaced with `sqlx::query_as::<_, UserIdRow>()` runtime query with `.bind(&owner)` — consistent with Plan 01's established pattern for all DB queries in this codebase.
- **Files modified:** `registry/src/routes/publish.rs`
- **Verification:** `cargo check` passes with zero errors
- **Committed in:** `703c11c6` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug fix, runtime macro replacement)
**Impact on plan:** Fix necessary to match the runtime query pattern established in Plan 01 (no compile-time macros without live DB). No scope creep. All plan requirements met.

## Issues Encountered

The linter pre-populated `auth.rs` with a complete GitHub OAuth implementation (Plan 03 work) before Task 2 ran. This was incorporated into the router wiring without issue — the auth routes were already present and compiling.

## Next Phase Readiness

- **Plan 03 (GitHub OAuth)**: auth.rs already has complete implementation (linter pre-filled). Router already wires all auth routes. Plan 03 may need to verify session middleware configuration in main.rs.
- **Plan 04 (Website)**: Package metadata API returns `readme` field (null if no README in tarball) for per-package VitePress pages.
- All 5 registry API routes compile cleanly with zero errors.

## Self-Check: PASSED

Files present:
- registry/src/routes/publish.rs: FOUND
- registry/src/routes/download.rs: FOUND
- registry/src/routes/search.rs: FOUND
- registry/src/routes/metadata.rs: FOUND
- registry/src/routes/mod.rs: FOUND

Commits present:
- 703c11c6: FOUND (Task 1 - publish handler)
- 4829e5d4: FOUND (Task 2 - remaining routes + router)

---
*Phase: 140-package-registry-backend-website*
*Completed: 2026-03-01*
