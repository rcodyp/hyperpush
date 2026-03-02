---
phase: 138-testing-framework
plan: "03"
subsystem: testing-framework
tags: [testing, codegen, runtime, preprocessor, dsl]
dependency_graph:
  requires: [138-01, 138-02]
  provides: [test-harness-generation, test-dsl-lowering, assert-raises, mock-actor]
  affects: [mesh-codegen, mesh-typeck, mesh-rt, meshc]
tech_stack:
  added:
    - test DSL preprocessor (tokenizer + block extractor + code generator in test_runner.rs)
    - is_test_mode detection in MIR lowerer
    - IN_ASSERT_RAISES / ASSERT_RAISES_TRIGGERED thread-locals for safe assert_raises
    - process::exit(0/1) in mesh_test_summary for CI-friendly exit codes
  patterns:
    - source preprocessing: .test.mpl → valid Mesh with fn __test_body_N() + fn main()
    - flag-based exception signaling: avoid panic through extern "C" closures
    - fail-count snapshot: run_body detects test failure by diffing FAIL_COUNT
key_files:
  created:
    - compiler/meshc/src/test_runner.rs (complete rewrite with preprocessor)
    - tests/e2e/test_basic.test.mpl
    - tests/e2e/test_describe.test.mpl
    - tests/e2e/test_describe_groups.test.mpl
    - tests/e2e/test_assert_raises.test.mpl
    - tests/e2e/test_mock_actor.test.mpl
  modified:
    - compiler/mesh-rt/src/test.rs
    - compiler/mesh-codegen/src/mir/lower.rs
    - compiler/mesh-codegen/src/codegen/intrinsics.rs
    - compiler/mesh-typeck/src/builtins.rs
    - compiler/mesh-typeck/src/infer.rs
decisions:
  - "Source preprocessor approach: transform .test.mpl → valid Mesh before compilation rather than MIR-level harness generation. Simpler than CST walking since top-level test() calls aren't recognized Items."
  - "Flag-based assert_raises: avoid panic!() through extern C closures (Rust 1.73+ hard abort). Use IN_ASSERT_RAISES thread-local to intercept failures silently inside assert_raises closures."
  - "Fail-count snapshot in run_body: record FAIL_COUNT before/after body call instead of catch_unwind. Allows test bodies to run to completion without early-exit (acceptable trade-off)."
  - "process::exit in mesh_test_summary: compiled test binary exits 1 on failure so outer meshc test runner can detect via exit code."
metrics:
  duration_minutes: 210
  tasks_completed: 5
  files_modified: 11
  files_created: 6
  completed_date: "2026-02-28T22:12:54Z"
---

# Phase 138 Plan 03: Test Harness Generation Summary

**One-liner:** Source preprocessing DSL transforms `.test.mpl` to valid Mesh with `fn __test_body_N()` + `fn main()` harness, with flag-based `assert_raises` to avoid panic through `extern "C"` closures.

## What Was Built

### Source Preprocessor (`test_runner.rs`)

Complete rewrite from a "copy file" approach to a proper source preprocessor:

1. **Mini-tokenizer** (`TToken` enum): handles keywords, string literals, `do`/`end`, comments
2. **Block extractor** (`extract_test_blocks`): parses `test("label") do body end` and nested `describe/setup/teardown` blocks
3. **Code generator** (`preprocess_test_source`): emits:
   - One `fn __test_body_N()` per test block (including setup/teardown wrappers)
   - `fn main()` harness with `test_begin`/`test_run_body`/`test_summary` calls
   - Describe groups prefix test labels as `"Group > test name"`

### MIR Lowerer (`lower.rs`)

- **`is_test_mode: bool`** field on `Lowerer` struct
- **Test mode detection**: pre-scan pass in `lower_source_file` looks for `fn __test_body_*` functions
- **DSL lowering** in `lower_call_expr`: intercepts `assert`/`assert_eq`/`assert_ne`/`assert_raises` in test mode and expands to `mesh_test_assert_*` calls with source text metadata
- **`coerce_to_string`** helper: Int/Float/Bool → String conversion for assert_eq/assert_ne
- **New `known_functions`** entries: `mesh_test_run_body`, `mesh_test_mock_actor`, `mesh_test_pass_count`, `mesh_test_fail_count`
- **New `map_builtin_name`** entries: `test_run_body`, `test_mock_actor`, `test_pass_count`, `test_fail_count`

### LLVM Intrinsics (`intrinsics.rs`)

Added four new external declarations:
- `mesh_test_run_body(fn_ptr: ptr, env_ptr: ptr) -> void`
- `mesh_test_mock_actor(fn_ptr: ptr, env_ptr: ptr) -> i64`
- `mesh_test_pass_count() -> i64`
- `mesh_test_fail_count() -> i64`

### Type Checker (`builtins.rs` + `infer.rs`)

- **`builtins.rs`**: registered all test DSL names as global builtins: `assert`, `assert_eq`, `assert_ne`, `assert_raises`, `test`, `describe`, `setup`, `teardown`, `test_run_body`, `test_begin`, `test_summary`, `test_cleanup_actors`, `test_pass_count`, `test_fail_count`
- **`infer.rs`**: added `Test.mock_actor(fn(String) -> String) -> Pid` to the `Test` stdlib module

### Runtime (`test.rs`)

Key changes:

