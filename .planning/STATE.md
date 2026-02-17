# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-17)

**Core value:** Expressive, readable concurrency -- writing concurrent programs should feel as natural and clean as writing sequential code, with the safety net of supervision and fault tolerance built into the language.
**Current focus:** v11.0 Query Builder -- Phase 107 (next)

## Current Position

Phase: 107 of 114 (v11.0 Query Builder)
Plan: 2 of 2 in current phase
Status: Phase Complete
Last activity: 2026-02-17 -- Completed 107-02 (JOIN runtime verification and requirement closure)

Progress: [█░░░░░░░░░] 10% (v11.0)

## Performance Metrics

**All-time Totals:**
- Plans completed: 314
- Phases completed: 106
- Milestones shipped: 20 (v1.0-v10.1)
- Lines of Rust: ~98,850
- Lines of website: ~5,500
- Lines of Mesh: ~4,020
- Timeline: 12 days (2026-02-05 -> 2026-02-17)

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 104   | 01   | 12min    | 2     | 3     |
| 105   | 01   | 18min    | 3     | 1     |
| 105   | 02   | 8min     | 3     | 4     |
| 105.1 | 02   | 9min     | 1     | 1     |
| 105.1 | 01   | 17min    | 2     | 5     |
| 105.1 | 03   | 9min     | 2     | 2     |
| 106   | 01   | 8min     | 2     | 8     |
| 106   | 02   | 8min     | 2     | 8     |
| 107   | 01   | 6min     | 2     | 8     |
| 107   | 02   | 1min     | 1     | 4     |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Phase 105.1: Pass MIR return type to codegen_service_call_helper for type-aware reply conversion
- Phase 105.1: Construction-side fix only for struct-in-Result: existing codegen_leaf deref logic handles destructuring
- Phase 105.1: Auth workaround reverted -- authenticate_request returns Project!String directly
- Phase 105.1: EventProcessor service call SIGSEGV persists -- needs dedicated investigation
- [Phase 106]: OR clause encoding uses OR:field1,field2,...:N format with field names embedded in clause string
- [Phase 106]: ILIKE added as atom_to_sql_op mapping -- no new function needed, works via existing where_op
- [Phase 106]: Unified renumber_placeholders helper handles both ? and $N styles in a single pass
- [Phase 106]: RAW: prefix reused for ORDER BY and GROUP BY raw expressions, consistent with existing pattern
- [Phase 107]: ALIAS: prefix encoding distinguishes aliased from regular joins in join_clauses list
- [Phase 107]: SQL aliases (AS) used in JOIN queries for unambiguous column names in runtime E2E tests

### Roadmap Evolution

- v11.0 roadmap created: 9 phases (106-114), 32 requirements mapped

### Pending Todos

None.

### Blockers/Concerns

- Event ingestion (POST /api/v1/events) crashes during background EventProcessor service call after HTTP response is sent. Requires deeper investigation of EventProcessor service loop state or call dispatch.

## Session Continuity

Last session: 2026-02-17
Stopped at: Completed 107-02-PLAN.md (JOIN runtime verification and requirement closure) -- Phase 107 fully complete
Resume file: None
Next action: Plan Phase 108
