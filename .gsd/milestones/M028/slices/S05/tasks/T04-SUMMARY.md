---
id: T04
parent: S05
milestone: M028
provides:
  - Added durable recovery-result scaffolding in storage and left an exact resume path for the remaining worker-state/compiler mismatch that still blocks the whole-process restart proof.
key_files:
  - reference-backend/storage/jobs.mpl
  - reference-backend/jobs/worker.mpl
  - .gsd/milestones/M028/slices/S05/S05-PLAN.md
  - .gsd/milestones/M028/slices/S05/tasks/T04-SUMMARY.md
key_decisions:
  - Fix the durable storage/recovery export gap first instead of inventing the T04 whole-process proof on top of a still-failing T03 build.
patterns_established:
  - The current Mesh compiler path in this area is sensitive to how worker-state service updates are expressed; the latest unverified attempt converts mutating state APIs from `cast` to synchronous `call ... :: Int` methods because repeated helper-level update calls kept failing with `E0012 non-exhaustive match on Int`.
observability_surfaces:
  - compiler/meshc/tests/e2e_reference_backend.rs
  - reference-backend/storage/jobs.mpl
  - reference-backend/jobs/worker.mpl
  - .gsd/milestones/M028/slices/S05/S05-PLAN.md
duration: 1h
verification_result: partial
completed_at: 2026-03-23 19:59:12 EDT
blocker_discovered: false
---

# T04: Prove whole-process recovery and document the supervision contract

**Added durable job-recovery storage scaffolding and isolated a remaining worker-state compiler mismatch that blocked the whole-process restart proof.**

## What Happened

I read the T04 contract, the slice plan, the prior T01–T03 summaries, and the current backend surfaces before changing anything. Local reality was still behind the slice goal: `compiler/meshc/tests/e2e_reference_backend.rs` already contained the T03 worker-crash/health proofs, but `reference-backend/storage/jobs.mpl` on disk still did **not** export `reclaim_processing_jobs(...)`, `reference-backend/jobs/worker.mpl` still imported that missing symbol, and the T04 process-restart proof and README section were still absent.

I reproduced the focused failing backend proof first with the existing ignored T03 command. That confirmed the immediate blockers were still compile-time, not runtime or database setup: the worker imported a missing `reclaim_processing_jobs` export, the worker helper path still produced `expected Int, found ()`, and the crash injector path was still brittle.

I fixed the durable storage gap in `reference-backend/storage/jobs.mpl` by adding:

- a public `RecoveryResult` struct,
- a raw SQL `reclaim_processing_jobs_sql()` path that requeues `processing` rows back to `pending`, sets `last_error` to the recovery hint, clears `processed_at`, and updates `updated_at`, and
- a public `reclaim_processing_jobs(pool, error_message)` export that returns the recovery count plus the last recovered job id.

I then iterated repeatedly on `reference-backend/jobs/worker.mpl` to align the worker-state bookkeeping with that new storage contract. The import/export mismatch was removed, but the worker still failed at build time on the state-update path. The failure evolved from the original missing-export / type-mismatch pair into a more specific `E0012 non-exhaustive match on Int` around worker-state update calls plus an LLVM verifier error involving `job_worker_loop`.

Before the context-budget warning forced wrap-up, I made one last unverified change: I converted the mutating `JobWorkerState` APIs (`NoteBoot`, `NoteRecovery`, `NoteTick`, `NoteIdle`, `NoteClaimed`, `NoteProcessed`, `NoteFailed`, `NoteCrashSoon`) from `cast` methods to synchronous `call ... :: Int` methods that return `(next_state, 0)`. I did **not** get to rerun the build after that last step.

Because the backend still did not build cleanly, I did **not** start the actual T04 work items that depend on a healthy T03 base:

- no `e2e_reference_backend_process_restart_recovers_inflight_job` proof was added,
- `reference-backend/README.md` was not updated with the supervision/recovery section, and
- the T04 checkbox remains unchecked in the slice plan.

## Verification

