---
phase: 142-update-docs-page-with-changes-additions-from-v14
plan: "01"
subsystem: website/docs
tags: [documentation, vitepress, stdlib, crypto, encoding, datetime, testing]
dependency_graph:
  requires: []
  provides:
    - website/docs/docs/stdlib/index.md
    - website/docs/docs/testing/index.md
    - website/docs/.vitepress/config.mts (sidebar + meshVersion 14.0)
  affects:
    - website/docs (VitePress sidebar)
tech_stack:
  added: []
  patterns:
    - VitePress Markdown pages with frontmatter
    - Sidebar group insertion in config.mts
key_files:
  created:
    - website/docs/docs/stdlib/index.md
    - website/docs/docs/testing/index.md
  modified:
    - website/docs/.vitepress/config.mts
decisions:
  - Combined Crypto, Base64, Hex, DateTime into single Standard Library page per research recommendation
  - Sidebar group named 'Standard Library' inserted between Tooling and Reference groups
  - All code examples sourced exclusively from passing e2e tests (no invented syntax)
metrics:
  duration: "109s"
  completed_date: "2026-03-01"
  tasks_completed: 3
  files_created: 2
  files_modified: 1
---

# Phase 142 Plan 01: VitePress Config + New Doc Pages Summary

Two new documentation pages (Standard Library reference and Testing Framework guide) added for v14.0 stdlib features, plus VitePress config updated with sidebar entries and version bump to 14.0.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Update VitePress config — sidebar + meshVersion | f8864344 | website/docs/.vitepress/config.mts |
| 2 | Create Standard Library doc page (Crypto, Encoding, DateTime) | 9a46329f | website/docs/docs/stdlib/index.md |
| 3 | Create Testing Framework doc page | 3b5f8033 | website/docs/docs/testing/index.md |

## What Was Built

### Task 1: VitePress Config Update

Updated `website/docs/.vitepress/config.mts`:
- Changed `meshVersion: '12.0'` to `meshVersion: '14.0'`
- Added "Standard Library" sidebar group with links to `/docs/stdlib/` and `/docs/testing/`
- Inserted the new group between Tooling and Reference groups (as specified)

### Task 2: Standard Library Doc Page

Created `website/docs/docs/stdlib/index.md` (204 lines):
- **Crypto section**: sha256, sha512, hmac_sha256, hmac_sha512, secure_compare, uuid4 — each with verified code examples and API tables
- **Encoding section**: Base64 (encode, decode, encode_url, decode_url) and Hex (encode, decode) — both noting the `Result<String, String>` return type for decode operations
- **DateTime section**: utc_now, from_iso8601, to_iso8601, unix interop (from_unix_ms, from_unix_secs, to_unix_ms, to_unix_secs), arithmetic (add, diff), and comparison (is_before, is_after)

### Task 3: Testing Framework Doc Page

Created `website/docs/docs/testing/index.md` (155 lines):
- **Runner section**: `meshc test .` discovery, output format, non-zero exit on failure
- **Writing tests**: `test("name") do ... end` pattern
- **Assertions**: assert, assert_eq, assert_ne, assert_raises with examples
- **describe**: grouping with `describe("group") do ... end`
- **setup/teardown**: scoped lifecycle hooks within describe blocks
- **Mock actors**: `Test.mock_actor` with callback pattern, "ok"/"stop" return semantics
- **assert_receive**: pattern matching with timeout, default 100ms
- **Coverage**: `--coverage` stub with v14.1 roadmap note

## Decisions Made

1. **Combined stdlib modules into single page**: Crypto, Base64, Hex, and DateTime documented on one `/docs/stdlib/` page rather than separate pages — keeps sidebar clean, consistent with other langs' stdlib reference pages, and all modules are small enough to share one page.

2. **Sidebar group naming**: Used "Standard Library" as the group text (matching the `text` field in the plan spec) rather than splitting into multiple groups.

3. **Code example sourcing**: All Mesh code blocks sourced from verified e2e tests: `crypto_sha256.mpl`, `crypto_sha512.mpl`, `crypto_hmac.mpl`, `crypto_uuid4.mpl`, `crypto_secure_compare.mpl`, `base64_encode_decode.mpl`, `base64_url_encode_decode.mpl`, `hex_encode_decode.mpl`, `datetime_utc_now.mpl`, `datetime_iso8601_roundtrip.mpl`, `datetime_add_diff.mpl`, `datetime_compare.mpl`, `test_basic.test.mpl`, `test_describe.test.mpl`, `test_setup_teardown.test.mpl`, `test_mock_actor.test.mpl`.

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

All 10 verification checks passed:
1. `meshVersion: '14.0'` present in config.mts
2. `docs/stdlib/` sidebar entry present
3. `docs/testing/` sidebar entry present
4. `website/docs/docs/stdlib/index.md` exists (204 lines, well above 100-line minimum)
5. `website/docs/docs/testing/index.md` exists (155 lines, well above 80-line minimum)
6. `Crypto.sha256` present in stdlib page
7. `Base64.encode` present in stdlib page
8. `DateTime.utc_now` present in stdlib page
9. `meshc test` present in testing page
10. `assert_receive` present in testing page

## Self-Check: PASSED

All created files verified to exist on disk:
- FOUND: website/docs/docs/stdlib/index.md
- FOUND: website/docs/docs/testing/index.md
- FOUND: .planning/phases/142-update-docs-page-with-changes-additions-from-v14/142-01-SUMMARY.md

All task commits verified in git log:
- FOUND: f8864344 (Task 1 — VitePress config)
- FOUND: 9a46329f (Task 2 — stdlib page)
- FOUND: 3b5f8033 (Task 3 — testing page)
