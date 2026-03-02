---
phase: 135-encoding-crypto-stdlib
plan: 02
subsystem: stdlib
tags: [base64, hex, encoding, rust, llvm, typeck]

# Dependency graph
requires:
  - phase: 135-01
    provides: "Crypto stdlib module and five-registration-point pattern (builtins.rs, infer.rs stdlib_modules, infer.rs STDLIB_MODULE_NAMES, lower.rs STDLIB_MODULES + map_builtin_name + known_functions, intrinsics.rs)"
provides:
  - "Base64 stdlib module: encode, decode, encode_url, decode_url (RFC 4648 compliant)"
  - "Hex stdlib module: encode (lowercase), decode (case-insensitive)"
  - "6 extern C functions appended to compiler/mesh-rt/src/crypto.rs"
  - "Type registrations in mesh-typeck builtins.rs and infer.rs"
  - "LLVM intrinsic declarations in mesh-codegen intrinsics.rs"
  - "MIR lowering wiring in mesh-codegen lower.rs"
  - "3 e2e test fixtures and 5 Rust test functions"
affects: ["136-datetime", "138-testing", "139-package-manifest"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "base64 0.22 API: general_purpose::STANDARD.encode/decode + URL_SAFE_NO_PAD (already in Cargo.toml)"
    - "Lenient Base64 decode: try padded first, then unpadded — prevents incorrect byte stripping"
    - "Hex encode via format loop (no new dep): input.iter().map(|b| format!(':02x', b)).collect()"
    - "Hex decode with to_lowercase() before parsing for case-insensitivity"

key-files:
  created:
    - tests/e2e/base64_encode_decode.mpl
    - tests/e2e/base64_url_encode_decode.mpl
    - tests/e2e/hex_encode_decode.mpl
  modified:
    - compiler/mesh-rt/src/crypto.rs
    - compiler/mesh-typeck/src/builtins.rs
    - compiler/mesh-typeck/src/infer.rs
    - compiler/mesh-codegen/src/mir/lower.rs
    - compiler/mesh-codegen/src/codegen/intrinsics.rs
    - compiler/meshc/tests/e2e.rs

key-decisions:
  - "Lenient Base64.decode tries STANDARD (padded) first, then STANDARD_NO_PAD — if unpadded first, padded input gets bytes incorrectly stripped"
  - "Base64.decode_url uses URL_SAFE_NO_PAD exclusively (no lenient fallback) — URL-safe mode has unambiguous no-padding semantics"
  - "Hex.decode is case-insensitive via to_lowercase() before parsing — accepts both 6869 and DEADBEEF"
  - "Error strings locked: 'invalid base64', 'invalid utf-8', 'invalid hex' — consistent with plan spec"
  - "Zero new Rust dependencies — base64 0.22 already in Cargo.toml from WebSocket handshake implementation"

patterns-established:
  - "New stdlib module with Result-returning functions: decode functions use MirType::Ptr return type (opaque Result pointer)"
  - "Appending to existing runtime module (crypto.rs) keeps encoding functions co-located with related crypto functions"

requirements-completed: [ENCODE-01, ENCODE-02, ENCODE-03, ENCODE-04, ENCODE-05, ENCODE-06]

# Metrics
duration: 4min
completed: 2026-02-28
---

# Phase 135 Plan 02: Encoding Stdlib Module Summary

**6-function Base64/Hex stdlib (RFC 4648 standard+URL-safe Base64, case-insensitive Hex) using base64 0.22 already in Cargo.toml, lenient padded decode, zero new dependencies, all 5 e2e tests passing**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-28T07:18:52Z
- **Completed:** 2026-02-28T07:22:54Z
- **Tasks:** 3
- **Files modified:** 6 (+ 3 created)

## Accomplishments

- Appended 6 extern C functions to `compiler/mesh-rt/src/crypto.rs`: mesh_base64_encode, mesh_base64_decode, mesh_base64_encode_url, mesh_base64_decode_url, mesh_hex_encode, mesh_hex_decode — zero new Rust dependencies
- Wired Base64 and Hex through all 5 compiler registration points following the pattern documented in Plan 01: builtins.rs, infer.rs (2 locations), lower.rs (3 locations), intrinsics.rs
- All 5 Base64/Hex e2e tests pass: Base64.encode("hello") = "aGVsbG8=" (padded), encode_url("hello") = "aGVsbG8" (no padding), Hex.encode("hi") = "6869" (lowercase), Hex.decode("6869") = Ok("hi"), all Plan 01 Crypto regression tests still pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Append Base64 and Hex extern C functions to crypto.rs** - `59271650` (feat)
2. **Task 2: Wire Base64 and Hex modules into typeck, MIR lowering, and LLVM intrinsics** - `bc18ebf3` (feat)
3. **Task 3: Write Base64 and Hex e2e fixtures and Rust test functions** - `52c9c280` (feat)

## Files Created/Modified

- `compiler/mesh-rt/src/crypto.rs` - 6 new extern C functions appended: Base64 standard/URL-safe encode+decode, Hex encode+decode; added base64 and io imports
- `compiler/mesh-typeck/src/builtins.rs` - 6 type registrations for base64_encode, base64_decode, base64_encode_url, base64_decode_url, hex_encode, hex_decode
- `compiler/mesh-typeck/src/infer.rs` - Base64 and Hex modules added to stdlib_modules() HashMap + STDLIB_MODULE_NAMES const
- `compiler/mesh-codegen/src/mir/lower.rs` - "Base64" and "Hex" in STDLIB_MODULES + 6 map_builtin_name entries + 6 known_functions entries (encode->String, decode->Ptr)
- `compiler/mesh-codegen/src/codegen/intrinsics.rs` - 6 LLVM External declarations (all ptr -> ptr)
- `compiler/meshc/tests/e2e.rs` - 5 Rust e2e test functions added
- `tests/e2e/base64_encode_decode.mpl` - Standard encode/decode round-trip and invalid input fixture
- `tests/e2e/base64_url_encode_decode.mpl` - URL-safe encode/decode fixture
- `tests/e2e/hex_encode_decode.mpl` - Lowercase encode, case-insensitive decode, invalid input fixture

## Decisions Made

- Used lenient Base64.decode: tries STANDARD (padded) first, then STANDARD_NO_PAD. This order is essential — if unpadded is tried first, padded input (like "aGVsbG8=") has the `=` bytes incorrectly stripped
- Base64.decode_url uses URL_SAFE_NO_PAD exclusively without fallback — URL-safe mode has unambiguous no-padding semantics
- Hex.decode lowercases input before parsing: `(*s).as_str().to_lowercase()` — simple and correct for ASCII hex digits
- All error strings match plan spec exactly: "invalid base64", "invalid utf-8", "invalid hex"

## Deviations from Plan

None - plan executed exactly as written. The five-registration-point pattern discovered in Plan 01 was correctly applied from the start in Plan 02. All 6 functions compile and all 5 tests pass on first attempt.

## Issues Encountered

None beyond what is documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Base64 and Hex modules fully operational — Mesh programs can call `Base64.encode`, `Base64.decode`, `Hex.encode`, `Hex.decode` etc.
- Phase 135 (Encoding & Crypto Stdlib) is now complete — all 12 functions from both plans implemented and tested
- Phase 136 (DateTime Stdlib) can proceed following the same 5-registration-point pattern

---
*Phase: 135-encoding-crypto-stdlib*
*Completed: 2026-02-28*
