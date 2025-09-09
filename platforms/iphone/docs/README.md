# iOS Platform Documentation

## 📦 **Distribution Formats**
- **Development**: `Runner.app` (for testing)
- **Ad-hoc**: `.ipa` for beta testing
- **App Store**: `.ipa` for App Store distribution
- **TestFlight**: `.ipa` for TestFlight distribution

## 🛠️ **Build Requirements**
- **OS**: macOS 10.15+ (for iOS builds)
- **Flutter**: Latest stable version
- **Xcode**: 12+ with iOS SDK
- **Apple Developer Account**: Required for distribution
- **iOS Device**: For testing (optional)

## 🚀 **Quick Build (On macOS)**

### **Development Build**
```bash
# Navigate to iOS build directory
cd platforms/iphone/scripts

# Run automated build
./build_ios.sh
```

### **Release Build for App Store**
```bash
cd frontend
flutter build ios --release --no-codesign
```

### **Build IPA**
```bash
cd frontend
flutter build ipa --release
```

## 📁 **Build Output Structure**

```
platforms/iphone/
├── builds/
│   ├── ExportOptions.plist     # Export configuration
│   ├── provisioning/           # Provisioning profiles
│   └── certificates/           # Code signing certificates
├── scripts/
│   ├── build_ios.sh            # Automated iOS build
│   ├── create_ipa.sh           # IPA creation script
│   └── upload_testflight.sh    # TestFlight upload
└── binaries/
    ├── Runner.app/             # iOS app bundle
    ├── app-release.ipa         # Distribution IPA ⭐
    └── testflight.ipa          # TestFlight IPA
```

## 🔧 **Manual Build Steps**

### **Step 1: Setup iOS Development**
```bash
# Install CocoaPods
sudo gem install cocoapods

# Setup iOS
flutter precache --ios

# Check iOS setup
flutter doctor -v
```

### **Step 2: Configure Xcode**
1. **Open iOS project**: `open frontend/ios/Runner.xcworkspace`
2. **Select team**: In Xcode, select your Apple Developer account
3. **Configure bundle ID**: Update to your unique bundle ID
4. **Configure provisioning**: Select development/distribution profile

### **Step 3: Build Flutter iOS**
```bash
cd frontend

# Development build
flutter build ios --debug

# Release build
flutter build ios --release
```

### **Step 4: Create IPA**
```bash
cd frontend

# Build IPA for distribution
flutter build ipa --release

# Build for TestFlight
flutter build ipa --release --export-method app-store
```

## 📱 **iOS-Specific Configuration**

### **Info.plist Configuration**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Cred Manager</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.credmanager</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>credmanager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
```

### **App Icons**
iOS requires multiple icon sizes:
- 20x20pt, 29x29pt, 40x40pt, 60x60pt (iPhone)
- 20x20pt, 29x29pt, 40x40pt, 76x76pt, 83.5x83.5pt (iPad)
- 1024x1024pt (App Store)

## 🔒 **Code Signing & Provisioning**

### **Development Signing**
```bash
# Automatic signing (Xcode)
# 1. Open ios/Runner.xcworkspace
# 2. Select your development team
# 3. Enable automatic signing
```

### **Distribution Signing**
```bash
# Manual signing for distribution
# 1. Create distribution certificate in Apple Developer
# 2. Create provisioning profile
# 3. Configure in Xcode or manually
```

### **Export Options**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0//EN">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

## 📱 **Testing iOS Package**

### **Test on Simulator**
```bash
# List available simulators
flutter emulators

# Launch specific simulator
flutter emulators --launch iPhone_14

# Run on simulator
flutter run --device-id <simulator_id>
```

### **Test on Physical Device**
```bash
# List connected devices
flutter devices

# Run on device
flutter run --release
```

### **Test IPA Installation**
```bash
# Install via Xcode
# 1. Open ios/Runner.xcworkspace
# 2. Select device
# 3. Run (Cmd+R)

# Install via TestFlight
# 1. Upload to TestFlight
# 2. Install from TestFlight app
```

## 🔧 **Troubleshooting**

### **Common Issues**

**❌ No iOS devices/simulators**
```bash
# Check connected devices
flutter devices

# Start simulator
open -a Simulator

# Reset simulator
xcrun simctl erase all
```

**❌ Code signing issues**
```bash
# Check certificates
security find-identity -v -p codesigning

