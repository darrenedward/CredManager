# 🔐 Credential Manager

A secure, local-only credential manager built with Flutter and encrypted SQLite storage.

## 🌟 **Features**

### **🔒 Security First**
- **AES-256-GCM Encryption** - Military-grade encryption for all credentials
- **Argon2 Key Derivation** - Secure passphrase-based encryption keys  
- **Zero Plaintext Storage** - All sensitive data encrypted at rest
- **Local-Only Operation** - No network dependencies, completely offline

### **📱 Cross-Platform**
- **Desktop:** Linux, Windows, macOS
- **Mobile:** Android, iOS
- **Single Codebase** - Flutter for consistent experience across platforms

### **💾 Data Management**
- **Projects & Credentials** - Organize API keys, passwords, and connection strings
- **AI Service Keys** - Manage API keys for various AI services
- **Export/Import** - JSON-based data portability with encryption
- **Search & Filter** - Quick access to your credentials

### **🎨 Modern UI**
- **Material 3 Design** - Clean, modern interface
- **Dark/Light Themes** - Automatic theme switching
- **Responsive Layout** - Optimized for all screen sizes
- **Inline Editing** - Quick credential updates

## 🏗️ **Project Structure**

```
APIKeyManager/
├── frontend/          # Flutter application
│   ├── lib/          # Application source code
│   ├── assets/       # Images, fonts, and resources
│   └── pubspec.yaml  # Dependencies and configuration
└── platforms/        # Build system and deployment
    ├── build_all.sh  # Master build script
    ├── linux/        # Linux builds and packaging
    ├── windows/      # Windows builds and packaging
    ├── macos/        # macOS builds and packaging
    ├── android/      # Android builds and packaging
    └── iphone/       # iOS builds and packaging
```

## 🚀 **Quick Start**

### **Prerequisites**
- Flutter SDK 3.10.0 or higher
- Platform-specific development tools (see platform docs)

### **Development Setup**
```bash
# Clone the repository
git clone <repository-url>
cd APIKeyManager

# Install Flutter dependencies
cd frontend
flutter pub get

# Run in development mode
flutter run
```

### **Building for Production**
```bash
# Build for all platforms
cd platforms
./build_all.sh

# Build for specific platform
./build_all.sh --linux
./build_all.sh --android --ios
```

## 📦 **Installation**

### **From Releases**
1. Download the appropriate build for your platform from the releases page
2. Extract and run the executable
3. Create your master passphrase on first launch

### **From Source**
See the [platforms README](platforms/README.md) for detailed build instructions.

## 🔧 **Usage**

1. **First Launch:** Create a secure master passphrase
2. **Add Projects:** Organize your credentials by project
3. **Store Credentials:** Add API keys, passwords, connection strings
4. **Manage AI Services:** Store and organize AI service API keys
5. **Export/Backup:** Use the export feature for data portability

## 🛡️ **Security Architecture**

### **Encryption Details**
- **Algorithm:** AES-256-GCM with unique nonce per record
- **Key Derivation:** Argon2id with 64MB memory, 1 iteration, 4 threads
- **Salt Generation:** Cryptographically secure random salts
- **Database:** SQLite with encrypted credential storage

### **Security Best Practices**
- Master passphrase never stored in plaintext
- Encryption keys derived fresh from passphrase on each session
- Secure memory handling with automatic key cleanup
- No network communication eliminates remote attack vectors

## 📚 **Documentation**

- [Platform Builds](platforms/README.md) - Build system and deployment
- [Frontend Development](frontend/README.md) - Flutter app development
- [Security Architecture](docs/security.md) - Detailed security documentation
- [API Documentation](docs/api.md) - Internal API reference

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- Flutter team for the excellent cross-platform framework
- SQLite for reliable local database storage
- Argon2 and AES-GCM for robust cryptographic primitives

---

**Built with ❤️ for secure credential management**
