# 🔐 Credential Manager - Frontend

Flutter application for secure, local credential management with encrypted SQLite storage.

## 🏗️ **Architecture**

### **Core Components**
- **Authentication System** - Secure login with passphrase-based encryption
- **Encrypted Storage** - SQLite database with AES-256-GCM encryption
- **State Management** - Provider pattern for reactive UI updates
- **Cross-Platform UI** - Material 3 design system

### **Key Services**
- `DatabaseService` - SQLite database operations
- `EncryptionService` - AES-256-GCM encryption with Argon2 key derivation
- `CredentialStorageService` - High-level credential management
- `AuthState` - Authentication and session management
- `DashboardState` - UI state and data management

## 📁 **Project Structure**

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models and state management
│   ├── auth_state.dart      # Authentication state
│   ├── dashboard_state.dart # Dashboard UI state
│   ├── project.dart         # Project data model
│   └── ai_service.dart      # AI service data model
├── screens/                 # UI screens
│   ├── auth_wrapper.dart    # Authentication flow wrapper
│   ├── login_screen.dart    # Login interface
│   ├── main_dashboard_screen.dart # Main application interface
│   └── settings_screen.dart # Settings and preferences
├── services/                # Business logic services
│   ├── database_service.dart # SQLite operations
│   ├── encryption_service.dart # Cryptographic operations
│   └── credential_storage_service.dart # Credential management
└── utils/                   # Utilities and constants
    └── constants.dart       # Application constants
```

## 🚀 **Development Setup**

### **Prerequisites**
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher

### **Installation**
```bash
# Install dependencies
flutter pub get

# Run code generation (if needed)
flutter packages pub run build_runner build

# Run the application
flutter run
```

### **Platform-Specific Setup**

#### **Linux**
```bash
# Install required packages
sudo apt-get update
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

#### **Windows**
- Visual Studio 2022 with C++ development tools
- Windows 10 SDK

#### **macOS**
- Xcode Command Line Tools
- CocoaPods: `sudo gem install cocoapods`

## 🔧 **Configuration**

### **Dependencies**
Key dependencies in `pubspec.yaml`:
- `sqflite` - SQLite database
- `cryptography` - Encryption operations
- `provider` - State management
- `flutter_secure_storage` - Secure local storage
- `path_provider` - Platform-specific paths

### **Build Configuration**
- **Package Name:** `cred_manager`
- **Minimum SDK:** Flutter 3.10.0, Dart 3.0.0
- **Platforms:** Linux, Windows, macOS, Android, iOS

## 🧪 **Testing**

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## 🔨 **Building**

### **Development Build**
```bash
flutter run --debug
```

### **Release Build**
```bash
# Use platform-specific build scripts
cd ../platforms
./build_all.sh --linux
```

## 🛡️ **Security Implementation**

### **Encryption Details**
- **Algorithm:** AES-256-GCM
- **Key Derivation:** Argon2id (64MB memory, 1 iteration, 4 threads)
- **Unique Nonce:** Generated per encryption operation
- **Salt:** Cryptographically secure random salt per credential

### **Data Flow**
1. User enters passphrase
2. Argon2 derives encryption key from passphrase + salt
3. Credentials encrypted with AES-256-GCM before database storage
4. Decryption occurs only when displaying to user
5. Keys cleared from memory on logout

## 📱 **Platform Support**

| Platform | Status | Notes |
|----------|--------|-------|
| Linux    | ✅ Full | Native executable |
| Windows  | ✅ Full | Native executable |
| macOS    | ✅ Full | App bundle |
| Android  | ✅ Full | APK + App Bundle |
| iOS      | ✅ Full | Requires code signing |

## 🐛 **Debugging**

### **Common Issues**
- **Database errors:** Check file permissions and storage paths
- **Encryption failures:** Verify passphrase and key derivation
- **UI state issues:** Check Provider setup and notifyListeners calls

### **Debug Tools**
```bash
# Flutter inspector
flutter inspector

# Debug console
flutter logs

# Performance profiling
flutter run --profile
```

## 📚 **Resources**

- [Flutter Documentation](https://docs.flutter.dev/)
- [Material 3 Design](https://m3.material.io/)
- [Provider State Management](https://pub.dev/packages/provider)
- [SQLite Documentation](https://www.sqlite.org/docs.html)

---

**Secure credential management with Flutter** 🔐
