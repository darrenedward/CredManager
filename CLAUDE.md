# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Credential Manager** is a Flutter-based, local-only credential manager with military-grade encryption. It stores API keys, passwords, and connection strings in an encrypted SQLite database with zero network dependencies.

### Key Architecture Principles

1. **Local-Only Operation** - No backend server, all data stored locally in encrypted SQLite
2. **Dual-Platform Encryption Strategy**:
   - **Mobile (Android/iOS):** SQLCipher with PRAGMA key + XOR application-layer encryption
   - **Desktop (Linux/Windows/macOS):** SQLite with FFI + XOR application-layer encryption only
   - SQLCipher is not available on desktop, so application-layer encryption provides cross-platform security equivalence
3. **Provider State Management** - Uses `ChangeNotifier` pattern with `AuthState` as single source of truth
4. **Dynamic Secrets** - JWT secrets and biometric keys are derived from passphrase (not stored)

## Development Commands

### Flutter Development

```bash
cd frontend

# Install dependencies
flutter pub get

# Run in development mode
flutter run

# Run with specific platform
flutter run -d linux
flutter run -d android

# Run tests
flutter test

# Run specific test file
flutter test test/auth_service_test.dart

# Run integration tests
flutter test integration_test/

# Analyze code
flutter analyze

# Clean build artifacts
flutter clean
```

### Building for Production

```bash
# Build all platforms (from project root)
cd platforms
./build_all.sh

# Build specific platform
./build_all.sh --linux
./build_all.sh --android
./build_all.sh --macos

# Platform-specific direct build
cd frontend
flutter build linux --release
flutter build apk --release
flutter build appbundle --release
```

### Test Commands

```bash
cd frontend/test

# Run Python security validation scripts
python3 analyze_answers.py
python3 brute_force_answers.py
python3 verify_database.py
```

## Code Architecture

### Directory Structure

```
frontend/lib/
├── main.dart                 # App entry point, MultiProvider setup, AuthWrapper routing
├── models/                   # State management (Provider pattern)
│   ├── auth_state.dart       # Core auth state, session management, JWT handling
│   ├── dashboard_state.dart  # Dashboard state, credential CRUD operations
│   └── user_model.dart       # User data models
├── screens/                  # UI screens (10 screens)
│   ├── login_screen.dart
│   ├── setup_screen.dart
│   ├── main_dashboard_screen_responsive.dart  # Main dashboard (110KB+, responsive)
│   ├── settings_screen.dart
│   └── recovery_screen.dart
├── services/                 # Business logic layer (12 services)
│   ├── auth_service.dart          # Authentication, Argon2 hashing, migration
│   ├── database_service.dart      # SQLite/SQLCipher operations (1200+ lines)
│   ├── encryption_service.dart    # XOR + AES-GCM encryption
│   ├── biometric_auth_service.dart # Fingerprint/Face ID integration
│   ├── storage_service.dart       # Database metadata, flags, migrations
│   ├── argon2_service.dart        # Argon2id key derivation
│   ├── jwt_service.dart           # JWT token generation/validation
│   ├── key_derivation_service.dart # Dynamic secret derivation
│   └── credential_storage_service.dart
├── widgets/                  # Reusable UI components
└── utils/                    # Constants, helpers
```

### Service Layer Architecture

The service layer follows a dependency injection pattern where services instantiate each other as needed:

```
AuthService
├── Argon2Service (passphrase hashing)
├── KeyDerivationService (JWT secret derivation)
├── DatabaseService (encrypted storage)
└── StorageService (metadata, flags)

BiometricAuthService
└── Uses AuthService for authentication

DatabaseService
├── Uses sqflite_sqlcipher (mobile)
└── Uses sqflite_common_ffi (desktop)
```

### Authentication Flow

1. **Initial Setup:** User creates passphrase → Argon2 hashing → Store in encrypted database
2. **Login:** Passphrase → Argon2 verification → JWT token generation → Session establishment
3. **Session Management:** JWT expiration check + inactivity monitoring → Auto-logout
4. **Biometric Quick Unlock:** After passphrase auth, biometric unlocks session without re-entering passphrase

### Database Encryption Flow

```
User Passphrase
    ↓
Argon2Service.deriveKey() (per-operation salt)
    ↓
EncryptionService.deriveEncryptionKey() (XOR key derivation)
    ↓
DatabaseService.setPassphrase()
    ├→ Mobile: PRAGMA key (SQLCipher) + XOR application layer
    └→ Desktop: XOR application layer only
    ↓
Encrypted SQLite Database (credentials, projects, auth data)
```

### State Management

- **Provider Pattern:** Uses `ChangeNotifier` for reactive state updates
- **AuthState:** Single source of truth for authentication status, session data, user info
- **DashboardState:** Manages credentials, projects, filtering, search
- **ThemeService:** Manages light/dark theme switching

### Key Files and Their Purposes

| File | Purpose | Key Details |
|------|---------|-------------|
| `main.dart` | App entry, routing | MultiProvider setup, AuthWrapper decides Login vs Dashboard |
| `auth_state.dart` | Auth state management | JWT session, inactivity timer, auto-login, biometric quick unlock |
| `auth_service.dart` | Auth business logic | 700+ lines, Argon2 hashing, legacy SHA-256 migration, rate limiting |
| `database_service.dart` | Database operations | 1200+ lines, platform detection (SQLCipher vs FFI), migrations |
| `encryption_service.dart` | Encryption logic | XOR for sensitive fields, AES-GCM available |
| `argon2_service.dart` | KDF wrapper | Argon2id with configurable memory/iterations |
| `jwt_service.dart` | JWT handling | Token generation, validation, expiration checking |
| `storage_service.dart` | Metadata storage | Migration flags, settings, user preferences |

