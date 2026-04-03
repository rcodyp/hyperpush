---
id: T06
parent: S04
milestone: M049
provides:
  - Partial closeout contract updates for retiring the repo-root proof packages, plus exact resume notes for the remaining verifier reruns.
key_files:
  - README.md
  - website/docs/docs/distributed-proof/index.md
  - website/docs/docs/distributed/index.md
  - website/docs/docs/tooling/index.md
  - website/docs/docs/getting-started/clustered-example/index.md
  - scripts/tests/verify-m049-s04-onboarding-contract.test.mjs
  - scripts/verify-m047-s04.sh
  - scripts/verify-m047-s05.sh
  - compiler/meshc/tests/e2e_m045_s04.rs
  - compiler/meshc/tests/e2e_m045_s05.rs
  - compiler/meshc/tests/e2e_m046_s06.rs
  - compiler/meshc/tests/e2e_m047_s05.rs
key_decisions:
  - Keep the historical M045/M046 wrapper aliases on the existing M047 cutover chain for now, and update the stale contract readers around them instead of rerouting aliases mid-closeout.
patterns_established:
  - Closeout verifiers should fail closed on repo-root proof-package resurrection and read relocated clustered fixtures directly in contract tests.
observability_surfaces:
  - .tmp/m047-s04/verify
  - .tmp/m047-s05/verify
  - .tmp/m047-s05/verify/m047-s05-tooling.log
  - .tmp/m047-s05/verify/m047-s05-fixture-provenance.log
duration: partial-wrap-up
verification_result: partial
completed_at: ""
blocker_discovered: false
---

# T06: Update wrapper/closeout rails, delete the root proof-package dirs, and close the slice

**Updated the closeout/onboarding contracts for retired root proof packages, but the task is not complete because the retained Todo subrail and the slice-level historical rails still need final reruns.**

## What Happened

I updated the public closeout wording so the M047/S05 Todo rail is described as a retained subrail behind fixture-backed rails instead of as part of the public starter contract. I tightened the onboarding contract test so it now fails closed if `tiny-cluster/` or `cluster-proof/` reappear at repo root, and I added the same root-absence guard to `scripts/verify-m047-s04.sh`. I split `scripts/verify-m047-s05.sh` into named `m047-s05-pkg` and `m047-s05-tooling` contract phases so the S06 closeout rail can retain the Todo proof honestly, then updated the Rust-side contracts that were still reading deleted repo-root paths (`e2e_m045_s04.rs`, `e2e_m045_s05.rs`, `e2e_m046_s06.rs`). I also aligned the M047/S06 docs contract with the exact README/distributed-proof wording it expects.

The authoritative cutover rail is green from the current tree. The retained Todo subrail failed in the new tooling phase because `compiler/meshc/tests/e2e_m047_s05.rs::m047_s05_public_clustered_surfaces_use_source_first_names_and_todo_template` was still reading `repo_root()/tiny-cluster/work.mpl` and `repo_root()/cluster-proof/work.mpl`. I applied the obvious follow-up fix to point that test at `scripts/fixtures/clustered/.../work.mpl`, but I stopped before rerunning the Todo subrail because the context-budget warning fired.

## Verification

What passed from the current tree:
- `node --test scripts/tests/verify-m049-s04-onboarding-contract.test.mjs`
- `bash scripts/verify-m047-s04.sh`
- `cargo test -p meshc --test e2e_m045_s04 m045_s04_ -- --nocapture`
- `cargo test -p meshc --test e2e_m045_s05 m045_s05_ -- --nocapture`
- `cargo test -p meshc --test e2e_m046_s06 -- --nocapture`
- `cargo test -p meshc --test e2e_m047_s05 m047_s05_assembled_verifier_replays_cutover_and_todo_rails -- --nocapture`
- `cargo test -p meshc --test e2e_m047_s06 -- --nocapture`

What is still unresolved:
- `bash scripts/verify-m047-s05.sh` last failed in `m047-s05-tooling` before the final `e2e_m047_s05.rs` fixture-path fix landed.
- The slice-level rails `bash scripts/verify-m039-s01.sh` and `bash scripts/verify-m045-s02.sh` have not been rerun from the current tree in this unit.

## Verification Evidence

