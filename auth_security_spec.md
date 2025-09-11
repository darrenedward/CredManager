# Authentication and Security Specification for Cred Manager

## 1. Problem Statement
The current implementation has authentication failures (passcode rejection due to Argon2 parsing bugs and lack of input normalization) and security gaps unsuitable for a high-security credential vault:
- Legacy SHA-256 fallback (insecure for passwords).
- Unencrypted SQLite DB (sqflite; vulnerable to extraction).
- Mixed storage (SecureStorage + SharedPreferences + DB).
- Hardcoded JWT secrets and mock data (predefined questions, localhost URL).
- Weak biometrics (base64 only).
- No login rate-limiting, potential side-channels.

This spec outlines fixes to enforce Argon2-only auth, SQLCipher-encrypted DB-only storage, dynamic secrets, no mocks, maximizing security for API keys/passwords.

## 2. Requirements

### Functional Requirements
- **Auth**: Passcode login/setup/recovery must succeed with exact (trimmed, case-sensitive) match. Remove SHA fallback; migrate legacy users.
- **Storage**: All data (hashes, questions, flags, credentials) in single encrypted DB. No prefs/SecureStorage fallbacks.
- **Crypto**: Argon2id for all key derivation (auth + encryption). AES-GCM-256 for data. Derived JWT secrets (no hardcode).
- **UI**: Prompt migration for legacy, enforce user-defined questions only. Validate/normalize inputs (trim, no mocks).
- **Migration**: Detect/convert SHA hashes to Argon2 during first login. Re-encrypt DB on passphrase change.
- **Biometrics**: Real AES-encrypt stored passphrase.

### Non-Functional Requirements
- **Performance**: Argon2 params unchanged (64MB/1iter/4par – ~100ms on mobile). DB queries <50ms.
- **Compatibility**: Cross-platform (Android/Linux/Mac/Windows/iOS). No breaking changes for new users.
- **Reliability**: Transactions for atomic ops. Error handling (e.g., decrypt fails → quarantine data).
- **Usability**: Generic errors only (no leaks). Rate-limit login (5 attempts/5min, lockout).

### Security Requirements
- **Confidentiality**: DB encrypted with SQLCipher (passphrase-derived key). All secrets derived from passphrase (PBKDF2/Argon2). Constant-time ops.
- **Integrity**: AES-GCM auth tags. FK constraints/cascades. Validate decrypts on read.
- **Availability**: Offline-only. Secure erase (zero memory) on logout.
- **Threat Mitigation**: No fallbacks/mocks. Rate-limit brute-force. Audit logs (optional). OWASP Mobile Top 10 compliance.
- **Compliance**: Argon2 (NIST-approved), AES-256 (FIPS). No known vulns in deps.

## 3. Current Architecture Analysis
(See attached report for details.)
- Auth: Argon2 (buggy verify) + SHA fallback → Refactor to Argon2-only.
- DB: Plain sqflite → Integrate sqlcipher_flutter_libs + passphrase encrypt.
- Storage: Mixed → Consolidate to DB (store flags/metadata in app_metadata table).
- Crypto: Strong primitives, but hardcoded secrets/mocks → Derive dynamically, remove predefined questions.
- JWT: HS256 with hardcode → Derive secret from passphrase hash.
- Biometrics: Base64 → AES with derived key.

Data Flow:
1. Setup: Derive Argon2 hash → Store in DB (encrypted). Encrypt questions/creds.
2. Login: Verify Argon2 → Derive session key → Decrypt DB access.
3. Vault: All reads/writes via passphrase-derived AES.

## 4. Proposed Architecture
- **Components**:
  - **AuthService**: Argon2-only (fixed parsing: clean split('$'), trim input). Rate-limit login. Derive JWT secret.
  - **SecureDBService**: Extends DatabaseService with SQLCipher (passphrase key via PRAGMA key). Store all (incl. hash/token as encrypted blobs in metadata).
  - **CredentialService**: Unchanged, but uses SecureDB + derived keys.
  - **EncryptionService**: Unchanged (strong).
  - **BiometricService**: AES-encrypt passphrase (using EncryptionService).
  - **Utils**: Remove mocks from constants.dart (dynamic questions via UI). Gen secrets runtime.

- **Data Flow**:
  1. App start: Check DB setup; if legacy, migrate.
  2. Login: Input → Trim → Argon2 verify (from DB) → Derive master key → Unlock DB (SQLCipher) → Gen JWT (derived secret).
  3. Session: In-memory decrypts; logout → Lock DB, zero keys.
  4. Recovery: Verify questions (Argon2 from DB) → Reset hash.

- **Storage Schema Updates**:
  - Add to app_metadata: encrypted_passphrase_hash, encrypted_token, is_first_time (bool as 0/1), setup_completed.
  - Security_questions: Already encrypted hashes.
  - Credentials/AI: Unchanged (app-level encrypt).

- **Secret Management**: All from passphrase: Argon2(passphrase + unique_salt) → Sub-keys for JWT/DB/AES.

## 5. Security Model
- **Key Hierarchy**: User passphrase → Argon2 (salt stored plain in DB metadata) → Master key → Derive: DB key (SQLCipher), AES key (creds), JWT secret.
- **Protections**: Device-bound (biometrics), no cloud, encrypted at rest (DB + fields), in-use (memory only during ops).
- **Attack Resistance**: Brute-force (Argon2 slow), extraction (SQLCipher), replay (JWT exp/timers), side-channel (constant-time).
- **Best Practices**: OWASP Mobile: M1 (crypto), M2 (storage), M9 (reverse eng – obfuscate?).

## 6. Implementation Tasks
(See todo list below for breakdown.)

## 7. Testing & Validation
- **Unit**: Test Argon2 verify (fixed parsing, normalization), SQLCipher unlock, derive keys, no SHA paths.
- **Integration**: Full login/setup/recovery with DB. Biometric round-trip.
- **Security**: Fuzz inputs, timing analysis, extract DB (verify encrypted), brute-force sim.
- **Migration**: Test legacy SHA → Argon2, prefs → DB.
- **Coverage**: 90%+ on auth/storage/crypto. Tools: flutter_test, mockito.

## 8. Risks & Mitigations
- **Risk**: Migration breaks data → Backup DB pre-migrate; dry-run mode.
- **Risk**: SQLCipher perf/platform issues → Benchmark; fallback to encrypted file if needed (but avoid).
- **Risk**: User lockout (wrong deriv) → Recovery prompts re-setup.
- **Risk**: Deps vulns → Pin versions, audit cryptography/sqlcipher_flutter_libs.

This spec provides a secure foundation. Approve for implementation in code mode.