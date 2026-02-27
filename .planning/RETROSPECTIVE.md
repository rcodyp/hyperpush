# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

---

## Milestone: v12.0 — Language Ergonomics & Open Source Readiness

**Shipped:** 2026-02-27
**Phases:** 10 (116-125) | **Plans:** 24 | **Duration:** 3 days (2026-02-25 → 2026-02-27)

### What Was Built
- Slot pipe operator `|N>` with full HM type inference — pipes expressions to any argument position with SlotPipeOutOfRange arity errors
- String interpolation `#{expr}` and `${expr}` (both syntaxes) plus heredoc strings `"""..."""` with trimIndent for multiline JSON construction
- Complete regex support: `~r/pattern/flags` literals, `Regex.compile`, `Regex.is_match`, `Regex.captures`, `Regex.replace`, `Regex.split`
- Typed env var stdlib: `Env.get("KEY", "default")` and `Env.get_int("PORT", 8080)` — eliminates manual Option unwrapping (parse_port pattern obsoleted)
- Mesh agent skill with 10 sub-skills (syntax, types, actors, supervisors, collections, strings/regex/env, http, database, pattern-matching, traits) — progressive disclosure for AI-assisted Mesh development
- Repository reorganization: clean compiler/mesher/website/tools/ structure for open source; all CI/CD updated
- Performance benchmarks: Mesh 29,108 req/s isolated (within 4% of Go, 2.3× faster than Elixir); published in benchmarks/ with methodology
- Developer seed migration: `meshc migrate up` now creates default org/project/API key for immediate testing

### What Worked
- Phases 116-123 shipped in a single 2-day burst (2026-02-25 → 2026-02-26) at quality profile — extremely high velocity for 8 language features
- `Env.get_int` was already partially implemented from an earlier phase; the dogfooding phase (quick task 8) caught and eliminated the now-redundant `parse_port` helper
- Benchmark methodology (isolated servers per VM via Fly.io, hey for load gen) produced clean results without CPU sharing artifacts — the +47% Mesh improvement from isolated vs co-located validated the approach
- Phase 121 (Mesh agent skill) executing with 4-plan parallelism (Wave 1 root + Wave 2 parallel sub-skills) worked cleanly — independent sub-skills had no merge conflicts
- Phases 124 and 125 were added post-roadmap to address developer experience gaps found during validation — the ability to insert quick-turn phases kept momentum

### What Was Inefficient
- Fly.io benchmark infrastructure required extensive Dockerfile debugging (LLVM static linking, Elixir OTP install, IPv6 networking, socat elimination) — ~40 fix commits for Phase 123 alone; a local benchmark approach would have been faster
- Phase 119 (Regex) required 3 plans because the Regex.match naming conflict with Mesh keyword `match` wasn't caught until test execution; a quick check of reserved words before designing the API would have avoided the rename
- The v12.0 roadmap header said "Phases 116-123" but phases 124-125 were added after; the milestone header became stale and required correction during archival

### Patterns Established
- **Quick task as dogfooding validator**: After a language feature ships, a quick task (`/gsd:quick`) to apply it to real code catches redundant patterns (parse_port → Env.get_int) and validates ergonomics without a full phase
- **Keyword collision check**: Before naming new stdlib functions, verify the name isn't a Mesh keyword (`match`, `case`, `fn`, `do`, `end`, etc.) — prevents Phase-3 renames
- **Isolated benchmark methodology**: Run one server per VM to eliminate CPU sharing artifacts; co-located benchmarks systematically understate Mesh's performance

### Key Lessons
1. Check Mesh reserved keywords before naming stdlib functions — `Regex.is_match` instead of `Regex.match` was a late rename that could have been avoided
2. Quick tasks after feature phases catch real-world ergonomics issues — `Env.get_int` replaced the manual parse_port pattern only after dogfooding found it
3. Isolated benchmark methodology gives significantly higher (and more honest) results than co-located — co-located Mesh underperformed by 47% vs isolated
4. Fly.io infrastructure setup is slow for benchmarks; prefer local benchmarks or well-documented cloud infrastructure templates for future perf phases

### Cost Observations
- Model mix: quality profile throughout (opus for planning and execution)
- Duration: 3 calendar days from start to milestone complete
- Notable: extremely high velocity — 10 phases, 24 plans, 8 language features in 3 days with no correctness regressions

---

## Milestone: v11.0 — Query Builder

**Shipped:** 2026-02-25
**Phases:** 11 (including 109.1) | **Plans:** 22 | **Sessions:** ~8 days