| # | Command | Exit Code | Verdict | Duration |
|---|---------|-----------|---------|----------|
| 1 | `node --test scripts/tests/verify-m049-s04-onboarding-contract.test.mjs` | 0 | ✅ pass | 609ms |
| 2 | `bash scripts/verify-m047-s04.sh` | 0 | ✅ pass | 150800ms |
| 3 | `bash scripts/verify-m047-s05.sh` | 1 | ❌ fail | 127100ms |
| 4 | `cargo test -p meshc --test e2e_m045_s04 m045_s04_ -- --nocapture` | 0 | ✅ pass | 32800ms |
| 5 | `cargo test -p meshc --test e2e_m045_s05 m045_s05_ -- --nocapture` | 0 | ✅ pass | 28400ms |
| 6 | `cargo test -p meshc --test e2e_m046_s06 -- --nocapture` | 0 | ✅ pass | 24400ms |
| 7 | `cargo test -p meshc --test e2e_m047_s05 m047_s05_assembled_verifier_replays_cutover_and_todo_rails -- --nocapture` | 0 | ✅ pass | 19200ms |
| 8 | `cargo test -p meshc --test e2e_m047_s06 -- --nocapture` | 0 | ✅ pass | 120000ms |

## Diagnostics

Resume from `.tmp/m047-s05/verify/m047-s05-tooling.log`. The last concrete failure was:
- `compiler/meshc/tests/e2e_m047_s05.rs::m047_s05_public_clustered_surfaces_use_source_first_names_and_todo_template`
- stale reads from `repo_root().join("tiny-cluster/work.mpl")` and `repo_root().join("cluster-proof/work.mpl")`
- those paths were updated at the end of this unit to `scripts/fixtures/clustered/tiny-cluster/work.mpl` and `scripts/fixtures/clustered/cluster-proof/work.mpl`, but **not rerun yet**.

After that rerun, the next truthful sequence is:
1. rerun `cargo test -p meshc --test e2e_m047_s05 m047_s05_public_clustered_surfaces_use_source_first_names_and_todo_template -- --nocapture`
2. rerun `bash scripts/verify-m047-s05.sh`
3. rerun the slice-level rails `bash scripts/verify-m039-s01.sh` and `bash scripts/verify-m045-s02.sh`
4. only if all of those pass, call `gsd_complete_task`

## Deviations

I updated several older Rust contract tests that were not listed in the task plan inputs because the repo-root proof-package deletion had already made them stale or incorrect (`e2e_m045_s04.rs`, `e2e_m045_s05.rs`, `e2e_m046_s06.rs`, and the tooling-path portion of `e2e_m047_s05.rs`).

## Known Issues

- `bash scripts/verify-m047-s05.sh` needs a fresh rerun from the current tree after the final `e2e_m047_s05.rs` fixture-path edit.
- `bash scripts/verify-m039-s01.sh` and `bash scripts/verify-m045-s02.sh` still need their final slice-level reruns from the current tree.
- The task is **not** complete yet, so I intentionally did **not** mark the task done or toggle any plan checkbox.

## Files Created/Modified

- `README.md` — aligned the SQLite/Postgres public clustered wording with the stricter M047/S06 docs contract.
- `website/docs/docs/distributed-proof/index.md` — updated the public clustered proof split wording to the exact two-public-layers-plus-local-starter contract.
- `website/docs/docs/distributed/index.md` — updated the retained Todo subrail wording to the fixture-backed closeout contract.
- `website/docs/docs/tooling/index.md` — updated the retained Todo subrail wording to the fixture-backed closeout contract.
- `website/docs/docs/getting-started/clustered-example/index.md` — updated the retained Todo subrail wording to the fixture-backed closeout contract.
- `scripts/tests/verify-m049-s04-onboarding-contract.test.mjs` — added repo-root proof-package absence checks plus a negative test for reintroduced root dirs.
- `scripts/verify-m047-s04.sh` — added fail-closed guards for reintroduced repo-root `tiny-cluster/` and `cluster-proof/` directories.
- `scripts/verify-m047-s05.sh` — added named `m047-s05-pkg` / `m047-s05-tooling` contract phases and a final pass-marker check.
- `compiler/meshc/tests/e2e_m045_s04.rs` — repointed cutover dependency assertions to fixture-backed `meshc build/test` commands.
- `compiler/meshc/tests/e2e_m045_s05.rs` — repointed cutover dependency assertions to fixture-backed `meshc build/test` commands.
- `compiler/meshc/tests/e2e_m046_s06.rs` — repointed stale root README readers to the relocated fixture runbooks and relaxed pre-migration omissions to match current docs.
- `compiler/meshc/tests/e2e_m047_s05.rs` — updated the assembled verifier contract and repointed the lingering work-file reads to the relocated clustered fixtures.
