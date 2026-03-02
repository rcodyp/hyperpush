---
phase: 136-datetime-stdlib
plan: 02
subsystem: testing
tags: [datetime, chrono, e2e, llvm, codegen, typeck, atoms]

# Dependency graph
requires:
  - phase: 136-01
    provides: DateTime runtime (datetime.rs, 11 extern C functions, chrono 0.4, compiler wiring)
provides:
  - 6 Mesh e2e fixture files covering all 8 DTIME requirements
  - 6 Rust e2e test functions in meshc test suite
  - DateTime MirType::Int registration in codegen (resolve_con)
  - Boxed scalar deref in Ok pattern matching (pattern.rs)
  - Atom literal semantics for unit params (no colon prefix at runtime)
  - is_before / is_after naming (avoids ? try-operator and after keyword)
affects: [137-http-client, 138-testing-framework]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DateTime opaque type registered as MirType::Int in resolve_con — opaque named types backed by scalar ABI need explicit MirType mapping"
    - "Boxed scalar Ok payload: should_deref_boxed_payload extends to Int/Float/Bool — any scalar returned via Box::into_raw needs deref in pattern binding"
    - "Atom literals lowered without colon by atom_text() — runtime match arms use bare names (day, hour) not (:day, :hour)"
    - "Mesh case arms are single-expression — multi-statement logic in arm body requires a helper function"

key-files:
  created:
    - tests/e2e/datetime_utc_now.mpl
    - tests/e2e/datetime_iso8601_roundtrip.mpl
    - tests/e2e/datetime_unix_ms.mpl
    - tests/e2e/datetime_unix_secs.mpl
    - tests/e2e/datetime_add_diff.mpl
    - tests/e2e/datetime_compare.mpl
  modified:
    - compiler/meshc/tests/e2e.rs
    - compiler/mesh-codegen/src/mir/types.rs
    - compiler/mesh-codegen/src/codegen/pattern.rs
    - compiler/mesh-codegen/src/mir/lower.rs
    - compiler/mesh-typeck/src/builtins.rs
    - compiler/mesh-typeck/src/infer.rs
    - compiler/mesh-rt/src/datetime.rs
    - compiler/mesh-rt/Cargo.toml

key-decisions:
  - "DateTime renamed before?/after? to is_before/is_after: ? is the Mesh postfix try operator, not part of an identifier; also 'after' is a keyword (AFTER_KW in parser for receive-timeout clauses)"
  - "Atom unit params typed as Ty::Con(TyCon::new(\"Atom\")) not Ty::string() — ensures typeck rejects non-atom arguments at compile time"
  - "Fixtures use helper functions (fn print_diff, fn from_later) to work around single-expression case arm constraint"
  - "Float diff of whole-number days prints as '7' not '7.0' — Rust f64::to_string() omits .0 for whole numbers; test assertions adjusted accordingly"

patterns-established:
  - "Opaque named type backed by scalar: register in resolve_con as MirType::Int (or Float/Bool) — not MirType::Struct"
  - "Result<ScalarType, _>: extend should_deref_boxed_payload to cover MirType::Int | MirType::Float | MirType::Bool"
  - "Atom literals in Mesh: :day lowers to the string 'day' (without colon) via atom_text() — runtime match on bare name"

requirements-completed: [DTIME-01, DTIME-02, DTIME-03, DTIME-04, DTIME-05, DTIME-06, DTIME-07, DTIME-08]

# Metrics
duration: 90min
completed: 2026-02-28
---

# Phase 136 Plan 02: DateTime E2E Tests Summary

**6 Mesh e2e fixtures and 6 Rust test functions proving DateTime round-trips, arithmetic, and comparison, with 10 compiler bug fixes required to make the DateTime opaque type work end-to-end**

## Performance

- **Duration:** ~90 min (multi-session including debugging)
- **Started:** 2026-02-28T07:30:00Z
- **Completed:** 2026-02-28T09:00:00Z
- **Tasks:** 2 of 2
- **Files modified:** 15

## Accomplishments