### What Was Built
- Advanced ORM query builder: NOT IN, BETWEEN, ILIKE, OR grouped conditions, raw SQL fragments with $N renumbering across all query positions (WHERE/SELECT/ORDER BY/GROUP BY)
- JOIN support (inner, left, aliased, multi-table) and full aggregation suite (count/sum/avg/min/max, group_by, having) — all with runtime SQLite E2E verification
- Upsert (INSERT ON CONFLICT DO UPDATE), RETURNING clause, subquery WHERE IN, plus critical compiler fixes: type checker arity bug and service loop type dispatch for Bool/Float/Struct params
- 49+ Mesher raw SQL queries rewritten to ORM across all 7 domains; 18 intentional ORM boundaries documented with rationale; zero unaccounted raw SQL
- Full E2E verification: Mesher compiled zero errors, all 8 HTTP API domains return 2xx, WebSocket 101, EventProcessor SIGSEGV resolved

### What Worked
- Decimal phase insertion (109.1) cleanly handled two blocking bugs mid-milestone without renumbering subsequent phases — the pattern is unambiguous and low-friction
- Incremental domain-by-domain Mesher rewrite (auth → issues → search/dashboard/alerts → retention) validated the ORM pattern before tackling more complex domains
- Explicit ORM boundary documentation (18 sites with rationale comments) was faster than trying to force-fit every query — honest scope beats over-engineering
- Phase 115 tracking-corrections pattern: a dedicated cleanup phase after verification to formally close audit gaps and canonicalize API style worked well
- Audit-then-complete workflow (two audit runs before archiving) caught 13 tracking gaps that would have silently entered the milestone record

### What Was Inefficient
- Phase 106 requirement tracking was incomplete at execution time — WHERE-01..06 and FRAG-01..04 were not marked in REQUIREMENTS.md during execution, requiring Phase 115 to close the gap retroactively
- The initial audit (gaps_found) required a second audit run after corrections; better to mark requirements during execution so first audit passes
- ROADMAP plan-level checkboxes accumulated cosmetic inconsistencies (some `[ ]` instead of `[x]` for completed plans) — minor but creates noise in audits
- Phase 109 API style (positional args) diverged from the roadmap description (keyword-option style) without an in-phase note; caught in audit, resolved in Phase 115

### Patterns Established
- **ORM boundary documentation pattern**: when a query cannot be expressed via ORM, add a comment explaining the specific SQL feature that prevents ORM use (arithmetic SET expressions, server-side JSONB, nested subqueries, DDL) — creates a clear inventory for future ORM extensions
- **Decimal phase insertion**: `109.1` for urgent mid-milestone bug fixes preserves ordering and avoids renumbering; INSERTED marker in roadmap
- **Three-phase verification sequence**: compile-zero-errors → startup/migration → HTTP+WS smoke test; each is a distinct plan
- **Requirement tracking discipline**: mark `requirements-completed` in SUMMARY frontmatter at execution time, not retroactively — prevents audit gaps

### Key Lessons
1. Mark requirements complete during execution in SUMMARY frontmatter — retroactive tracking (Phase 115) costs an extra phase
2. When an API style diverges from the roadmap spec during implementation, add an inline acceptance note to the roadmap immediately (not at audit time)
3. ORM boundary documentation is a feature, not a gap — explicitly catalogued raw SQL sites are better than hidden ones
4. Runtime SQLite E2E tests are high-value for query builder features: they catch SQL generation bugs that unit tests miss and create a regression baseline

### Cost Observations
- Model mix: quality profile throughout (primarily opus)
- Sessions: ~8 working days
- Notable: plan_check + verifier gates added confidence but extended execution time per phase; the trade-off was worthwhile for a large rewrite milestone

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 10 | 55 | Initial project — full compiler from scratch |
| v8.0 | 6 | 11 | Developer tooling — LSP, install scripts, VS Code |
| v9.0 | 9 | 38 | First large Mesh application (Mesher) — multi-domain |
| v10.0 | 8 | 25 | ORM library — schema DSL, repo pattern, migrations |
| v11.0 | 11 | 22 | ORM query builder + full application rewrite |
| v12.0 | 10 | 24 | Language ergonomics + open source readiness + benchmarks |

### Top Lessons (Cross-Milestone)

1. Runtime E2E tests (SQLite for DB, live HTTP smoke for services) are more valuable than static analysis for verifying query/protocol features
2. Incremental domain-by-domain rewrites (auth → issues → search → ...) are more reliable than big-bang rewrites — each domain validates the pattern before the next
3. Explicit audit + gap-closure phases (115 pattern) are worth the overhead for large milestones with many requirements
