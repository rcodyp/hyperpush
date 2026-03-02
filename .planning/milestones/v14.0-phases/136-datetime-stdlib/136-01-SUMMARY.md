---
phase: 136-datetime-stdlib
plan: 01
subsystem: stdlib
tags: [chrono, datetime, rust, ffi, llvm, typeck]

# Dependency graph
requires:
  - phase: 135-encoding-crypto-stdlib
    provides: five-registration-point pattern for stdlib modules (builtins.rs, infer.rs STDLIB_MODULE_NAMES, infer.rs stdlib_modules(), lower.rs STDLIB_MODULES + map_builtin_name + known_functions, intrinsics.rs LLVM declarations)

provides:
  - 11 extern C runtime functions in mesh-rt/src/datetime.rs backed by chrono 0.4
  - DateTime type registered as opaque TyCon (Ty::Con(TyCon::new("DateTime"))) in typeck
  - DateTime module in STDLIB_MODULE_NAMES and stdlib_modules() HashMap in infer.rs
  - DateTime in STDLIB_MODULES + 11 map_builtin_name entries + 11 known_functions MIR registrations in lower.rs
  - 11 LLVM External declarations in intrinsics.rs with correct i64/f64/i8/ptr types
  - ABI: DateTime is always i64 Unix milliseconds at all boundaries

affects:
  - 136-datetime-stdlib plan 02 (e2e tests)
  - Any phase using DateTime.utc_now(), from_iso8601(), to_iso8601(), from/to_unix_ms(), from/to_unix_secs(), add(), diff(), before?(), after?()

# Tech tracking
tech-stack:
  added:
    - "chrono = { version = \"0.4\", features = [\"clock\"] } — Rust datetime library for parsing, formatting, arithmetic"
  patterns:
    - "Five-registration-point stdlib module pattern (same as Phase 135 Crypto/Base64/Hex)"
    - "DateTime ABI: i64 Unix milliseconds everywhere — no heap allocation for DateTime values"
    - "Result-returning functions box i64 payload via Box::into_raw(Box::new(ms)) as *mut u8"
    - "Bool-returning functions (before?, after?) use i8 ABI: 1=true, 0=false"
    - "diff() returns f64 (MirType::Float) not i64 — fractional precision for sub-ms granularity"
    - "before?/after? strip ? in map_builtin_name: 'datetime_before?' => 'mesh_datetime_before'"

key-files:
  created:
    - "compiler/mesh-rt/src/datetime.rs — 11 extern C functions: utc_now, from_iso8601, to_iso8601, from_unix_ms, to_unix_ms, from_unix_secs, to_unix_secs, add, diff, before, after"
  modified:
    - "compiler/mesh-rt/Cargo.toml — added chrono 0.4 with clock feature"
    - "compiler/mesh-rt/src/lib.rs — added pub mod datetime;"
    - "compiler/mesh-typeck/src/builtins.rs — DateTime type + 11 function type registrations"
    - "compiler/mesh-typeck/src/infer.rs — DateTime in STDLIB_MODULE_NAMES and stdlib_modules()"
    - "compiler/mesh-codegen/src/mir/lower.rs — DateTime in STDLIB_MODULES, 11 map_builtin_name entries, 11 known_functions MIR types"
    - "compiler/mesh-codegen/src/codegen/intrinsics.rs — 11 LLVM External declarations"

key-decisions:
  - "DateTime ABI is i64 Unix milliseconds — confirmed from Phase 136 research, avoids new type machinery in typeck/codegen"
  - "diff() return type is MirType::Float (f64) not MirType::Int — fractional precision for sub-second computations"
  - "before?/after? function names retain ? in Mesh source but drop ? in C symbol names (C symbols cannot contain ?)"
  - "chrono::DateTime::from_timestamp() used for from_unix_secs (not deprecated variant) — matched chrono 0.4.44 API"
  - "alloc_result pattern: Ok payload boxed via Box::into_raw(Box::new(ms)) as *mut u8 — same as SqliteConn pattern"

patterns-established:
  - "DateTime module follows identical five-point registration pattern as Phase 135 Crypto/Base64/Hex"
  - "Opaque type (Ty::Con(TyCon::new('DateTime'))) registered in builtins.rs for type annotation support"