## Security Architecture

### Encryption Layers

1. **Passphrase Hashing:** Argon2id (memory-hard KDF, resistant to GPU/ASIC attacks)
2. **Database Encryption:**
   - Mobile: SQLCipher PRAGMA key (file-level) + XOR (field-level)
   - Desktop: XOR (field-level only)
3. **Dynamic Secrets:** JWT secrets derived from passphrase, not stored
4. **Biometric Keys:** Double-encrypted with XOR + additional layer

### Migration Path

- **Legacy SHA-256:** Auto-detected, verified, and migrated to Argon2 on first successful login
- **Legacy Storage:** Migrating from `shared_preferences` to encrypted database

### Security Best Practices in Code

- **Never store plaintext passphrases** - Only Argon2 hashes
- **Per-operation salt generation** - Never reuse salts
- **Rate limiting** - Login (5 attempts), Recovery (3 attempts), 5-minute lockout
- **Session timeout** - Configurable, default 30 minutes
- **Key cleanup** - Clear sensitive data from memory on logout

## Testing Strategy

### Test Categories

**Unit Tests** (`frontend/test/`):
- `auth_service_test.dart` - Authentication logic, migration, rate limiting
- `argon2_service_test.dart` - Argon2 KDF correctness
- `database_service_test.dart` - CRUD operations, encryption
- `encryption_validation_test.dart` - XOR/AES-GCM validation
- `jwt_service_test.dart` - Token generation, expiration
- `biometric_auth_test.dart` - Biometric integration (mocked)
- `dynamic_secrets_test.dart` - Dynamic secret derivation

**Integration Tests** (`frontend/integration_test/`):
- `security_e2e_test.dart` - End-to-end security flows

**Python Validation Scripts** (`frontend/test/`):
- `analyze_answers.py` - Security question analysis
- `brute_force_answers.py` - Security validation
- `verify_database.py` - Database integrity

### Test Setup Pattern

Tests mock platform channels:
- `flutter_secure_storage` method channel
- `shared_preferences` method channel
- Database cleanup between tests
- Login rate limiting reset

### Running Tests

```bash
cd frontend

# All tests
flutter test

# Specific test file
flutter test test/auth_service_test.dart

# With coverage
flutter test --coverage

# Integration tests
flutter test integration_test/security_e2e_test.dart
```

## Platform-Specific Notes

### Desktop (Linux/Windows/macOS)

- Uses `sqflite_common_ffi` for SQLite
- No SQLCipher support - relies on application-layer XOR encryption
- Window management via `window_manager` package

### Mobile (Android/iOS)

- Uses `sqflite_sqlcipher` for SQLCipher
- Double encryption: PRAGMA key + XOR application layer
- Biometric auth via `local_auth` package

## Agent OS Integration

This project uses Agent OS for feature development workflow:

- **Specs:** `.agent-os/specs/` - Feature specifications with task tracking
- **Tasks:** Each spec has a `tasks.md` file tracking implementation progress
- **Workflow:** When implementing features, follow the 3-phase execution:
  1. Pre-execution setup (context, git branch)
  2. Task execution loop
  3. Post-execution (tests, commit, update roadmap)

**Important:** When completing tasks, update the `tasks.md` file in the active spec folder.

## Common Patterns

### Adding a New Service

1. Create service in `frontend/lib/services/`
2. Use dependency injection pattern (instantiate dependencies in constructor)
3. Follow singleton or instance pattern based on statefulness
4. Add tests in `frontend/test/[service_name]_test.dart`

### Adding a New Screen

1. Create screen in `frontend/lib/screens/`
2. Add route to `main.dart` routes
3. Add navigation from appropriate existing screen
4. Follow responsive design patterns (use `ResponsiveService`)

### Database Migrations

1. Add migration logic to `database_service.dart`
2. Set migration flag in `storage_service.dart`
3. Test migration path in `database_service_test.dart`
4. Document migration in code comments

## Dependencies

### Core Flutter
- `flutter: >=3.10.0`
- `dart: '>=3.0.0 <4.0.0'`
- `provider: ^6.1.1` - State management

### Database & Encryption
- `sqflite_sqlcipher: ^3.3.0` - Mobile SQLCipher
- `sqflite_common_ffi: ^2.3.0` - Desktop SQLite
- `sqlite3_flutter_libs: ^0.5.0` - Native SQLite libraries
- `cryptography: ^2.7.0` - AES-GCM encryption
- `crypto: ^3.0.3` - SHA-256, hashing

### Authentication & Security
- `local_auth: ^2.1.6` - Biometric auth
- `flutter_secure_storage: ^8.0.0` - Platform secure storage
- `jwt_decode: ^0.3.1` - JWT parsing
- `argon2` (custom service) - Argon2id KDF

### UI & Theming
- `cupertino_icons: ^1.0.2`
- `window_manager: ^0.3.9` - Desktop window management

## Git Workflow

- **Main branch:** Check git status for current main branch
- **Feature branches:** Named after spec folder (e.g., `auth-security-overhaul`)
- **Commit after changes:** Use `git add .` and `git commit` with relevant message
- **Branch naming:** Exclude date prefix from spec folder names

## Important Notes

1. **No network code** - This is a local-only application
2. **Always use Argon2** for new passphrase hashing (never SHA-256 directly)
3. **Platform detection** - Use `DatabaseService.platform` to check mobile vs desktop
4. **Session management** - All auth operations go through `AuthState`
5. **Test security** - Always add tests for security-critical code paths
