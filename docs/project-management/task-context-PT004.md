# Task Context: PT004 - Enhanced Security Features

## Task Overview
**Parent Task:** PT004
**Status:** TODO
**Effort:** M (3-4 days)
**Description:** Implement rate limiting, secure biometrics, memory protection, and session management

## Subtasks
- ST023: Write tests for rate limiting and login attempt tracking
- ST024: Implement login attempt rate limiting (5 attempts/5 minutes)
- ST025: Enhance biometric authentication with proper AES encryption
- ST026: Implement secure memory zeroing on logout and app termination
- ST027: Add session management with automatic timeout
- ST028: Implement secure credential decryption/encryption flow
- ST029: Verify all security enhancement tests pass

## Dependencies
- Depends on PT003 (Dynamic secrets needed for enhanced security)

## Technical Context
From technical-spec.md:
- Implement login rate-limiting: add static int loginAttempts = 0; DateTime? lastLoginAttempt; in login method, if _isLoginLockedOut() throw LockoutException; increment on fail, reset after 5min; lockout if >=5 attempts in 300s.
- For biometrics, in biometric_auth_service.dart, replace base64 with _encryption.encrypt(passphrase, derived_key) for storeBiometricKey; decrypt in loginWithBiometric.
- Add in auth_state.dart logout: _currentPassphrase = null; (Dart strings immutable, but clear any buffers); call _encryption.clearKeyCache(); _credentialStorage.clearPassphrase().
- Ensure Argon2 calls <200ms; use transactions for batch ops. Catch decrypt fails in credential_storage_service, log/quarantine. UI: Generic errors ("Invalid input" for trim fails, "Too many attempts" for lockout).

## Product Context
API Key Manager is a desktop security application for secure credential management with military-grade encryption.

## Spec Summary
Overhaul authentication with Argon2-only enforcement, SQLCipher-encrypted database, dynamic secrets derivation, and enhanced security features.