# Phase 136: DateTime Stdlib - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Mesh programs gain a `DateTime` type with ISO 8601 parse/format, Unix timestamp interop (milliseconds and seconds variants), arithmetic (`add`/`diff`), and comparison (`before?`/`after?`) — all backed by chrono 0.4. Timezone database support and named timezones are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Timezone handling
- DateTime accepts timezone offsets in ISO 8601 input (e.g. `+05:30`)
- All offsets are normalized to UTC at parse time — DateTime is always stored as UTC internally
- `to_iso8601` always emits `Z` suffix (never `+00:00` or other offsets)
- Naive datetime strings with no timezone (e.g. `"2024-01-15T10:30:00"`) → `Err` — callers must provide explicit timezone

### Unix timestamp API naming
- Millisecond pair (primary): `DateTime.from_unix_ms(ms)` / `DateTime.to_unix_ms(dt)` — matches JS/HTTP convention
- Seconds pair (POSIX interop): `DateTime.from_unix_secs(s)` / `DateTime.to_unix_secs(dt)`
- Both `from_unix_ms` and `from_unix_secs` return `Result<DateTime, String>` for out-of-range or invalid values
- Note: roadmap names `from_unix`/`to_unix` — these should be updated to `from_unix_ms`/`to_unix_ms`

### ISO 8601 format
- `from_iso8601` accepts RFC 3339 only: `"2024-01-15T10:30:00Z"` or `"2024-01-15T10:30:00+05:30"`
- Space separator (`"2024-01-15 10:30:00Z"`) is NOT accepted — use strict `T` separator
- Fractional seconds are accepted and preserved at millisecond precision (e.g. `"2024-01-15T10:30:00.123Z"`)
- `to_iso8601` always emits milliseconds: `"2024-01-15T10:30:00.000Z"` even for whole-second values

### Duration units in add/diff
- Supported atoms: `:ms`, `:second`, `:minute`, `:hour`, `:day`, `:week` (all fixed-length)
- `:month` and `:year` are excluded — variable-length units add edge cases and belong in a future phase
- Unknown atom → runtime error/panic with a clear message (not a `Result` error)
- `DateTime.diff(dt1, dt2, unit)` returns `Float` — fractional units preserved (e.g. `2.7` for `:hour`)
- Float is the uniform return type regardless of unit (e.g. `5000.0` for `:ms`)
- `DateTime.add(dt, n, unit)` takes an integer `n` (negative for subtraction)

### Claude's Discretion
- Internal representation: i64 Unix milliseconds (as noted in roadmap plan)
- `utc_now()` implementation details
- Error message text for parse failures and invalid atoms
- E2E test fixture design

</decisions>

<specifics>
## Specific Ideas

- The API rename from `from_unix`/`to_unix` → `from_unix_ms`/`to_unix_ms` is intentional for clarity — no unit ambiguity at any call site
- `diff` returning Float (not Int) overrides the roadmap description of "signed integer" — this was an explicit user decision for fractional precision

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 136-datetime-stdlib*
*Context gathered: 2026-02-28*
