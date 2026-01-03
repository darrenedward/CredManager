# 🔐 Cred Manager

A secure, local-only credential manager built with Flutter and encrypted SQLite storage.

## 🌟 **Features**

### **🔒 Security First**
- **SQLCipher Database** - AES-256 encrypted SQLite database for all stored data
- **Argon2id Key Derivation** - Secure passphrase-based encryption with memory-hard hashing
- **Zero Plaintext Storage** - All sensitive data encrypted at rest
- **Local-Only Operation** - No network dependencies, completely offline
- **Biometric Authentication** - Fingerprint/unlock support on supported platforms
- **Security Questions** - Configurable recovery questions for account recovery
- **Emergency Backup Codes** - BIP39/Base32 one-time backup codes for recovery
- **Rate Limiting** - Brute force protection with configurable lockout
- **Session Management** - Secure JWT-based sessions with automatic expiry

### **📱 Cross-Platform**
- **Desktop:** Linux (native + .deb), Windows (MSI + EXE), macOS
- **Mobile:** Android (APK + AAB), iOS
- **Single Codebase** - Flutter for consistent experience across platforms
- **CI/CD Builds** - GitHub Actions automated builds for all platforms

### **💾 Data Management**
- **Projects & Credentials** - Organize API keys, passwords, and connection strings
- **AI Service Keys** - Manage API keys for various AI services
- **Encrypted Export/Import** - Secure data portability
- **Search & Filter** - Quick access to your credentials
- **Emergency Kits** - PDF generation for offline backup storage

### **🎨 Modern UI**
- **Material 3 Design** - Clean, modern interface
- **Dark/Light Themes** - Automatic theme switching
- **Responsive Layout** - Optimized for all screen sizes
- **Animated Transitions** - Smooth, polished user experience

## 🏗️ **Project Structure**

```
CredManager/
├── .github/workflows/  # GitHub Actions CI/CD
│   └── build-flutter-app.yml
├── frontend/           # Flutter application
│   ├── lib/            # Application source code
│   │   ├── models/     # Data models (AuthState, DashboardState)
│   │   ├── services/   # Business logic services
│   │   ├── screens/    # UI screens (Setup, Login, Dashboard, etc.)
│   │   ├── widgets/    # Reusable UI components
│   │   └── utils/      # Utilities (validation, constants)
│   ├── assets/         # Images, fonts, and resources
│   ├── integration_test/ # End-to-end tests
│   └── test/           # Unit tests
├── platforms/          # Platform-specific build scripts
├── docs/              # Documentation
└── README.md
```

## 🚀 **Quick Start**

### **Installation**

#### **Linux (Debian/Ubuntu)**
```bash
# Download .deb package from releases
sudo dpkg -i cred-manager_1.0.0_amd64.deb
sudo apt-get install -f  # Install dependencies if needed
```

#### **Windows**
- **MSI Installer**: Download and run `cred-manager-windows-x64.msi`
- **EXE Installer**: Download and run `cred-manager-windows-x64-setup.exe`

#### **macOS**
- Download and extract `cred-manager-macos-x64.zip`
- Drag `Cred Manager.app` to Applications folder

#### **Android**
- Download `app-release.apk` from releases
- Install and enable "Install from unknown sources"

### **First Launch**
1. **Create Master Passphrase** - Must be 12+ characters with mixed case, numbers, and symbols
2. **Setup Security Questions** - Choose 3 questions and answers for recovery
3. **Enable Biometric Auth** (optional) - Fingerprint/unlock for quick access
4. **Generate Emergency Kit** - Create backup codes for account recovery
5. **Start Adding Credentials** - Organize by project or category

## 🔧 **Development**

### **Prerequisites**
- Flutter SDK 3.27.0 or higher
- Dart SDK 3.6.0 or higher
- Platform-specific development tools:
  - **Linux**: `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`
  - **Windows**: Visual Studio 2022 with C++ desktop development
  - **macOS**: Xcode 15+ and CocoaPods
  - **Android**: Java 17 and Android SDK
  - **iOS**: Xcode 15+ and CocoaPods

### **Setup**
```bash
# Clone the repository
git clone https://github.com/darrenedward/CredManager.git
cd CredManager/frontend

# Install dependencies
flutter pub get

# Run in development mode
flutter run -d linux    # Linux
flutter run -d windows  # Windows
flutter run -d macos    # macOS
flutter run            # Android/iOS (if connected)
```

### **Running Tests**
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test

# E2E security tests
flutter test integration_test/security_e2e_test.dart
```

### **Building Locally**
```bash
# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (requires code signing)
flutter build ios --release
```

## 🛡️ **Security Architecture**

### **Database Encryption**
- **SQLCipher**: AES-256 encrypted SQLite database
- **Key Derivation**: Argon2id with configurable parameters
  - Memory: 64MB (configurable)
  - Time cost: 3 iterations
  - Parallelism: 4 threads
- **Per-Record Encryption**: Additional XOR layer for sensitive fields
- **Salt Management**: Unique salts per encryption operation

### **Authentication Flow**
```
┌─────────────────┐
│  User Enters    │
│  Passphrase     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐       ┌──────────────────┐
│  Argon2id KDF   │──────▶│  Database Key    │
│  (salt + params)│       │  (256-bit)       │
└─────────────────┘       └────────┬─────────┘
                                   │
                                   ▼
                          ┌──────────────────┐
                          │  SQLCipher DB    │
                          │  (AES-256-GCM)   │
                          └──────────────────┘
```

### **Recovery Mechanisms**
1. **Security Questions** - 3 configurable questions with hashed answers
2. **Emergency Backup Codes** - BIP39 (24 words) or Base32 format
   - One-time use codes
   - Stored with SHA-256 hash
   - Can be regenerated (invalidates old codes)

### **Rate Limiting**
- **Failed Login Tracking**: Monitors failed authentication attempts
- **Progressive Delays**: Increasing lockout durations
- **Configurable Threshold**: Default 5 failed attempts
- **Account Recovery**: Via security questions or backup codes

## 📚 **Documentation**

| Document | Description |
|----------|-------------|
| [Security Architecture](docs/security/ARCHITECTURE.md) | Detailed security design |
| [API Reference](docs/api.md) | Internal API documentation |
| [Testing Guide](docs/testing/TESTING.md) | Test coverage and strategies |
| [Deployment](docs/deployment/DEPLOYMENT.md) | Build and release process |

## 🔄 **CI/CD**

GitHub Actions automatically builds all platforms on push:
- **Triggers**: Push to `main`, `develop`, `auth-security-overhaul`
- **Artifacts**: Available for 30 days from Actions page
- **Releases**: Tagged releases create permanent artifacts

### **Build Artifacts**
| Platform | Formats |
|----------|---------|
| Linux | `.tar.gz`, `.deb` |
| Windows | `.zip`, `.msi`, `.exe` |
| macOS | `.zip` |
| Android | `.apk`, `.aab` |
| iOS | `.zip` (unsigned) |

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Ensure all tests pass (`flutter test`)
6. Run E2E security tests
7. Submit a pull request

### **Code Style**
- Follow Flutter/Dart style guide
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep files under 500 lines (split when needed)

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **Flutter Team** - Excellent cross-platform framework
- **SQLCipher** - Encrypted SQLite database
- **Argon2** - Secure key derivation
- **BIP39** - Mnemonic code standard for backup codes

---

**Built with ❤️ for secure credential management**

**Repository**: https://github.com/darrenedward/CredManager
