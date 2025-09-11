# Spec Tasks: Auth Security Overhaul

## Tasks

### PT001: Argon2 Authentication Fix and Enhancement
**Status:** [x] COMPLETE
**Effort:** M (3-4 days)
**Description:** Fix passphrase parsing bugs, enforce Argon2-only hashing, remove SHA fallback, and implement proper input normalization

**Subtasks:**
- [x] ST001: Write comprehensive tests for Argon2 password verification with edge cases
- [x] ST002: Fix passphrase parsing bug to handle whitespace and normalization
- [x] ST003: Remove SHA-256 fallback implementation entirely
- [x] ST004: Implement proper Argon2id parameter configuration for security
- [x] ST005: Add input validation and sanitization for passphrases
- [x] ST006: Update all authentication tests to use Argon2-only paths
- [x] ST007: Verify all authentication tests pass with new implementation

### PT002: Encrypted Database Integration
**Status:** [ ] TODO
**Effort:** L (5-7 days)
**Description:** Replace SQLite with SQLCipher, implement passphrase-derived encryption, consolidate all storage to encrypted DB

**Subtasks:**
- [x] ST008: Write tests for SQLCipher integration and data encryption
- [x] ST009: Replace sqflite dependency with SQLCipher package
- [ ] ST010: Implement passphrase-derived database encryption key
- [ ] ST011: Migrate all authentication data to encrypted database
- [ ] ST012: Remove SharedPreferences and SecureStorage usage for auth data
- [ ] ST013: Implement database schema for consolidated storage
- [ ] ST014: Add database encryption validation tests
- [ ] ST015: Verify all database encryption tests pass

### PT003: Dynamic Secrets and Hardcode Removal
**Status:** [ ] TODO
**Effort:** M (3-4 days)
**Description:** Remove all hardcoded values, implement dynamic key derivation, enforce user-only security questions

**Subtasks:**
- [ ] ST016: Write tests for dynamic key derivation and JWT generation
- [ ] ST017: Remove predefined security questions implementation
- [ ] ST018: Implement passphrase-derived JWT secret keys
- [ ] ST019: Remove all hardcoded values and mock data
- [ ] ST020: Implement dynamic AES key derivation for credential encryption
- [ ] ST021: Update UI to enforce user-defined security questions only
- [ ] ST022: Verify all dynamic secrets tests pass

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