- All 6 `e2e_datetime_*` tests pass: utc_now, iso8601_roundtrip, unix_ms, unix_secs, add_diff, compare
- Phase 135 crypto regression tests still pass (5/5) — no regressions introduced
- Discovered and fixed 10 bugs in the DateTime compiler pipeline that blocked the tests

## Task Commits

Each task was committed atomically:

1. **Task 1: Write 6 DateTime e2e Mesh fixture files** - `d4d6fe77` (feat)
2. **Task 2: Add 6 DateTime Rust e2e test functions + compiler fixes** - `1afc1f5c` (feat)

## Files Created/Modified

- `tests/e2e/datetime_utc_now.mpl` — utc_now + to_unix_ms smoke test; verifies ms > 1700000000000
- `tests/e2e/datetime_iso8601_roundtrip.mpl` — from_iso8601 / to_iso8601 round-trip; UTC, +05:30 offset, naive string error
- `tests/e2e/datetime_unix_ms.mpl` — from_unix_ms / to_unix_ms round-trip with known epoch
- `tests/e2e/datetime_unix_secs.mpl` — from_unix_secs / to_unix_secs round-trip with known epoch
- `tests/e2e/datetime_add_diff.mpl` — add/diff arithmetic using helper function for multi-statement case arm
- `tests/e2e/datetime_compare.mpl` — is_before / is_after with two-level Result unwrapping via helper functions
- `compiler/meshc/tests/e2e.rs` — added e2e_datetime_utc_now through e2e_datetime_compare
- `compiler/mesh-codegen/src/mir/types.rs` — DateTime -> MirType::Int in resolve_con
- `compiler/mesh-codegen/src/codegen/pattern.rs` — should_deref_boxed_payload covers Int/Float/Bool
- `compiler/mesh-codegen/src/mir/lower.rs` — datetime_is_before / datetime_is_after dispatch
- `compiler/mesh-typeck/src/builtins.rs` — Atom type for add/diff unit params; is_before/is_after
- `compiler/mesh-typeck/src/infer.rs` — same changes in stdlib_modules HashMap
- `compiler/mesh-rt/src/datetime.rs` — unit match arms without colon; std::time for utc_now
- `compiler/mesh-rt/Cargo.toml` — chrono without clock feature (no CoreFoundation)
- `Cargo.lock` — updated for chrono feature change

## Decisions Made

- **is_before / is_after naming**: `?` is the Mesh postfix try operator (not part of identifiers), and `after` is a reserved keyword (`AFTER_KW` for receive-timeout clauses). Renamed to `is_before`/`is_after` throughout all layers.
- **Atom typed unit params**: Changed `add`/`diff` unit parameter from `Ty::string()` to `Ty::Con(TyCon::new("Atom"))` to ensure only atom literals (`:day`, `:hour`, etc.) are accepted.
- **Float diff prints as "7" not "7.0"**: Rust's `f64::to_string()` emits `"7"` for whole numbers (no `.0` suffix). Test assertions match actual output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] DateTime not registered as MirType::Int in resolve_con**
- **Found during:** Task 2 (running first test)
- **Issue:** `"DateTime"` fell through to `MirType::Struct("DateTime")` in `resolve_con` — LLVM tried to allocate an opaque struct, producing "Cannot allocate unsized type" error
- **Fix:** Added `"DateTime" => MirType::Int` case in `compiler/mesh-codegen/src/mir/types.rs` after the existing `"PoolHandle" => MirType::Int` entry
- **Files modified:** `compiler/mesh-codegen/src/mir/types.rs`
- **Verification:** LLVM no longer errors on DateTime allocation; test proceeds
- **Committed in:** `1afc1f5c`

