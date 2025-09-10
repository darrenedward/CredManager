# Credential Manager - Platform Builds

## 🏗️ **Project Structure**

```
APIKeyManager/
├── frontend/          # Flutter application with encrypted SQLite storage
├── platforms/         # Platform-specific builds & deployment ⭐
│   ├── build_all.sh   # Master build script for all platforms
│   ├── linux/
│   │   ├── docs/      # Linux documentation & deployment guides
│   │   ├── builds/    # Build artifacts & release packages
│   │   ├── binaries/  # Final executables & installers
│   │   └── scripts/   # Platform-specific build scripts
│   ├── windows/
│   │   ├── docs/      # Windows documentation & deployment guides
│   │   ├── builds/    # Build artifacts & release packages
│   │   ├── binaries/  # Final executables & installers
│   │   └── scripts/   # Platform-specific build scripts
│   ├── macos/
│   │   ├── docs/      # macOS documentation & deployment guides
│   │   ├── builds/    # Build artifacts & release packages
│   │   ├── binaries/  # Final executables & installers
│   │   └── scripts/   # Platform-specific build scripts
│   ├── iphone/
│   │   ├── docs/      # iOS documentation & deployment guides
│   │   ├── builds/    # Build artifacts & release packages
│   │   ├── binaries/  # Final executables & installers
│   │   └── scripts/   # Platform-specific build scripts
│   └── android/
│       ├── docs/      # Android documentation & deployment guides
│       ├── builds/    # Build artifacts & release packages
│       ├── binaries/  # Final executables & installers
│       └── scripts/   # Platform-specific build scripts
└── docs/             # General documentation
```

## � **Architecture: Local-Only Encrypted Credential Manager**

**✅ CURRENT ARCHITECTURE:** Self-contained Flutter application with:

1. **Encrypted SQLite Database** - Local storage with AES-256-GCM encryption
2. **Argon2 Key Derivation** - Secure passphrase-based encryption keys
3. **Cross-Platform Support** - Single codebase for all platforms
4. **No Network Dependencies** - Completely offline, local-only operation

### **Security Features:**
- All credentials encrypted at rest using military-grade encryption
- Zero plaintext storage of sensitive data
- Secure memory handling and key lifecycle management
- No network communication required (similar to KeePass model)

## 🛠️ **Building for All Platforms**

### **Quick Start - Build All Platforms**
```bash
# From the platforms directory
./build_all.sh

# Or build specific platforms
./build_all.sh --linux --android
./build_all.sh --windows
./build_all.sh --macos --ios
```

### **Manual Platform Builds**
```bash
# Linux
./linux/scripts/build.sh

# Windows (run on Windows or with Wine)
./windows/scripts/build.bat

# macOS (requires macOS)
./macos/scripts/build.sh

# Android
./android/scripts/build.sh

# iOS (requires macOS + Xcode)
./iphone/scripts/build.sh
```

### **Build Output Structure**
Each build creates timestamped releases:
```
platforms/[platform]/builds/
├── release_20240310_143022/    # Timestamped build
│   ├── [platform_files]       # Platform-specific executables
│   └── build_info.txt         # Build metadata
└── latest -> release_20240310_143022/  # Symlink to latest
```

## 📦 **Platform-Specific Outputs**

### **Linux (Executable Bundle)**
```
platforms/linux/builds/release_[timestamp]/
├── cred_manager                    # Main executable
├── lib/                           # Flutter engine libraries
├── data/                          # Flutter assets & resources
└── build_info.txt                 # Build metadata
```

### **Windows (Executable Bundle)**
```
platforms/windows/builds/release_[timestamp]/
├── cred_manager.exe               # Main executable
├── flutter_windows.dll           # Flutter engine
├── data/                          # Flutter assets & resources
└── build_info.txt                # Build metadata
```

### **macOS (App Bundle)**
```
platforms/macos/builds/release_[timestamp]/
├── Cred Manager.app/              # Complete macOS app bundle
│   ├── Contents/
│   │   ├── MacOS/cred_manager     # Executable
│   │   ├── Frameworks/            # Flutter framework
│   │   └── Resources/             # App resources
└── build_info.txt                # Build metadata
```

