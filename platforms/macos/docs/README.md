# macOS Platform Documentation

## 📦 **Distribution Formats**
- **Primary**: `CredManager-macOS.dmg` (DMG installer)
- **Alternative**: `CredManager-macOS.zip` (ZIP archive)
- **App Store**: `.pkg` installer (for App Store distribution)

## 🛠️ **Build Requirements**
- **OS**: macOS 10.15+ (Catalina or later)
- **Flutter**: Latest stable version
- **Xcode**: 12+ with command line tools
- **Go**: Latest version for backend
- **Optional**: create-dmg (for DMG creation)

## 🚀 **Quick Build (On macOS)**

### **Automated Build**
```bash
# Navigate to macOS build directory
cd platforms/macos/scripts

# Make script executable
chmod +x build_macos.sh

# Run automated build
./build_macos.sh
```

### **Universal App (Intel + Apple Silicon)**
```bash
# Build universal binary
./scripts/create_universal_app.sh
```

## 📁 **Build Output Structure**

```
platforms/macos/
├── builds/
│   ├── app_template/           # App bundle template
│   └── dmg_config/            # DMG creation config
├── scripts/
│   ├── build_macos.sh         # Automated build script
│   └── create_universal_app.sh # Universal binary creator
└── binaries/
    ├── Cred Manager.app/      # Complete app bundle ⭐
    ├── server                 # Go backend binary
    └── startup.sh             # Launch script
```

## 🔧 **Manual Build Steps**

### **Step 1: Enable macOS Desktop**
```bash
flutter config --enable-macos-desktop
```

### **Step 2: Build Go Backend**
```bash
cd backend

# For current architecture
go build -o server ./cmd/server

# For Intel (x86_64)
GOARCH=amd64 go build -o server-intel ./cmd/server

# For Apple Silicon (arm64)
GOARCH=arm64 go build -o server-arm64 ./cmd/server
```

### **Step 3: Build Flutter Frontend**
```bash
cd frontend
flutter build macos --release
```

### **Step 4: Create App Bundle**
```bash
# Copy Flutter app
cp -r frontend/build/macos/Build/Products/Release/Cred\ Manager.app dist/

# Copy Go backend
cp backend/server dist/Cred\ Manager.app/Contents/MacOS/

# Create startup script
# (Handled by build script)
```

## 📦 **Creating Professional Distribution**

### **DMG Installer (Recommended)**
```bash
# Install create-dmg
brew install create-dmg

# Create DMG
create-dmg \
  --volname "Cred Manager" \
  --volicon "Cred Manager.app/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "Cred Manager.app" 200 190 \
  --hide-extension "Cred Manager.app" \
  --app-drop-link 600 185 \
  "CredManager-macOS.dmg" \
  "Cred Manager.app"
```

### **ZIP Archive (Simple)**
```bash
cd dist
zip -r ../CredManager-macOS.zip "Cred Manager.app"
```

## 🧪 **Testing macOS Package**

### **Test App Bundle**
```bash
# Test app bundle
open "dist/Cred Manager.app"

# Or from Applications after installation
open -a "Cred Manager"
```

### **Test DMG**
```bash
# Open DMG
open CredManager-macOS.dmg

# Drag to Applications
# Launch from Applications
# Verify all features work
```

## 🔧 **Troubleshooting**

### **Common Issues**

**❌ "build macos" only supported on macOS**
- Must build on macOS machine
- Flutter cannot cross-compile macOS apps

**❌ Xcode not found**
```bash
# Install Xcode from App Store
# Install command line tools
xcode-select --install

# Accept Xcode license
sudo xcodebuild -license accept
```

**❌ App won't open after build**
```bash
# Remove quarantine
xattr -rd com.apple.quarantine "Cred Manager.app"

# Or right-click and select "Open"
```

**❌ Go build fails**
```bash
# Check architecture
uname -m  # Should show arm64 or x86_64

# Build for correct architecture
GOARCH=arm64 go build -o server ./cmd/server
```

## 📋 **Package Contents Checklist**

### **✅ Must Include:**
- [ ] Go backend server binary
- [ ] Flutter app bundle (.app)
- [ ] Startup script
- [ ] Configuration files
- [ ] Database migrations
- [ ] Icon files
- [ ] Info.plist (properly configured)

### **✅ Must Configure:**
- [ ] Bundle identifier
- [ ] Version information
- [ ] API endpoints
- [ ] File paths (macOS specific)
- [ ] Code signing (optional)

## 📤 **Distribution**

### **DMG Package**
- **File**: `CredManager-macOS.dmg`
- **Size**: ~50-100MB
- **Installation**: Drag to Applications
- **Gatekeeper**: May need to bypass on first run

### **ZIP Package**
- **File**: `CredManager-macOS.zip`
- **Size**: ~30-80MB
- **Installation**: Extract and run
- **No special permissions required**

## 🎯 **macOS-Specific Features**

### **✅ macOS Integration:**
- Dock integration
- Spotlight indexing
- Notification Center
- System Preferences
- Keychain integration
- Dark mode support

### **✅ macOS Optimization:**
- Native performance
- Memory management
- Battery optimization
- Retina display support
- Accessibility features

## 🔒 **Code Signing (Optional but Recommended)**

### **For Development**
```bash
# Sign with development certificate
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" "Cred Manager.app"
```

### **For Distribution**
```bash
# Sign for distribution
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" "Cred Manager.app"

# Verify signature
codesign --verify --verbose "Cred Manager.app"
```

### **Notarization (App Store)**
```bash
# Create ZIP for notarization
ditto -c -k --keepParent "Cred Manager.app" CredManager.zip

# Submit for notarization
xcrun notarytool submit CredManager.zip --keychain-profile "YourProfile" --wait

# Staple notarization ticket
xcrun stapler staple "Cred Manager.app"
```

## 📞 **Support**

### **Debug Commands**
```bash
# Check running processes
ps aux | grep "Cred Manager"

# Check app logs
log show --predicate 'process == "Cred Manager"' --last 1h

# Check system logs
log stream --predicate 'process == "Cred Manager"'
```

### **Log Locations**
- **Application logs**: `~/Library/Logs/Cred Manager/`
- **System logs**: `/var/log/system.log`
- **Crash reports**: `~/Library/Logs/DiagnosticReports/`

### **Common macOS Paths**
- **Application Support**: `~/Library/Application Support/Cred Manager/`
- **Preferences**: `~/Library/Preferences/`
- **Caches**: `~/Library/Caches/Cred Manager/`

---

## 🎉 **Success Checklist**

- [ ] App bundle builds without errors
- [ ] Both Go backend and Flutter frontend included
- [ ] Startup script launches both components
- [ ] macOS integration works (Dock, menus)
- [ ] Application functions completely
- [ ] Works on target macOS versions
- [ ] Code signing works (if enabled)
- [ ] Gatekeeper accepts the app

**Now you have COMPLETE, WORKING macOS packages!** 🍎