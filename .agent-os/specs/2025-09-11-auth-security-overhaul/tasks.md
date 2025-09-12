# Spec Tasks: Auth Security Overhaul

## Tasks

### PT001: Argon2 Authentication Fix and Enhancement
**Status:** [x] COMPLETE ✅
**Effort:** M (3-4 days)
**Description:** Fix passphrase parsing bugs, enforce Argon2-only hashing, remove SHA fallback, and implement proper input normalization

**Subtasks:**
- [x] ST001: Write comprehensive tests for Argon2 password verification with edge cases ✅ *COMPLETED*
- [x] ST002: Fix passphrase parsing bug to handle whitespace and normalization ✅ *COMPLETED*
- [x] ST003: Remove SHA-256 fallback implementation entirely ✅ *COMPLETED*
- [x] ST004: Implement proper Argon2id parameter configuration for security ✅ *COMPLETED*
- [x] ST005: Add input validation and sanitization for passphrases ✅ *COMPLETED*
- [x] ST006: Update all authentication tests to use Argon2-only paths ✅ *COMPLETED*
- [x] ST007: Verify all authentication tests pass with new implementation ✅ *COMPLETED*

### PT002: Encrypted Database Integration
**Status:** [x] COMPLETE ✅
**Effort:** L (5-7 days)
**Description:** Replace SQLite with SQLCipher, implement passphrase-derived encryption, consolidate all storage to encrypted DB

**Subtasks:**
- [x] ST008: Write tests for SQLCipher integration and data encryption ✅ *COMPLETED*
- [x] ST009: Replace sqflite dependency with SQLCipher package ✅ *COMPLETED*
- [x] ST010: Implement passphrase-derived database encryption key ✅ *COMPLETED*
- [x] ST011: Migrate all authentication data to encrypted database ✅ *COMPLETED*
- [x] ST012: Remove SharedPreferences and SecureStorage usage for auth data ✅ *COMPLETED*
- [x] **SQLCipher Linux Desktop Compatibility Fix** - Fixed SQLCipher plugin compatibility issue on Linux desktop by implementing platform-aware database service using sqflite_common_ffi for desktop and sqflite_sqlcipher for mobile ✅ *COMPLETED*
- [x] **Support Documentation Update** - Enhanced support screen with comprehensive FAQ section explaining biometric authentication availability, security features, and platform limitations without exposing implementation details ✅ *COMPLETED*
- [x] ST013: Implement database schema for consolidated storage ✅ *COMPLETED*
- [x] ST014: Add database encryption validation tests ✅ *COMPLETED*
- [x] ST015: Verify all database encryption tests pass ✅ *COMPLETED*

### PT003: Dynamic Secrets and Hardcode Removal
**Status:** [x] COMPLETE ✅
**Effort:** M (3-4 days)
**Description:** Remove all hardcoded values, implement dynamic key derivation, enforce user-only security questions

**Subtasks:**
- [x] ST016: Write tests for dynamic key derivation and JWT generation ✅ *COMPLETED*
- [x] ST017: Remove predefined security questions implementation ✅ *COMPLETED*
- [x] ST018: Implement passphrase-derived JWT secret keys ✅ *COMPLETED*
- [x] ST019: Remove all hardcoded values and mock data ✅ *COMPLETED*
- [x] ST020: Implement dynamic AES key derivation for credential encryption ✅ *COMPLETED*
- [x] ST021: Update UI to enforce user-defined security questions only ✅ *COMPLETED*
- [x] ST022: Verify all dynamic secrets tests pass ✅ *COMPLETED*

### PT004: Enhanced Security Features
**Status:** [ ] TODO
**Effort:** M (3-4 days)
**Description:** Implement rate limiting, secure biometrics, memory protection, and session management

**Subtasks:**
- [ ] ST023: Write tests for rate limiting and login attempt tracking
- [ ] ST024: Implement login attempt rate limiting (5 attempts/5 minutes)
- [ ] ST025: Enhance biometric authentication with proper AES encryption
- [ ] ST026: Implement secure memory zeroing on logout and app termination
- [ ] ST027: Add session management with automatic timeout
- [ ] ST028: Implement secure credential decryption/encryption flow
- [ ] ST029: Verify all security enhancement tests pass

### PT005: Legacy Migration and Comprehensive Testing
**Status:** [ ] TODO
**Effort:** M (3-4 days)
**Description:** Implement migration from legacy systems, update all tests, add security validations

**Subtasks:**
- [ ] ST030: Write migration tests for legacy SHA to Argon2 conversion
- [ ] ST031: Implement automatic legacy data detection and migration
- [ ] ST032: Create migration UI prompts for users with legacy data
- [ ] ST033: Update all existing tests for new security model
- [ ] ST034: Add security validation tests (timing attacks, data extraction)
- [ ] ST035: Perform comprehensive end-to-end security testing
- [ ] ST036: Verify all migration and security validation tests pass

## Dependencies
- PT001 → PT002 (Argon2 fixes needed before DB integration)
- PT002 → PT003 (Encrypted DB needed for dynamic secrets)
- PT003 → PT004 (Dynamic secrets needed for enhanced security)
- All tasks → PT005 (All components needed for migration testing)

## Technical Requirements
- **Flutter**: SQLCipher integration, Argon2 native bindings
- **Encryption**: AES-GCM for credentials, Argon2 for passphrases
- **Storage**: Single encrypted SQLCipher database only
- **Security**: No fallbacks, no hardcodes, no unencrypted storage
- **Performance**: Maintain <500ms authentication response time

## Testing Requirements
- Unit tests for all security components
- Integration tests for migration paths
- Security validation tests (brute force, timing attacks)
- End-to-end authentication flow tests
- Cross-platform testing (Linux, Windows, macOS)