**2. [Rule 3 - Blocking] chrono `clock` feature requires CoreFoundation on macOS staticlib**
- **Found during:** Task 2 (linking phase)
- **Issue:** `chrono` with default features enables `clock` which depends on `iana-time-zone`, which requires `CoreFoundation.framework`. Static library builds on macOS cannot link framework dependencies this way — linker error: `_CFRelease` undefined symbol
- **Fix:** Changed `Cargo.toml` to `chrono = { version = "0.4", default-features = false, features = ["std", "alloc"] }`; rewrote `mesh_datetime_utc_now` to use `std::time::SystemTime::now()` instead of `Utc::now()`
- **Files modified:** `compiler/mesh-rt/Cargo.toml`, `compiler/mesh-rt/src/datetime.rs`
- **Verification:** Workspace builds and links cleanly; utc_now test passes
- **Committed in:** `1afc1f5c`

**3. [Rule 1 - Bug] Mesh case arms are single-expression only**
- **Found during:** Task 2 (parsing fixtures with multi-statement Ok arms)
- **Issue:** Fixtures written with multi-line `Ok(dt) -> let ms = ...\nprintln(ms)\nprintln(...)` fail to parse — Mesh case arm bodies must be a single expression
- **Fix:** Restructured all affected fixtures to use helper functions (e.g., `fn print_unix_ms`, `fn print_diff`, `fn from_later`) that perform multi-statement work
- **Files modified:** All 6 `.mpl` fixture files
- **Verification:** All fixtures parse and compile
- **Committed in:** `1afc1f5c`

**4. [Rule 1 - Bug] Boxed i64 Ok payload not dereferenced in pattern binding**
- **Found during:** Task 2 (DateTime.from_unix_ms returns wrong value after pattern match)
- **Issue:** `from_unix_ms`, `from_unix_secs`, `from_iso8601` box the i64 (`Box::into_raw(Box::new(ms)) as *mut u8`). Pattern binding `Ok(dt)` extracted a raw pointer rather than the i64 value — `should_deref_boxed_payload` only triggered for `MirType::Struct` and `MirType::SumType`, not `MirType::Int`
- **Fix:** Extended `should_deref_boxed_payload` in `pattern.rs` to also match `MirType::Int | MirType::Float | MirType::Bool`
- **Files modified:** `compiler/mesh-codegen/src/codegen/pattern.rs`
- **Verification:** `e2e_datetime_unix_ms` produces correct ms value in pattern-bound variable
- **Committed in:** `1afc1f5c`

**5. [Rule 1 - Bug] Atom literals pass "day" not ":day" to runtime**
- **Found during:** Task 2 (DateTime.add panics with unknown unit)
- **Issue:** `atom_text()` strips the leading `:` from atom literals — `:day` becomes `"day"`. Runtime `mesh_datetime_add` and `mesh_datetime_diff` matched `":day"`, `":hour"` etc. — these never matched, causing panic
- **Fix:** Updated `mesh_datetime_add` and `mesh_datetime_diff` in `datetime.rs` to match bare names: `"day"`, `"hour"`, `"minute"`, `"second"`, `"week"`, `"ms"`
- **Files modified:** `compiler/mesh-rt/src/datetime.rs`
- **Verification:** `e2e_datetime_add_diff` produces correct output `"7\n1\n"`
- **Committed in:** `1afc1f5c`

**6. [Rule 1 - Bug] Unit params typed as Ty::string() instead of Ty::Atom**
- **Found during:** Task 2 (typeck accepts plain strings for unit param — should be atoms)
- **Issue:** Both `builtins.rs` and `infer.rs` registered `datetime_add` and `datetime_diff` unit parameter as `Ty::string()`. Atom literals have type `Ty::Con(TyCon::new("Atom"))` — mismatch causes typeck to reject `:day` usage
- **Fix:** Changed unit param type to `Ty::Con(TyCon::new("Atom"))` in both `builtins.rs` and `infer.rs`
- **Files modified:** `compiler/mesh-typeck/src/builtins.rs`, `compiler/mesh-typeck/src/infer.rs`
- **Verification:** `:day`, `:hour` atoms type-check correctly; string literals rejected
- **Committed in:** `1afc1f5c`

