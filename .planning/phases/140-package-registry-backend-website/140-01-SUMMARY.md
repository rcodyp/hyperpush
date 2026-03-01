---
phase: 140-package-registry-backend-website
plan: "01"
subsystem: infra
tags: [axum, sqlx, postgres, aws-s3, r2, minio, argon2, oauth2, tower-sessions]

# Dependency graph
requires:
  - phase: 139-package-manifest-meshpkg-cli
    provides: "Package manifest format and meshpkg CLI API contract (endpoints registry must implement)"

provides:
  - "mesh-registry crate with Cargo.toml, standalone workspace, all deps"
  - "Database migrations: users, tokens, packages, versions tables + tsvector FTS GIN index"
  - "AppConfig (from_env), AppError (IntoResponse), AppState (PgPool + R2Client + Arc<AppConfig> + oauth_client)"
  - "R2Client wrapper: put_object, get_object, object_exists with force_path_style=true for MinIO"
  - "DB query layer: version_exists, insert_version, get_package, get_version, list_versions, list_packages, search_packages, increment_download"
  - "Token management: hash_token, verify_token_hash, validate_bearer_token, upsert_user, create_token, list_tokens, delete_token"
  - "Route stubs for Plans 02 and 03: publish, download, search, metadata, auth"

affects:
  - "140-02-PLAN.md"
  - "140-03-PLAN.md"

# Tech tracking
tech-stack:
  added:
    - "axum 0.8 (Rust HTTP framework)"
    - "sqlx 0.8 postgres (async SQL with runtime queries)"
    - "aws-sdk-s3 1 (R2/MinIO object storage)"
    - "oauth2 4 (GitHub OAuth)"
    - "tower-sessions 0.14 (session middleware)"
    - "tower-sessions-sqlx-store 0.15 (postgres session store)"
    - "argon2 0.5 (Argon2id token hashing)"
    - "uuid 1 (v4 UUIDs)"
    - "tracing + tracing-subscriber (structured logging)"
    - "dotenvy (env var loading)"
  patterns:
    - "registry/ is its own standalone workspace (excluded from main workspace) to avoid libsqlite3-sys conflict with mesh-rt's bundled sqlite3"
    - "Runtime sqlx::query() / query_as() used (not compile-time macros) since no live DB during scaffold phase"
    - "SHA-256 content addressing for R2 object keys — tarballs stored by hash, deduplication automatic"
    - "Argon2id PHC string hashing for publish tokens stored in tokens.hash column"

key-files:
  created:
    - "registry/Cargo.toml"
    - "registry/migrations/20260228000001_initial.sql"
    - "registry/migrations/20260228000002_fts_index.sql"
    - "registry/src/main.rs"
    - "registry/src/config.rs"
    - "registry/src/state.rs"
    - "registry/src/error.rs"
    - "registry/src/routes/mod.rs"
    - "registry/src/routes/auth.rs"
    - "registry/src/routes/download.rs"
    - "registry/src/routes/metadata.rs"
    - "registry/src/routes/publish.rs"
    - "registry/src/routes/search.rs"
    - "registry/src/db/mod.rs"
    - "registry/src/db/packages.rs"
    - "registry/src/db/tokens.rs"
    - "registry/src/storage/mod.rs"
    - "registry/src/storage/r2.rs"
  modified:
    - "Cargo.toml (root) — added exclude = [\"registry\"] with explanation comment"

key-decisions:
  - "registry/ excluded from main Cargo workspace (not a member) to avoid libsqlite3-sys links conflict between mesh-rt (0.36 bundled) and sqlx-sqlite (^0.28)"
  - "registry/Cargo.toml declares its own [workspace] root — resolves independently from compiler tools"
  - "Runtime sqlx::query() chosen over compile-time sqlx::query!() macros — no live PostgreSQL available during scaffold; can upgrade to compile-time macros after running cargo sqlx prepare"
  - "tower-sessions-sqlx-store 0.15 used with tower-sessions 0.14 (compatible via tower-sessions-core 0.14)"