requirements-completed: [DTIME-01, DTIME-02, DTIME-03, DTIME-04, DTIME-05, DTIME-06, DTIME-07, DTIME-08]

# Metrics
duration: ~10min
completed: 2026-02-28
---

# Phase 136 Plan 01: DateTime Stdlib Runtime + Compiler Wiring Summary

**11 extern C datetime functions backed by chrono 0.4 with complete 5-point compiler registration: typeck builtins, infer STDLIB_MODULE_NAMES + stdlib_modules(), MIR lower STDLIB_MODULES + map_builtin_name + known_functions, and LLVM intrinsics — DateTime ABI is i64 Unix milliseconds throughout**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-02-28T07:50:00Z
- **Completed:** 2026-02-28T08:02:23Z
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Created `compiler/mesh-rt/src/datetime.rs` with 11 `#[no_mangle] extern "C"` functions backed by chrono 0.4.44
- Wired DateTime through all 5 compiler registration points (builtins.rs, infer.rs x2, lower.rs x3, intrinsics.rs)
- `cargo build --workspace` succeeds with zero errors after both tasks
- DateTime module accessible in Mesh source as `DateTime.utc_now()`, `DateTime.from_iso8601(s)`, etc.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add chrono dep, create datetime.rs runtime module, register in lib.rs** - `d8faaa89` (feat)
2. **Task 2: Wire DateTime through typeck, infer.rs, MIR lower, and LLVM intrinsics** - `28bb5ef9` (feat)

## Files Created/Modified

- `compiler/mesh-rt/src/datetime.rs` - 11 extern C functions: utc_now (returns current time), from_iso8601/to_iso8601 (RFC 3339 parse/format), from_unix_ms/to_unix_ms/from_unix_secs/to_unix_secs (Unix timestamp interop), add (duration arithmetic), diff (returns f64), before/after (comparison returning i8 Bool)
- `compiler/mesh-rt/Cargo.toml` - chrono = { version = "0.4", features = ["clock"] }
- `compiler/mesh-rt/src/lib.rs` - pub mod datetime; added after pub mod crypto;
- `compiler/mesh-typeck/src/builtins.rs` - DateTime type constructor + 11 function type registrations (dt_t = Ty::Con(TyCon::new("DateTime")))
- `compiler/mesh-typeck/src/infer.rs` - "DateTime" added to STDLIB_MODULE_NAMES; datetime_mod with 11 methods inserted into stdlib_modules() HashMap
- `compiler/mesh-codegen/src/mir/lower.rs` - "DateTime" in STDLIB_MODULES; 11 map_builtin_name match arms (datetime_before? => mesh_datetime_before strips ?); 11 known_functions MIR type entries
- `compiler/mesh-codegen/src/codegen/intrinsics.rs` - 11 LLVM External declarations (f64_type for diff, i8_type for before/after, i64_type for DateTime-typed args)

## Decisions Made

- DateTime ABI is i64 Unix milliseconds throughout — confirmed from Phase 136 research, avoids new type machinery
- `diff()` returns `MirType::Float` (f64), not `MirType::Int` — fractional precision for sub-second computations
- `before?`/`after?` retain `?` in Mesh source names but drop `?` in C symbol names (C symbols cannot contain `?`)
- `alloc_result` pattern: Ok i64 payload boxed via `Box::into_raw(Box::new(ms)) as *mut u8` — same as SqliteConn

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DateTime runtime and compiler wiring complete; plan 02 (e2e tests) can now compile Mesh programs using DateTime
- All 11 functions available: `DateTime.utc_now()`, `DateTime.from_iso8601(s)`, `DateTime.to_iso8601(dt)`, `DateTime.from_unix_ms(n)`, `DateTime.to_unix_ms(dt)`, `DateTime.from_unix_secs(n)`, `DateTime.to_unix_secs(dt)`, `DateTime.add(dt, n, unit)`, `DateTime.diff(dt1, dt2, unit)`, `DateTime.before?(dt1, dt2)`, `DateTime.after?(dt1, dt2)`

---
*Phase: 136-datetime-stdlib*
*Completed: 2026-02-28*

## Self-Check: PASSED
