# API Key Manager - Setup Requirements

## System Requirements

### Flutter SDK
- **Flutter**: >= 3.10.0
- **Dart SDK**: >= 3.0.0 < 4.0.0

### Platform Support
- **Linux**: Ubuntu 18.04+ / Debian 10+ / Fedora 30+ / Arch Linux
- **Windows**: Windows 10 (1903+) / Windows 11
- **macOS**: macOS 10.14+ (Mojave)
- **Android**: API Level 21+ (Android 5.0)
- **iOS**: iOS 12.0+

## Core Dependencies

### Database & Encryption
```yaml
dependencies:
  # SQLCipher for mobile platforms (Android/iOS)
  sqflite_sqlcipher: ^3.3.0
  
  # SQLite FFI for desktop platforms (Linux/Windows/macOS)
  sqflite_common_ffi: ^2.3.0
  sqlite3_flutter_libs: ^0.5.0
  
  # Cryptography and encryption libraries
  cryptography: ^2.7.0
  crypto: ^3.0.3
  hex: ^0.2.0
  convert: ^3.1.1
```

### Authentication & Security
```yaml
dependencies:
  # Biometric authentication
  local_auth: ^2.1.6
  
  # Legacy storage (being migrated to encrypted database)
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^8.0.0
  
  # JWT token handling
  jwt_decode: ^0.3.1
```

### Utilities
```yaml
dependencies:
  # Path and file system utilities
  path: ^1.8.3
  path_provider: ^2.1.1
  
  # HTTP client for API communication
  http: ^1.1.0
  
  # State management
  provider: ^6.1.1
```

## Platform-Specific Requirements

### Linux Desktop
**Required System Libraries:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
  libsqlite3-dev \
  libsecret-1-dev \
  libjsoncpp-dev \
  libgtk-3-dev \
  libblkid-dev \
  liblzma-dev

# Fedora/RHEL
sudo dnf install -y \
  sqlite-devel \
  libsecret-devel \
  jsoncpp-devel \
  gtk3-devel \
  libblkid-devel \
  xz-devel

# Arch Linux
sudo pacman -S \
  sqlite \
  libsecret \
  jsoncpp \
  gtk3 \
  util-linux \
  xz
```

**Generated Plugin Configuration:**
- `sqlite3_flutter_libs` - Provides SQLite3 native libraries
- `flutter_secure_storage_linux` - Secure storage implementation

### Windows Desktop
**Required Components:**
- Visual Studio Build Tools 2019 or later
- Windows SDK 10.0.17763.0 or later
- SQLite3 (bundled with `sqlite3_flutter_libs`)

### macOS Desktop
**Required Components:**
- Xcode 12.0 or later
- macOS deployment target: 10.14+
- SQLite3 (bundled with system)

### Android
**Required Components:**
- Android SDK API Level 21+
- NDK r21 or later (for SQLCipher native compilation)
- Gradle 7.0+

**SQLCipher Integration:**
- Native SQLCipher library compilation
- Proguard rules for encryption classes
- Keystore access for biometric authentication

### iOS
**Required Components:**
- Xcode 12.0+
- iOS deployment target: 12.0+
- CocoaPods 1.10+

**SQLCipher Integration:**
- Native SQLCipher framework
- Keychain access for secure storage
- Biometric authentication frameworks

## Database Encryption Architecture

### Cross-Platform Strategy
The application uses a **dual-encryption approach** for maximum compatibility:

#### Mobile Platforms (Android/iOS)
- **File-level encryption**: SQLCipher with PRAGMA key
- **Application-layer encryption**: XOR encryption for sensitive fields
- **Double encryption**: Biometric keys use both layers

#### Desktop Platforms (Linux/Windows/macOS)
- **Application-layer encryption**: XOR encryption only
- **Platform compatibility**: Uses `sqflite_common_ffi` instead of SQLCipher
- **Security equivalence**: Provides same security level through application-layer encryption

### Encryption Details
- **Key Derivation**: Argon2id with user passphrase
- **Encryption Algorithm**: XOR encryption with passphrase-derived keys
- **Salt Generation**: Cryptographically secure random salts
- **Key Storage**: Never stored in plaintext, always derived on-demand

## Installation Instructions

### 1. Clone Repository
```bash
git clone <repository-url>
cd APIKeyManager/frontend
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Verify Dependencies
```bash
# Run dependency verification script
dart scripts/verify_dependencies.dart

# Should output: ✅ All dependencies verified successfully!
```