1. **Flag-based `assert_raises`**: Added `IN_ASSERT_RAISES` and `ASSERT_RAISES_TRIGGERED` thread-locals. When `mesh_test_assert_raises` sets `IN_ASSERT_RAISES`, subsequent `mesh_test_assert` failures set `ASSERT_RAISES_TRIGGERED` instead of recording a failure. After the closure returns, the flag is checked.

2. **`mesh_test_run_body` via fail-count snapshot**: Instead of `catch_unwind` (which panics through `extern "C"`, causing abort in Rust 1.73+), records `FAIL_COUNT` before/after body call.

3. **`mesh_test_summary` with `process::exit`**: Exits with code 0 (all pass) or 1 (any fail), enabling CI detection.

4. **`mesh_test_run_body`, `mesh_test_mock_actor`, `mesh_test_pass_count`, `mesh_test_fail_count`** added as `#[no_mangle] extern "C"` functions.

### E2E Fixture Files

| File | Tests | Coverage |
|------|-------|----------|
| `test_basic.test.mpl` | 5 | arithmetic, booleans, strings, assert_raises |
| `test_describe.test.mpl` | 4 | describe groups (original format) |
| `test_describe_groups.test.mpl` | 6 | describe groups with > separator, top-level tests |
| `test_assert_raises.test.mpl` | 1 | standalone assert_raises test |
| `test_mock_actor.test.mpl` | 1 | Test.mock_actor spawning |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stash drop lost all session changes**
- **Found during:** Task continuation after context reset
- **Issue:** `git stash drop` removed all uncommitted changes from the session (test.rs improvements, test_runner.rs preprocessor, all fixture files)
- **Fix:** Re-implemented all changes from scratch based on conversation context
- **Files modified:** All Plan 03 files

**2. [Rule 1 - Bug] `panic!()` in extern "C" assert functions**
- **Found during:** assert_raises test execution
- **Issue:** `mesh_test_assert` used `panic!()` which can't unwind through `extern "C"` Mesh closures (Rust 1.73+ hard abort: "panic in a function that cannot unwind")
- **Fix:** Changed to flag-based mechanism (`IN_ASSERT_RAISES` / `ASSERT_RAISES_TRIGGERED` thread-locals); removed all `panic!()` from assert functions
- **Files modified:** `compiler/mesh-rt/src/test.rs`
- **Commit:** 1a1d4d56

**3. [Rule 2 - Missing] Process exit code**
- **Found during:** Test verifying failure detection
- **Issue:** `mesh_test_summary` didn't call `process::exit(1)` on failures; outer runner saw exit 0 even when tests failed
- **Fix:** Added `std::process::exit(0/1)` to `mesh_test_summary`
- **Files modified:** `compiler/mesh-rt/src/test.rs`
- **Commit:** 1a1d4d56

**4. [Rule 2 - Missing] `mesh_test_run_body/mock_actor/pass_count/fail_count` in intrinsics.rs**
- **Found during:** test_basic.test.mpl compile error "Undefined variable 'mesh_test_run_body'"
- **Issue:** Plan 02 added `mesh_test_begin/assert/summary/cleanup` LLVM declarations but not the four new functions added in Plan 03
- **Fix:** Added LLVM external declarations to intrinsics.rs
- **Files modified:** `compiler/mesh-codegen/src/codegen/intrinsics.rs`
- **Commit:** 1a1d4d56

**5. [Rule 3 - Blocking] `do/end` depth tracking bug with `fn`**
- **Found during:** preprocessor testing with multi-line closures
- **Issue:** Treating `fn` as a depth-incrementing keyword caused `fn() do body end` to count as 2 depth levels, leaving the block body parser in wrong state
- **Fix:** Only `do`/`if`/`while`/`case`/`for`/`receive` increment depth; `fn` does not
- **Files modified:** `compiler/meshc/src/test_runner.rs`
- **Commit:** 1a1d4d56

**6. [Rule 1 - Bug] `assert_raises` fixture used wrong label format**
- **Found during:** describe group output format check
- **Issue:** Test output showed "Group test name" instead of "Group > test name"
- **Fix:** Changed format string from `"{} {}"` to `"{} > {}"`
- **Files modified:** `compiler/meshc/src/test_runner.rs`
- **Commit:** 1a1d4d56

### Deferred Items

**`assert_receive`**: Not implemented. Requires pattern matching on received messages from the test process mailbox. This requires `mesh_actor_receive` integration with the test harness, which is a separate concern. The `test_mock_actor.test.mpl` fixture uses a simplified version that just spawns the mock and verifies the Pid was returned.

## Verification Results

## Self-Check: PASSED

All key files exist and commit 1a1d4d56 is present.

```
meshc test tests/e2e/test_basic.test.mpl
  ✓ arithmetic is correct
  ✓ boolean logic works
  ✓ string operations
  ✓ assert_raises catches failing assertion
  ✓ assert_raises catches nested failure
5 passed in 0.00s

meshc test tests/e2e/test_describe_groups.test.mpl
  ✓ Math operations > addition
  ✓ Math operations > multiplication
  ✓ Math operations > subtraction
  ✓ String module > length
  ✓ String module > contains
  ✓ top-level test also runs
6 passed in 0.00s

meshc test tests/e2e/test_assert_raises.test.mpl
  ✓ assert_raises catches panics
1 passed in 0.00s

meshc test tests/e2e/test_mock_actor.test.mpl
  ✓ Test.mock_actor spawns an actor
1 passed in 0.00s
```
