---
phase: 137-http-client-improvements
plan: "01"
subsystem: http-client
tags: [http, ureq, builder-api, stdlib, compiler-registration]
dependency_graph:
  requires: []
  provides: [Http.build, Http.header, Http.body, Http.timeout, Http.query, Http.json, Http.send, HttpResponse]
  affects: [mesh-rt, mesh-typeck, mesh-codegen, meshc-e2e]
tech_stack:
  added: ["ureq 3.2.0 (upgraded from 2.12.1)"]
  patterns: ["opaque-handle (Box::into_raw)", "5-point stdlib registration", "Atom-to-String ABI lowering"]
key_files:
  created:
    - tests/e2e/http_client_builder.mpl
  modified:
    - compiler/mesh-rt/Cargo.toml
    - compiler/mesh-rt/src/http/client.rs
    - compiler/mesh-rt/src/http/mod.rs
    - compiler/mesh-typeck/src/builtins.rs
    - compiler/mesh-typeck/src/infer.rs
    - compiler/mesh-codegen/src/mir/lower.rs
    - compiler/mesh-codegen/src/codegen/intrinsics.rs
    - compiler/meshc/tests/e2e.rs
decisions:
  - "Atom type for Http.build first parameter — :get/:post atoms type-check correctly; same pattern as DateTime.add :day/:hour"
  - "MeshRequest handle is u64 ABI (MirType::Int) via Box::into_raw — same as SqliteConn pattern"
  - "http_status_as_error(false) set at Agent level via config_builder — ureq 3 moved this from per-request to per-Agent config"
  - "is_body_method check: POST/PUT/PATCH/DELETE use send(), GET/HEAD/OPTIONS/DELETE-no-body use call()"
metrics:
  duration: "~16 minutes"
  completed: "2026-02-28"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 8
  files_created: 1
---

# Phase 137 Plan 01: Http Client Builder API Summary

**One-liner:** Http builder API (Http.build/header/body/timeout/query/json/send) with ureq 3.2.0 upgrade, MeshRequest opaque handle, HttpResponse struct, and 5-point compiler registration enabling `resp.status/body/headers` field access.

## What Was Built

### Task 1: ureq 3 upgrade + client.rs rewrite

- Upgraded `ureq = "2"` to `ureq = { version = "3", features = ["gzip"] }` in `compiler/mesh-rt/Cargo.toml`
- Rewrote `compiler/mesh-rt/src/http/client.rs`:
  - Updated `mesh_http_get` / `mesh_http_post` to ureq 3 API (`response.body_mut().read_to_string()`)
  - Added `MeshRequestData` struct (heap-owned, Box::into_raw pattern)
  - Added `MeshClientResponse #[repr(C)]` struct with `status: i64, body: *mut u8, headers: *mut u8`
  - Implemented all 7 builder functions: `mesh_http_build`, `mesh_http_header`, `mesh_http_body`, `mesh_http_timeout`, `mesh_http_query`, `mesh_http_json`, `mesh_http_send`
  - `mesh_http_send` builds `Agent` with `http_status_as_error(false)` and optional timeout, dispatches to ureq 3 methods
  - Error messages prefixed with TIMEOUT:/DNS_FAILURE:/TLS_ERROR: for Mesh pattern matching
- Updated `compiler/mesh-rt/src/http/mod.rs` to export all 7 new functions

### Task 2: 5-point compiler registration

All 5 registration points updated:

1. **builtins.rs** — Added `http_build/header/body/timeout/query/json/send` + `HttpResponse` type constructor. Used `Atom` type for `Http.build` first parameter (`:get`, `:post` literals).
2. **infer.rs stdlib_modules()** — Added `Http` module HashMap with 7 builder functions.
3. **infer.rs STDLIB_MODULE_NAMES** — Added `"Http"` to the constant.
4. **infer.rs infer_with_imports** — Registered `HttpResponse` as `StructDefInfo` with `status: Int, body: String, headers: Map<String, String>` for field access.
5. **lower.rs STDLIB_MODULES** — Added `"Http"`.
6. **lower.rs map_builtin_name** — Added `http_* => mesh_http_*` mappings.
7. **lower.rs known_functions** — Registered MIR types for all 7 functions (handle as `MirType::Int`).
8. **lower.rs lower_to_mir** — Pre-seeded `HttpResponse MirStructDef` with `status/body/headers` for LLVM field access.
9. **intrinsics.rs** — Added LLVM external declarations for `mesh_http_build` through `mesh_http_send`.

### Task 3: e2e compile test

- Created `tests/e2e/http_client_builder.mpl` — exercises Http.build/header/timeout chain, prints "built"
- Added `e2e_http_builder_compiles` test to `compiler/meshc/tests/e2e.rs`
- Test passes: the Mesh program compiles and runs without network access

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Atom type required for Http.build first parameter**
- **Found during:** Task 3 (e2e test run)
- **Issue:** Plan specified `http_build` first parameter as `String`, but Mesh source uses `:get` atom literal which has type `Atom` in the typechecker. Passing Atom where String is expected fails type checking.
- **Fix:** Changed `http_build` first parameter type from `Ty::string()` to `Ty::Con(TyCon::new("Atom"))` in both `builtins.rs` and `infer.rs stdlib_modules()`. Same pattern as `DateTime.add` unit parameter.
- **Files modified:** `compiler/mesh-typeck/src/builtins.rs`, `compiler/mesh-typeck/src/infer.rs`
- **Commit:** 72dbf82f

**2. [Rule 1 - Bug] Duplicate `let mut req` in mesh_http_send body branch**
- **Found during:** Task 1 (cargo build produced unused_mut warnings)
- **Issue:** Draft code created a `let mut req = agent.post(...)` then immediately overwrote it with `let req = match method { ... }` — dead code.
- **Fix:** Removed the duplicate line, using only the match dispatch.
- **Files modified:** `compiler/mesh-rt/src/http/client.rs`
- **Commit:** ae654e5a

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | ae654e5a | feat(137-01): upgrade ureq to 3, add MeshRequest builder API to client.rs |
| 2 | 94dd20ac | feat(137-01): register Http module through all 5 compiler points + HttpResponse struct |
| 3 | 72dbf82f | feat(137-01): add e2e test + fix Atom type for Http.build method parameter |

## Self-Check: PASSED

All key files verified present:
- compiler/mesh-rt/src/http/client.rs — FOUND
- compiler/mesh-rt/Cargo.toml — FOUND (ureq 3)
- tests/e2e/http_client_builder.mpl — FOUND
- .planning/phases/137-http-client-improvements/137-01-SUMMARY.md — FOUND

All commits verified:
- ae654e5a — FOUND
- 94dd20ac — FOUND
- 72dbf82f — FOUND

Key content verified:
- mesh_http_build in client.rs — FOUND
- MeshClientResponse in client.rs — FOUND
- "Http" in STDLIB_MODULE_NAMES — FOUND
- mesh_http_build in intrinsics.rs — FOUND
- HttpResponse in infer.rs — FOUND