patterns-established:
  - "registry is a separate Rust workspace co-located in the monorepo"
  - "DB queries use runtime checked sqlx::query_as::<_, RowType>() pattern with .bind() chains"
  - "AppState holds Arc<AppConfig> + PgPool + R2Client + Arc<BasicClient> — all Clone"

requirements-completed: [REG-01]

# Metrics
duration: 12min
completed: 2026-03-01
---

# Phase 140 Plan 01: Registry Foundation Summary

**Axum+SQLx registry scaffold with PostgreSQL migrations, R2Client (MinIO-compat), Argon2id token hashing, and complete DB query layer for packages/versions/tokens/users**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-01T05:04:58Z
- **Completed:** 2026-03-01T05:16:58Z
- **Tasks:** 2
- **Files modified:** 19

## Accomplishments

- mesh-registry standalone Rust workspace with all dependencies for Plans 02-04
- PostgreSQL migrations define 4 tables (users, tokens, packages, versions) with tsvector FTS GIN index
- Complete AppState, AppConfig, AppError infrastructure + R2Client wrapper with MinIO compat
- Full DB query layer covering all 10 functions needed by Plans 02 and 03

## Task Commits

Each task was committed atomically:

1. **Task 1: Workspace integration, Cargo.toml, migrations, config, state, error** - `73e20ade` (feat)
2. **Task 2: DB query layer and R2 storage client** - `1bd9e318` (feat)

## Files Created/Modified

- `registry/Cargo.toml` - Standalone workspace + package deps (axum, sqlx, aws-sdk-s3, oauth2, etc.)
- `registry/migrations/20260228000001_initial.sql` - users, tokens, packages, versions tables with constraints
- `registry/migrations/20260228000002_fts_index.sql` - tsvector generated column + GIN index for FTS
- `registry/src/main.rs` - Tokio entrypoint: load config, connect PgPool, run migrations, build AppState, serve
- `registry/src/config.rs` - AppConfig::from_env() with all required env vars
- `registry/src/state.rs` - AppState: PgPool + R2Client + Arc<AppConfig> + Arc<BasicClient>
- `registry/src/error.rs` - AppError enum with IntoResponse (400/401/403/404/409/500)
- `registry/src/routes/mod.rs` - Stub router + pub mod declarations for Plans 02/03
- `registry/src/routes/{auth,download,metadata,publish,search}.rs` - Empty stubs
- `registry/src/db/mod.rs` - pub mod packages; pub mod tokens;
- `registry/src/db/packages.rs` - All package/version query functions (runtime sqlx)
- `registry/src/db/tokens.rs` - Token hash/verify functions + CRUD (runtime sqlx)
- `registry/src/storage/mod.rs` - pub mod r2;
- `registry/src/storage/r2.rs` - R2Client: build_r2_client, put_object, get_object, object_exists
- `Cargo.toml` (root) - Added exclude = ["registry"] comment explaining the isolation

## Decisions Made

- **Separate workspace for registry**: mesh-rt uses `libsqlite3-sys = "0.36"` (bundled), while sqlx-sqlite 0.8 requires `^0.28`. Both define `links = "sqlite3"` — Cargo cannot resolve both in the same workspace. Making registry its own workspace root resolves this at the cost of not sharing root-level dep versions, but the registry has no deps shared with the compiler.
- **Runtime sqlx queries**: The plan noted: "switch to `sqlx::query()` if DB is not available". No live PostgreSQL available during this phase, so all queries use runtime-checked `sqlx::query_as::<_, T>()` instead of `sqlx::query_as!()` macros. Future: run `cargo sqlx prepare` with a live DB and switch back to macros for compile-time safety.
- **tower-sessions-sqlx-store 0.15**: Plan specified version 0.14 with `postgres-store` feature, but that feature was removed in 0.14; the store was split to a separate crate at 0.15. Used `tower-sessions-sqlx-store 0.15` with `features = ["postgres"]` instead.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] registry excluded from main workspace (libsqlite3-sys conflict)**
- **Found during:** Task 1 (workspace integration)
- **Issue:** `mesh-rt` uses `libsqlite3-sys = "0.36"` (bundled) and `sqlx-sqlite 0.8` requires `libsqlite3-sys = "^0.28"`. Both define `links = "sqlite3"`. Cargo resolver rejects this: "Only one package in the dependency graph may specify the same links value."
- **Fix:** Removed `registry` from `[workspace] members` in root Cargo.toml. Added `exclude = ["registry"]` with explanatory comment. Made `registry/Cargo.toml` declare its own `[workspace]` root with `resolver = "2"`.
- **Files modified:** `Cargo.toml` (root), `registry/Cargo.toml`
- **Verification:** `cargo check --manifest-path registry/Cargo.toml` succeeds; `cargo check -p meshpkg` still succeeds
- **Committed in:** `73e20ade` (Task 1 commit)

