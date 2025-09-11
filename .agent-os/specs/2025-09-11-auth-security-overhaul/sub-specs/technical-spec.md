# Technical Specification

This is the technical specification for the spec detailed in .agent-os/specs/2025-09-11-auth-security-overhaul/spec.md

## Technical Requirements

- **Authentication Refactoring**: Update argon2_service.dart verifyPassword to parse encodedHash with clean split(r'$') expecting exactly 6 parts ( ['', 'argon2id', 'v=19', param_section, saltB64, hashB64 ]); dynamically parse m/t/p from param_section.split(','); remove all try-catch with '4' and redundant fallbacks; throw FormatException on invalid format. In auth_service.dart, modify _verifyPassphrase to check startsWith('$argon2id$') only, delegate to Argon2.verifyPassword (no SHA branch); add passphrase = passphrase.trim() in login/createPassphrase/verifyRecoveryAnswers; document in comments that Argon2 is case-sensitive post-trim. Implement login rate-limiting: add static int loginAttempts = 0; DateTime? lastLoginAttempt; in login method, if _isLoginLockedOut() throw LockoutException; increment on fail, reset after 5min; lockout if >=5 attempts in 300s.
- **DB Encryption Integration**: Refactor database_service.dart to use sqlcipher_flutter_libs instead of sqflite/sqflite_common_ffi; add method Future<Database> initEncryptedDB(String passphrase) that derives key = await Argon2(passphrase, fixed_salt_from_metadata_or_gen) .extractBytes(); then openDatabase with PRAGMA key = 'x' + hex.encode(key); update onCreate/onUpgrade to run after PRAGMA; add passphrase param to all public methods (pass from auth_state after login). Consolidate storage_service.dart: move getPassphraseHash/storePassphraseHash to DB app_metadata (encrypt value with AES); same for token/flags (isFirstTime as bool 0/1); remove all SharedPreferences/FlutterSecureStorage calls, fallback migrations; update auth_state.initialize to use DB flags.
- **Dynamic Secrets and Biometrics**: In auth_service.dart, after verify, derive jwtSecret = await Argon2(passphrase, sub_salt='jwt').extractBytes(); pass to jwt_service.dart generateToken/verifyToken (modify methods to accept secret param, remove hardcoded). For biometrics, in biometric_auth_service.dart, replace base64 with _encryption.encrypt(passphrase, derived_key) for storeBiometricKey; decrypt in loginWithBiometric. Add in auth_state.dart logout: _currentPassphrase = null; (Dart strings immutable, but clear any buffers); call _encryption.clearKeyCache(); _credentialStorage.clearPassphrase().
- **Migration and UI Updates**: In storage_service.dart _loadAuthState, check if hash startsWith('$argon2id$') else prompt migration via UI (navigate to reset screen, re-hash with Argon2, update DB). In constants.dart, remove predefinedSecurityQuestions; in setup_screen.dart, require 3+ user-input questions, no defaults. Update validation.dart to enforce strong passphrase (length 12+, mix chars).
- **Performance and Error Handling**: Ensure Argon2 calls <200ms; use transactions for batch ops. Catch decrypt fails in credential_storage_service, log/quarantine. UI: Generic errors ("Invalid input" for trim fails, "Too many attempts" for lockout).

## External Dependencies (Conditional)

- **sqlcipher_flutter_libs** - For encrypted SQLite (SQLCipher) to secure DB at rest with passphrase key.
  - Justification: Current sqflite is unencrypted; SQLCipher provides AES-256 encryption with PRAGMA key support, essential for vault security without custom file encryption.
  - Version: ^0.5.0 (latest stable for Flutter 3+; cross-platform incl. FFI for desktop).

No other new deps; use existing cryptography for Argon2/AES derivations.