### 4. Platform Setup

#### Linux
```bash
# Install system dependencies (see Linux section above)
sudo apt-get install libsqlite3-dev libsecret-1-dev libgtk-3-dev

# Enable Linux desktop support
flutter config --enable-linux-desktop

# Build for Linux
flutter build linux
```

#### Windows
```bash
# Enable Windows desktop support
flutter config --enable-windows-desktop

# Build for Windows
flutter build windows
```

#### macOS
```bash
# Enable macOS desktop support
flutter config --enable-macos-desktop

# Build for macOS
flutter build macos
```

#### Android
```bash
# Build for Android
flutter build apk
# OR for release
flutter build appbundle
```

#### iOS
```bash
# Build for iOS (requires macOS and Xcode)
flutter build ios
```

## Testing

### Run All Tests
```bash
# Unit and integration tests
flutter test

# Specific test suites
flutter test test/services/storage_service_encrypted_test.dart
flutter test test/encryption_validation_test.dart
flutter test test/database_service_test.dart
```

### Platform-Specific Testing
```bash
# Linux
flutter test --device-id linux

# Windows  
flutter test --device-id windows

# macOS
flutter test --device-id macos
```

## Troubleshooting

### Common Issues

#### SQLCipher Plugin Not Found (Linux)
```bash
# Solution: Install sqlite3 development libraries
sudo apt-get install libsqlite3-dev

# Rebuild Flutter
flutter clean
flutter pub get
```

#### Missing Secure Storage (Linux)
```bash
# Solution: Install libsecret
sudo apt-get install libsecret-1-dev

# Restart application
```

#### Database Permissions Error
```bash
# Solution: Check directory permissions
chmod 755 ~/.api_key_manager/
chmod 644 ~/.api_key_manager/api_key_manager.db
```

#### Test Environment Issues
- SharedPreferences plugin not available in test environment (expected)
- Some encryption tests may fail due to platform-specific implementations
- Use `flutter test --timeout=60s` for encryption-heavy tests

## Security Notes

### Development vs Production
- **Development**: Uses test passphrases and relaxed security
- **Production**: Enforces strong passphrases and full encryption
- **Testing**: Some security features disabled for test automation

### Data Protection
- **No plaintext storage**: All sensitive data encrypted
- **Memory protection**: Secure memory clearing on app termination  
- **Key derivation**: Uses Argon2id with secure parameters
- **Platform security**: Leverages OS-level security features

### Migration Strategy
- **Legacy detection**: Automatic detection of unencrypted data
- **Secure migration**: Encrypted transfer of existing data
- **Backup creation**: Automatic backups before migration
- **Rollback support**: Ability to restore from backups if needed

## Performance Expectations

### Encryption Performance
- **Key derivation**: ~100-500ms (depends on Argon2 parameters)
- **Data encryption**: <10ms per operation
- **Database operations**: <50ms per query
- **Bulk operations**: <5 seconds for 1000+ records

### Memory Usage
- **Base application**: ~50-100MB
- **Database cache**: ~10-20MB
- **Encryption operations**: +5-10MB temporary
- **Peak usage**: <150MB total

## Version Compatibility

### Minimum Versions
- Flutter: 3.10.0
- Dart: 3.0.0
- Android: API 21 (Android 5.0)
- iOS: 12.0
- Linux: Ubuntu 18.04 / equivalent
- Windows: Windows 10 (1903)
- macOS: 10.14 (Mojave)

### Tested Versions
- Flutter: 3.16.x, 3.19.x, 3.22.x
- Dart: 3.0.x, 3.2.x, 3.4.x
- All supported platform versions