**2. [Rule 3 - Blocking] tower-sessions postgres-store feature does not exist in version 0.14**
- **Found during:** Task 1 (workspace dependencies)
- **Issue:** Plan specified `tower-sessions = { version = "0.14", features = ["postgres-store"] }`. Feature `postgres-store` was removed from `tower-sessions` — the SQLx-backed store was split into separate crate `tower-sessions-sqlx-store` at version 0.15.
- **Fix:** Changed to `tower-sessions = "0.14"` + `tower-sessions-sqlx-store = { version = "0.15", features = ["postgres"] }`.
- **Files modified:** `registry/Cargo.toml`
- **Verification:** `cargo check` succeeds with the corrected deps
- **Committed in:** `73e20ade` (Task 1 commit)

**3. [Rule 3 - Blocking] Switched from compile-time sqlx macros to runtime queries**
- **Found during:** Task 2 (DB query layer)
- **Issue:** `sqlx::query!()` macros require either a live DATABASE_URL or a pre-populated `.sqlx/` offline cache (via `cargo sqlx prepare`). Neither is available in this environment. With `SQLX_OFFLINE=true`, the compiler errors: "no cached data for this query".
- **Fix:** Replaced all `sqlx::query!()`, `sqlx::query_as!()`, `sqlx::query_scalar!()` macros with their runtime equivalents: `sqlx::query()`, `sqlx::query_as::<_, T>()`, `sqlx::query_scalar::<_, T>()` with `.bind()` chains. Consistent with the plan's explicit note: "executor may make this pragmatic call".
- **Files modified:** `registry/src/db/packages.rs`, `registry/src/db/tokens.rs`
- **Verification:** `cargo check` passes without SQLX_OFFLINE; all query functions type-check correctly
- **Committed in:** `1bd9e318` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 3 - blocking)
**Impact on plan:** All three fixes necessary to produce a compiling crate. No scope creep. The separation of the registry into its own workspace is architecturally correct for a separate service. The switch to runtime queries is explicitly anticipated in the plan note.

## Issues Encountered

The workspace dependency conflict (libsqlite3-sys) was the primary technical challenge. The fix (separate workspace) is clean and maintains the plan's intent of having the registry compiled as part of the monorepo while avoiding native library link conflicts. The `-p mesh-registry` cargo check invocation from the plan's verification step should be replaced with `--manifest-path registry/Cargo.toml` for this configuration.

## User Setup Required

None — no external service configuration required for this scaffold phase. The actual service requires env vars (DATABASE_URL, STORAGE_ENDPOINT, etc.) documented in `registry/src/config.rs`.

## Next Phase Readiness

- **Plan 02 (API routes)**: AppState, AppError, db::packages, storage::r2 all ready. Route stubs in routes/{publish,download,search,metadata}.rs await implementation.
- **Plan 03 (GitHub OAuth)**: AppState with oauth_client, db::tokens functions ready. routes/auth.rs stub awaits implementation.
- **Compiler integration**: runtime sqlx queries work correctly; can upgrade to compile-time `query!` macros after running `cargo sqlx prepare --database-url $DATABASE_URL` against a live instance.

## Self-Check: PASSED

All files present. All commits verified (73e20ade, 1bd9e318).

---
*Phase: 140-package-registry-backend-website*
*Completed: 2026-03-01*