**7. [Rule 1 - Bug] before?/after? names: ? is Mesh try operator and after is keyword**
- **Found during:** Task 2 (parse error on `DateTime.before?(earlier, later)`)
- **Issue 1:** `?` is Mesh's postfix try operator — `DateTime.before?(a, b)` parses as `TryExpr(FieldAccess(DateTime, "before"))` followed by `(a, b)` = syntax error
- **Issue 2:** `after` is a reserved keyword (`AFTER_KW`) used for receive-timeout syntax — `DateTime.after(...)` fails to parse
- **Fix:** Renamed to `is_before`/`is_after` throughout: builtins.rs, infer.rs, lower.rs, datetime.rs (C symbol names unchanged: `mesh_datetime_before`/`mesh_datetime_after`), all fixture files
- **Files modified:** `compiler/mesh-typeck/src/builtins.rs`, `compiler/mesh-typeck/src/infer.rs`, `compiler/mesh-codegen/src/mir/lower.rs`, `tests/e2e/datetime_compare.mpl`
- **Verification:** `e2e_datetime_compare` parses, compiles, and produces `"true\nfalse\nfalse\ntrue\n"`
- **Committed in:** `1afc1f5c`

**8. [Rule 1 - Bug] println(bool) type error — println only accepts String**
- **Found during:** Task 2 (initial datetime_utc_now.mpl had `println(positive)` with Bool)
- **Fix:** Changed to `println("${positive}")` using string interpolation
- **Files modified:** `tests/e2e/datetime_utc_now.mpl`
- **Verification:** `e2e_datetime_utc_now` produces `"true\n"`
- **Committed in:** `1afc1f5c`

**9. [Rule 1 - Bug] Wrong expected epoch in unix_ms test**
- **Found during:** Task 2 (assertion mismatch)
- **Issue:** Plan stated `1705312200000 ms = 2024-01-15T10:30:00.000Z` but actual conversion is `2024-01-15T09:50:00.000Z`
- **Fix:** Updated `e2e_datetime_unix_ms` assertion to `"1705312200000\n2024-01-15T09:50:00.000Z\n"`
- **Files modified:** `compiler/meshc/tests/e2e.rs`
- **Verification:** Test passes with correct expected value
- **Committed in:** `1afc1f5c`

**10. [Rule 1 - Bug] Float diff prints "7" not "7.0" — f64::to_string() behavior**
- **Found during:** Task 2 (assertion mismatch in add_diff test)
- **Issue:** Rust `7.0f64.to_string()` returns `"7"` (no `.0` suffix for whole numbers). Plan expected `"7.0\n1.0\n"`
- **Fix:** Updated `e2e_datetime_add_diff` assertion to `"7\n1\n"`
- **Files modified:** `compiler/meshc/tests/e2e.rs`
- **Verification:** Test passes
- **Committed in:** `1afc1f5c`

---

**Total deviations:** 10 auto-fixed (Rule 1 - Bug x9, Rule 3 - Blocking x1)
**Impact on plan:** All auto-fixes were necessary to make the DateTime type work through the compiler pipeline. The compiler had no prior test coverage for scalar opaque types returned via Result — these fixes establish patterns used by future stdlib types.

## Issues Encountered

- Nested case arms (`Ok(x) -> case ... do ... end`) fail to parse when the nested case is on a new line — workaround is helper functions. This is a known Mesh single-expression case arm constraint.
- `//` line comments are not valid Mesh syntax — initial fixtures had to have all comments removed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DateTime stdlib is fully implemented and tested (DTIME-01 through DTIME-08)
- Phase 137 (HTTP Client Improvements) can proceed
- Phase 138 (Testing Framework) can proceed
- Key patterns established: MirType::Int for scalar opaque types, boxed scalar deref in Ok patterns, Atom type for unit params

---
*Phase: 136-datetime-stdlib*
*Completed: 2026-02-28*

## Self-Check: PASSED

- FOUND: tests/e2e/datetime_utc_now.mpl
- FOUND: tests/e2e/datetime_compare.mpl
- FOUND: compiler/meshc/tests/e2e.rs
- FOUND: .planning/phases/136-datetime-stdlib/136-02-SUMMARY.md
- FOUND: commit d4d6fe77 (Task 1)
- FOUND: commit 1afc1f5c (Task 2)
