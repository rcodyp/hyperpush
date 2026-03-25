---
estimated_steps: 4
estimated_files: 7
skills_used:
  - postgresql-database-engineering
  - test
---

# T03: Retire the hard whole-query raw read families with honest decomposition

**Slice:** S03 — Hard read-side coverage and honest raw-tail collapse
**Milestone:** M033

## Description

Retire the hardest S03-owned read-side whole-query raw SQL without pretending the ORM is more general than it really is. This task should rewrite the recurring whole-query raw families by composing smaller builder-backed reads and combining the results in Mesh, not by adding a fake derived-table or scalar-subquery abstraction. If a function still remains dishonest after that pass, keep it explicit and named instead of hiding it.

## Steps

1. Extend `compiler/meshc/tests/e2e_m033_s03.rs` with named `e2e_m033_s03_hard_reads_*` coverage for filtered issue listing, project health summary, event neighbors, and threshold evaluation.
2. Replace `list_issues_filtered` with honest conditional query building: append the optional status/level/assigned filters only when present, preserve the current row shape and descending keyset semantics, and keep any unavoidable cursor-specific raw fragment explicit instead of rebuilding the old whole-query string.
3. Replace `project_health_summary`, `get_event_neighbors`, and `evaluate_threshold_rule` with two or three smaller builder-backed reads plus Mesh-side combination, preserving their exact output keys (`unresolved_count`, `events_24h`, `new_today`, `next_id`, `prev_id`, `should_fire`).
4. Reassess the final S03 keep-list after the rewrites and keep only the short named leftovers that are still genuinely dishonest (`extract_event_fields`, `check_volume_spikes`, `check_sample_rate` unless execution proves otherwise); do not widen the neutral core or smuggle PG-only behavior outside `Pg.*`.

## Must-Haves

- [ ] `list_issues_filtered`, `project_health_summary`, `get_event_neighbors`, and `evaluate_threshold_rule` no longer depend on `Repo.query_raw(...)` whole-query strings
- [ ] `compiler/meshc/tests/e2e_m033_s03.rs` contains named `e2e_m033_s03_hard_reads_*` proofs for the T03 families
- [ ] The remaining keep-list is short, explicit, and justified rather than being hidden behind a misleading neutral abstraction

## Verification

- `cargo test -p meshc --test e2e_m033_s03 hard_reads -- --nocapture`
- `cargo run -q -p meshc -- build mesher`

## Observability Impact

- Signals added/changed: named `e2e_m033_s03_hard_reads_*` failures and explicit leftover comments distinguish decomposition bugs from intentionally retained keep-sites
- How a future agent inspects this: rerun the `hard_reads` filter and inspect the hard-family helper blocks plus the leftover comments in `mesher/storage/queries.mpl`
- Failure state exposed: cursor/order bugs, count mismatches, and keep-list drift become explicit at the storage boundary

## Inputs

- `compiler/meshc/tests/e2e_m033_s03.rs` — partial S03 proof harness from T01/T02
- `mesher/storage/queries.mpl` — remaining S03-owned whole-query raw families
- `mesher/api/search.mpl` — filtered issue listing contract
- `mesher/api/dashboard.mpl` — health-summary contract
- `mesher/api/detail.mpl` — event-neighbor contract
- `mesher/ingestion/pipeline.mpl` — threshold-evaluation caller contract
- `mesher/ingestion/routes.mpl` — sample-rate caller and remaining read-boundary context

## Expected Output

- `compiler/meshc/tests/e2e_m033_s03.rs` — named `hard_reads` proofs for filtered issues, health summary, neighbors, and threshold evaluation
- `mesher/storage/queries.mpl` — hard read-side raw families rewritten or explicitly retained in the short named keep-list