# Check provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/
```

**❌ Build fails with CocoaPods**
```bash
cd frontend/ios
pod install
pod update
```

**❌ App crashes on startup**
```bash
# Check device logs
idevicesyslog

# Check Xcode console
# Xcode > Window > Devices and Simulators > View Device Logs
```

## 📋 **Package Contents Checklist**

### **✅ Must Include:**
- [ ] Flutter iOS app
- [ ] Go backend (if iOS version needed)
- [ ] Proper code signing
- [ ] App icons (all sizes)
- [ ] Launch screen
- [ ] Info.plist configured
- [ ] Privacy permissions

### **✅ Must Configure:**
- [ ] Bundle identifier
- [ ] Version numbers
- [ ] API endpoints
- [ ] iOS-specific paths
- [ ] Privacy permissions

## 📤 **Distribution**

### **TestFlight (Beta Testing)**
```bash
# Upload to TestFlight
xcrun altool --upload-app --type ios --file "build/ios/ipa/app-release.ipa" --username "your@email.com" --password "app-specific-password"
```

### **App Store (Production)**
```bash
# Upload to App Store Connect
xcrun altool --upload-app --type ios --file "build/ios/ipa/app-release.ipa" --username "your@email.com" --password "app-specific-password"

# Or use Transporter app
# 1. Download Transporter from App Store
# 2. Drag IPA file to Transporter
# 3. Deliver to App Store Connect
```

### **Ad-hoc Distribution**
```bash
# Create ad-hoc IPA
flutter build ipa --release --export-method ad-hoc

# Distribute IPA file directly
# Users install via iTunes/Finder or third-party tools
```

## 🎯 **iOS-Specific Features**

### **✅ iOS Integration:**
- iOS design language
- Face ID/Touch ID
- iCloud integration
- Siri shortcuts
- Widgets
- Notification Center
- Share extensions

### **✅ iOS Optimization:**
- Performance optimization
- Memory management
- Battery efficiency
- Offline capabilities
- Push notifications
- Background processing

## 📱 **Supported Devices**

### **iPhone**
- iPhone 6s and later (iOS 12+)
- iPhone SE (all generations)
- iPhone X and later (Face ID support)

### **iPad**
- iPad (5th generation) and later
- iPad mini (4th generation) and later
- iPad Air (3rd generation) and later
- iPad Pro (all models)

### **iPod touch**
- iPod touch (7th generation)

## 📊 **App Store Requirements**

### **Technical Requirements**
- **iOS Version**: 12.0+ (recommended 13.0+)
- **Device Types**: iPhone, iPad (Universal app)
- **Architecture**: 64-bit only
- **App Size**: Under 4GB (recommended under 500MB)

### **Content Requirements**
- **Privacy Policy**: Required
- **App Review**: May require demo account
- **Screenshots**: Required (iPhone + iPad)
- **Description**: Clear and accurate
- **Keywords**: Relevant search terms

## 📞 **Support**

### **Debug Commands**
```bash
# Device info
xcrun simctl list devices

# App info
xcrun simctl get_app_container booted com.yourcompany.credmanager

# Install app
xcrun simctl install booted build/ios/iphoneos/Runner.app

# Launch app
xcrun simctl launch booted com.yourcompany.credmanager
```

### **Log Locations**
- **Device logs**: Xcode > Window > Devices and Simulators
- **Simulator logs**: `~/Library/Logs/CoreSimulator/`
- **Crash reports**: `~/Library/Logs/DiagnosticReports/`

### **Common iOS Paths**
- **Documents**: `NSDocumentDirectory`
- **Library**: `NSLibraryDirectory`
- **Caches**: `NSCachesDirectory`
- **Application Support**: `NSApplicationSupportDirectory`

---

## 🎉 **Success Checklist**

- [ ] App builds without errors for iOS
- [ ] Code signing works correctly
- [ ] App installs and runs on target devices
- [ ] Both Go backend and Flutter frontend work (if applicable)
- [ ] Network calls succeed
- [ ] UI displays correctly on different screen sizes
- [ ] App handles iOS lifecycle properly
- [ ] App Store Connect requirements met
- [ ] TestFlight distribution works (if used)

**Now you have COMPLETE, WORKING iOS packages!** 📱