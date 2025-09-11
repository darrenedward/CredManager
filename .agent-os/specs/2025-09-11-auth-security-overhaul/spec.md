# Spec Requirements Document

> Spec: Auth Security Overhaul
> Created: 2025-09-11

## Overview

Overhaul the authentication system to fix passcode rejection issues, remove insecure legacy SHA-256 fallback, enforce Argon2-only military-grade encryption, migrate to encrypted DB-only storage, eliminate mocks and hardcodes, and ensure maximum security for storing API keys and credentials in this vault app.

## User Stories

### Secure Authentication Setup and Login
As a user setting up the app, I want to create a passphrase and security questions using only Argon2 hashing stored in an encrypted database, so that my credentials are protected from brute-force attacks and device extraction without relying on weak fallbacks or unencrypted storage.

Detailed Workflow: During setup, trim and hash passphrase with Argon2id (fixed parsing), derive DB unlock key, encrypt all data (hashes, questions, metadata) in SQLCipher DB. On login, verify exact (trimmed) input against DB hash, rate-limit attempts, derive session keys for JWT and decrypts.

### Credential Vault Security
As a credential manager user, I want all API keys and passwords encrypted with passphrase-derived AES-GCM and stored only in a single encrypted DB, so that even if the device is compromised, data remains inaccessible without my passphrase.

Detailed Workflow: On successful auth, unlock DB with derived key, decrypt credentials in-memory only. Support re-encryption on passphrase change, biometrics with real AES (not base64), and secure erase on logout. No SharedPreferences or SecureStorage; all flags in DB metadata.

### Legacy Migration and Hardcode Removal
As an existing user, I want seamless migration from legacy SHA or mixed storage, with prompts to re-setup under new security model, so that my data is upgraded without loss and the app avoids exposing mocks or hardcodes.

Detailed Workflow: Detect legacy hashes/flags during init, prompt migration (re-hash to Argon2, move to DB), remove predefined questions (user-defined only), derive all secrets dynamically (no hardcoded JWT key), update UI to enforce secure practices.

## Spec Scope
1. **Argon2 Auth Fix** - Repair parsing bug in verifyPassword, add trim normalization, remove SHA fallback entirely.
2. **Encrypted DB Integration** - Replace sqflite with SQLCipher, passphrase-derived PRAGMA key, consolidate all storage (hashes, flags, questions, creds) to DB.
3. **Dynamic Secrets and No Mocks** - Derive JWT/DB/AES keys from passphrase, delete predefinedSecurityQuestions, enforce user-only inputs.
4. **Enhanced Biometrics and Rate-Limiting** - AES-encrypt stored passphrase, add login attempt limits (5/5min), secure memory zeroing on logout.
5. **Migration and Tests** - Auto-detect/convert legacy data, update tests for Argon2-only paths, add security validations (timing, extraction sim).

## Out of Scope
- Network API changes (app remains offline-only).
- New UI features beyond migration prompts and validation.
- Cross-device sync (local vault only).
- Advanced audits like formal verification (focus on fixes and tests).

## Expected Deliverable
1. Successful end-to-end login/setup/recovery with Argon2-only, no rejections, verified via debug logs and tests.
2. Encrypted DB extract shows unreadable data without passphrase; all storage consolidated (no prefs/SecureStorage usage).
3. No legacy SHA paths, mocks, or hardcodes; migration handles old data; biometrics decrypts correctly; logout zeros secrets.