### **Android (APK + App Bundle)**
```
platforms/android/builds/release_[timestamp]/
├── cred_manager_[timestamp].apk   # Android APK for sideloading
├── cred_manager_[timestamp].aab   # App Bundle for Play Store
└── build_info.txt                # Build metadata
```

### **iOS (App Bundle)**
```
platforms/iphone/builds/release_[timestamp]/
├── Runner.app/                    # iOS app bundle (unsigned)
└── build_info.txt                # Build metadata
```

## 🚀 **Quick Start Guide**

### **Build All Platforms (Recommended):**
```bash
cd platforms
./build_all.sh
```

### **Build Specific Platform:**
```bash
cd platforms

# Linux
./linux/scripts/build.sh

# Windows (requires Windows or Wine)
./windows/scripts/build.bat

# macOS (requires macOS)
./macos/scripts/build.sh

# Android
./android/scripts/build.sh

# iOS (requires macOS + Xcode)
./iphone/scripts/build.sh
```

### **Prerequisites:**
- **Flutter SDK** (3.10.0 or higher)
- **Platform-specific tools:**
  - Linux: Standard build tools
  - Windows: Visual Studio Build Tools
  - macOS: Xcode Command Line Tools
  - Android: Android SDK
  - iOS: Xcode (macOS only)

## 📋 **Build Verification Checklist**

### **✅ Build Artifacts:**
- [ ] Platform-specific executable created
- [ ] Flutter engine libraries included
- [ ] App assets and resources bundled
- [ ] Build metadata generated
- [ ] Timestamped build directory created
- [ ] Latest symlink updated

### **✅ Functionality Test:**
- [ ] Application launches successfully
- [ ] Authentication system works
- [ ] Database encryption functional
- [ ] CRUD operations for credentials work
- [ ] Export/import functionality works
- [ ] UI responsive and functional

## 🔧 **Common Issues & Solutions**

### **Build Failures:**
- **Problem:** Flutter build fails
- **Solution:** Ensure Flutter SDK is properly installed and updated
- **Check:** `flutter doctor -v`

### **Permission Denied:**
- **Problem:** Can't execute build scripts
- **Solution:** Make scripts executable
- **Fix:** `chmod +x platforms/*/scripts/*.sh`

### **Missing Platform Tools:**
- **Problem:** Platform-specific build tools not found
- **Solution:** Install required development tools for target platform
- **Check:** Platform-specific documentation in each platform's docs/ folder

### **Database Issues:**
- **Problem:** SQLite database errors
- **Solution:** Ensure proper file permissions and storage paths
- **Check:** Application logs and database file accessibility

## 🎯 **Testing Built Applications**

### **Test Checklist:**
1. **Launch application** - Verify executable starts correctly
2. **Test authentication** - Create account and login
3. **Test encryption** - Verify data is encrypted in database
4. **Test CRUD operations** - Create, read, update, delete credentials
5. **Test export/import** - Verify data portability
6. **Test UI responsiveness** - Check all screens and interactions

### **Debug Commands:**
```bash
# Check application processes
ps aux | grep cred_manager

# Check database file (should be encrypted)
file ~/.local/share/cred_manager/database.db

# Check application logs (if available)
tail -f ~/.local/share/cred_manager/logs/app.log
```

## 📤 **Distribution Ready Builds**

After successful builds, you'll have:
- **Linux:** `platforms/linux/builds/latest/` - Executable bundle
- **Windows:** `platforms/windows/builds/latest/` - Executable bundle
- **macOS:** `platforms/macos/builds/latest/` - App bundle
- **Android:** `platforms/android/builds/latest/` - APK and App Bundle
- **iOS:** `platforms/iphone/builds/latest/` - App bundle (unsigned)

**These builds are COMPLETE, SECURE, and FUNCTIONAL!** 🎉

---

## 🚨 **Important Notes**

1. **Local-only operation** - No network dependencies or server requirements
2. **Encrypted storage** - All sensitive data encrypted with AES-256-GCM
3. **Cross-platform** - Single codebase builds for all platforms
4. **Self-contained** - No external dependencies beyond Flutter runtime
5. **Test thoroughly** - Verify encryption and data persistence

**Production-ready encrypted credential manager!** ✨