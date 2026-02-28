//! Cryptographic functions for the Mesh standard library.
//!
//! Provides mesh_crypto_sha256, mesh_crypto_sha512, mesh_crypto_hmac_sha256,
//! mesh_crypto_hmac_sha512, mesh_crypto_secure_compare, and mesh_crypto_uuid4.
//!
//! All hash functions return lowercase hex-encoded strings.
//! secure_compare is constant-time (no short-circuit on length mismatch).
//! uuid4 produces RFC 4122 v4 UUIDs using the rand 0.9 API.

use crate::string::{MeshString, mesh_string_new};
use sha2::{Digest, Sha256, Sha512};
use hmac::{Hmac, Mac};
use std::hint::black_box;
use rand::RngCore;

type HmacSha256 = Hmac<Sha256>;
type HmacSha512 = Hmac<Sha512>;

// ── Public ABI ─────────────────────────────────────────────────────────

/// Crypto.sha256(s) -> String
///
/// Returns the SHA-256 digest of the UTF-8 bytes of `s` as a lowercase hex string.
/// NIST test vector: sha256("hello") = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
#[no_mangle]
pub extern "C" fn mesh_crypto_sha256(s: *const MeshString) -> *mut MeshString {
    unsafe {
        let input = (*s).as_str().as_bytes();
        let hash = Sha256::digest(input);
        let hex: String = hash.iter().map(|b| format!("{:02x}", b)).collect();
        mesh_string_new(hex.as_ptr(), hex.len() as u64)
    }
}

/// Crypto.sha512(s) -> String
///
/// Returns the SHA-512 digest of the UTF-8 bytes of `s` as a lowercase hex string.
#[no_mangle]
pub extern "C" fn mesh_crypto_sha512(s: *const MeshString) -> *mut MeshString {
    unsafe {
        let input = (*s).as_str().as_bytes();
        let hash = Sha512::digest(input);
        let hex: String = hash.iter().map(|b| format!("{:02x}", b)).collect();
        mesh_string_new(hex.as_ptr(), hex.len() as u64)
    }
}

/// Crypto.hmac_sha256(key, msg) -> String
///
/// Returns the HMAC-SHA256 of `msg` keyed with `key`, as a lowercase hex string.
/// RFC 2202 test vector: hmac_sha256("Jefe", "what do ya want for nothing?")
///   = "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964a72840"
#[no_mangle]
pub extern "C" fn mesh_crypto_hmac_sha256(
    key: *const MeshString,
    msg: *const MeshString,
) -> *mut MeshString {
    unsafe {
        let k = (*key).as_str().as_bytes();
        let m = (*msg).as_str().as_bytes();
        let mut mac = HmacSha256::new_from_slice(k)
            .expect("HMAC accepts any key length");
        mac.update(m);
        let result = mac.finalize();
        let hex: String = result.into_bytes().iter()
            .map(|b| format!("{:02x}", b)).collect();
        mesh_string_new(hex.as_ptr(), hex.len() as u64)
    }
}

/// Crypto.hmac_sha512(key, msg) -> String
///
/// Returns the HMAC-SHA512 of `msg` keyed with `key`, as a lowercase hex string.
/// RFC 2202 test vector: hmac_sha512("Jefe", "what do ya want for nothing?")
///   = "164b7a7bfcf819e2e395fbe73b56e0a387bd64222e831fd610270cd7ea2505549758bf75c05a994a6d034f65f8f0e6fdcaeab1a34d4a6b4b636e070a38bce737"
#[no_mangle]
pub extern "C" fn mesh_crypto_hmac_sha512(
    key: *const MeshString,
    msg: *const MeshString,
) -> *mut MeshString {
    unsafe {
        let k = (*key).as_str().as_bytes();
        let m = (*msg).as_str().as_bytes();
        let mut mac = HmacSha512::new_from_slice(k)
            .expect("HMAC accepts any key length");
        mac.update(m);
        let result = mac.finalize();
        let hex: String = result.into_bytes().iter()
            .map(|b| format!("{:02x}", b)).collect();
        mesh_string_new(hex.as_ptr(), hex.len() as u64)
    }
}

/// Crypto.secure_compare(a, b) -> Bool
///
/// Constant-time string comparison. Returns 1 (true) if `a == b`, 0 (false) otherwise.
/// CRITICAL: Does NOT short-circuit on length mismatch — all bytes are always compared.
/// This prevents timing attacks that would reveal the length of secret values.
///
/// Uses std::hint::black_box to prevent LLVM from eliminating the accumulation loop.
#[no_mangle]
pub extern "C" fn mesh_crypto_secure_compare(
    a: *const MeshString,
    b: *const MeshString,
) -> i8 {
    unsafe {
        let a_bytes = (*a).as_str().as_bytes();
        let b_bytes = (*b).as_str().as_bytes();
        // Constant-time: NEVER short-circuit on length mismatch — accumulate all diffs
        let max_len = a_bytes.len().max(b_bytes.len());
        let mut diff: u8 = 0;
        for i in 0..max_len {
            let a_byte = if i < a_bytes.len() { a_bytes[i] } else { 0 };
            let b_byte = if i < b_bytes.len() { b_bytes[i] } else { 0 };
            diff |= a_byte ^ b_byte;
        }
        // XOR length difference into diff — length itself is not leaked
        diff |= (a_bytes.len() ^ b_bytes.len()) as u8;
        // black_box prevents LLVM from eliminating the accumulation loop
        if black_box(diff) == 0 { 1 } else { 0 }
    }
}

/// Crypto.uuid4() -> String
///
/// Generates a random RFC 4122 v4 UUID using cryptographically random bytes.
/// Format: 8-4-4-4-12 hex characters separated by hyphens (36 characters total).
/// Version nibble set to 4 (0100), variant bits set to 10xx.
///
/// Uses rand 0.9 API: rand::rng().fill_bytes() (NOT rand::thread_rng() — removed in 0.9).
#[no_mangle]
pub extern "C" fn mesh_crypto_uuid4() -> *mut MeshString {
    let mut bytes = [0u8; 16];
    rand::rng().fill_bytes(&mut bytes);
    // RFC 4122 version 4 (0b0100) + variant 10xx (0b10xx)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    let uuid = format!(
        "{:02x}{:02x}{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}",
        bytes[0], bytes[1], bytes[2], bytes[3],
        bytes[4], bytes[5],
        bytes[6], bytes[7],
        bytes[8], bytes[9],
        bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
    );
    mesh_string_new(uuid.as_ptr(), uuid.len() as u64)
}