I repeatedly reran the smallest real backend proof instead of speculating:

- `set -a && source ./.env && set +a && cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_crash_recovers_job -- --ignored --nocapture`

That command consistently failed before runtime execution because `meshc build reference-backend` still failed. The failures progressed as follows:

1. missing `Storage.Jobs.reclaim_processing_jobs` export,
2. worker helper mismatch around `JobWorkerState.note_processed(...)` (`expected Int, found ()`),
3. repeated `E0012 non-exhaustive match on Int` around worker-state updates, plus an LLVM verifier error on `job_worker_loop`.

The last on-disk change — converting the mutating worker-state APIs from `cast` to `call ... :: Int` — was not rerun after the context-budget warning, so there is no passing or failing proof yet for that final variant.

## Verification Evidence

| # | Command | Exit Code | Verdict | Duration |
|---|---------|-----------|---------|----------|
| 1 | `set -a && source ./.env && set +a && cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_crash_recovers_job -- --ignored --nocapture` | 101 | ❌ fail | 5.05s |
| 2 | `set -a && source ./.env && set +a && cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_crash_recovers_job -- --ignored --nocapture` | 101 | ❌ fail | 5.13s |
| 3 | `set -a && source ./.env && set +a && cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_crash_recovers_job -- --ignored --nocapture` | 101 | ❌ fail | 5.26s |
| 4 | `set -a && source ./.env && set +a && cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_crash_recovers_job -- --ignored --nocapture` | 101 | ❌ fail | 4.86s |
| 5 | `set -a && source ./.env && set +a && cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_crash_recovers_job -- --ignored --nocapture` | 101 | ❌ fail | 5.12s |
| 6 | `set -a && source ./.env && set +a && cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_crash_recovers_job -- --ignored --nocapture` | 101 | ❌ fail | 5.34s |

## Diagnostics

Resume from the same focused proof command first:

- `set -a && source ./.env && set +a && cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_crash_recovers_job -- --ignored --nocapture`

Resume order:

1. Re-run that exact command against the current on-disk state.
2. If the new `call ... :: Int` worker-state change builds, continue immediately to:
   - `cargo test -p meshc --test e2e_reference_backend e2e_reference_backend_worker_restart_is_visible_in_health -- --ignored --nocapture`
3. Only after both T03 proofs pass, implement the actual T04 contract:
   - add `e2e_reference_backend_process_restart_recovers_inflight_job` to `compiler/meshc/tests/e2e_reference_backend.rs`, and
   - add the `Supervision and recovery` section plus exact ignored commands / `/health` field guidance to `reference-backend/README.md`.

The key remaining code path is `reference-backend/jobs/worker.mpl`. If the build still fails, focus on the worker-state update calls first; the storage export gap in `reference-backend/storage/jobs.mpl` is already fixed on disk.

## Deviations

I did not reach the planned T04 harness/README work because the checked-out backend still failed at the prerequisite T03 build/proof layer. I made no README changes and no T04 process-restart test changes in this unit.

## Known Issues

- `reference-backend` still does not build cleanly under the focused ignored backend proof as of the last rerun.
- The final worker-state service conversion from `cast` to `call ... :: Int` is on disk but unverified.
- `compiler/meshc/tests/e2e_reference_backend.rs` still lacks the planned T04 whole-process restart proof.
- `reference-backend/README.md` still lacks the planned supervision/recovery documentation section.

## Files Created/Modified

- `reference-backend/storage/jobs.mpl` — added `RecoveryResult` and the exported `reclaim_processing_jobs(...)` durable requeue helper.
- `reference-backend/jobs/worker.mpl` — iterated on worker recovery bookkeeping and, in the final unverified state, converted the mutating worker-state APIs from `cast` to synchronous `call ... :: Int` methods.
- `.gsd/milestones/M028/slices/S05/S05-PLAN.md` — left a T04 resume note without falsely marking the task complete.
- `.gsd/milestones/M028/slices/S05/tasks/T04-SUMMARY.md` — durable partial handoff for the next unit.
