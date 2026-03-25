---
estimated_steps: 4
estimated_files: 6
skills_used:
  - test
  - postgresql-database-engineering
---

# T04: Close S03 with the live Postgres verifier and named keep-list gate

**Slice:** S03 — Hard read-side coverage and honest raw-tail collapse
**Milestone:** M033

## Description

Close S03 with a stable proof bundle and a named keep-list gate that future agents can rerun without reopening the research. Finish `compiler/meshc/tests/e2e_m033_s03.rs` so the rewritten read families prove their behavior directly against live Postgres-backed Mesher storage paths, then add `scripts/verify-m033-s03.sh` so the slice has one authoritative closeout command that also enforces the owned raw-boundary contract.

## Steps

1. Finish `compiler/meshc/tests/e2e_m033_s03.rs` so the assembled suite proves the rewritten helper families, filtered issue listing, project health summary, event neighbors, threshold evaluation, and the stable caller-visible row keys against live Postgres truth.
2. Add `scripts/verify-m033-s03.sh` to run the full `e2e_m033_s03` target, `cargo run -q -p meshc -- fmt --check mesher`, and `cargo run -q -p meshc -- build mesher`.
3. Add a Python keep-list sweep to the verifier that names the only allowed S03 leftovers, fails if an owned rewritten function regresses to `Repo.query_raw(...)`, and explicitly excludes the S04-owned partition/catalog raw sites from the S03 accounting.
4. Make failure output actionable and redacted: the verifier should name the exact failing proof or function block without printing secret-bearing inputs or full connection strings.

## Must-Haves

- [ ] `compiler/meshc/tests/e2e_m033_s03.rs` proves the final S03 storage behaviors directly on live Postgres-backed Mesher storage paths
- [ ] `scripts/verify-m033-s03.sh` runs the full slice proof bundle plus Mesher fmt/build checks and an S03 keep-list sweep
- [ ] The verifier names the allowed leftovers and excludes the S04-owned partition/catalog raw sites from S03’s raw-tail accounting

## Verification

- `cargo test -p meshc --test e2e_m033_s03 -- --nocapture`
- `bash scripts/verify-m033-s03.sh`

## Observability Impact

- Signals added/changed: full `e2e_m033_s03_*` failures and verifier keep-list errors become the canonical S03 diagnostic surfaces
- How a future agent inspects this: rerun `cargo test -p meshc --test e2e_m033_s03 -- --nocapture` or `bash scripts/verify-m033-s03.sh` and inspect the first named failure
- Failure state exposed: the exact drifting proof family or function block is named without requiring a fresh repo-wide raw SQL audit

## Inputs

- `compiler/meshc/tests/e2e_m033_s01.rs` — reusable Docker/Postgres helper and direct-row assertion patterns
- `compiler/meshc/tests/e2e_m033_s02.rs` — recent M033 proof-harness and storage-project setup pattern
- `compiler/meshc/tests/e2e_m033_s03.rs` — assembled S03 proof target from prior tasks
- `scripts/verify-m033-s02.sh` — verifier structure and keep-list sweep pattern to adapt
- `mesher/storage/queries.mpl` — final owned read-side boundary and leftover keep-sites

## Expected Output

- `compiler/meshc/tests/e2e_m033_s03.rs` — full live-Postgres S03 proof bundle
- `scripts/verify-m033-s03.sh` — stable slice verifier and named keep-list gate for S03
