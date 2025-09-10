# Android Platform Documentation

## 📦 **Distribution Formats**
- **Primary**: `app-release.apk` (APK for sideloading)
- **Alternative**: `app-release.aab` (AAB for Google Play)
- **Debug**: `app-debug.apk` (for testing)

## 🛠️ **Build Requirements**
- **OS**: Linux, macOS, or Windows
- **Flutter**: Latest stable version
- **Android SDK**: API level 21+ (Android 5.0+)
- **Java**: JDK 11 or later
- **Android Studio**: Optional but recommended

## 🚀 **Quick Build**

### **APK Build (Universal)**
```bash
# Navigate to Android build directory
cd platforms/android/scripts

# Run automated build
./build_android.sh
```

### **AAB Build (Google Play)**
```bash
cd frontend
flutter build appbundle --release
```

### **Debug Build (Testing)**
```bash
cd frontend
flutter build apk --debug
```

## 📁 **Build Output Structure**

```
platforms/android/
├── builds/
│   ├── key.properties       # Signing configuration
│   ├── keystore.jks         # Release keystore
│   └── play-store/          # Google Play assets
├── scripts/
│   ├── build_android.sh     # Automated APK build
│   └── sign_apk.sh          # APK signing script
└── binaries/
    ├── app-release.apk      # Signed release APK ⭐
    ├── app-release.aab      # Android App Bundle
    └── app-debug.apk        # Debug APK
```

## 🔧 **Manual Build Steps**

### **Step 1: Configure Android**
```bash
# Check Android setup
flutter doctor --android-licenses

# Accept Android licenses
flutter doctor --android-licenses
```

### **Step 2: Configure Android Build**
```bash
cd frontend

# Ensure Android is enabled
flutter config --enable-android

# Check Android setup
flutter doctor --android-licenses
```

### **Step 3: Build Flutter APK**
```bash
cd frontend

# Build release APK
flutter build apk --release

# Build app bundle for Play Store
flutter build appbundle --release
```

### **Step 4: Sign APK (Required for Release)**
```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Sign APK
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore upload-keystore.jks build/app/outputs/flutter-apk/app-release-unsigned.apk upload

# Align APK
zipalign -v 4 build/app/outputs/flutter-apk/app-release-unsigned.apk build/app/outputs/flutter-apk/app-release.apk
```

## 📱 **Android-Specific Configuration**

### **AndroidManifest.xml**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:label="Cred Manager"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### **Build Configuration**
```gradle
// android/app/build.gradle
android {
    compileSdkVersion 33
    minSdkVersion 21
    targetSdkVersion 33

    defaultConfig {
        applicationId "com.yourcompany.credmanager"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## 📦 **Creating Signed Release**

### **Step 1: Create Keystore**
```bash
# Create keystore directory
mkdir -p platforms/android/builds

# Generate keystore
keytool -genkey -v -keystore platforms/android/builds/upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

### **Step 2: Configure Signing**
```properties
# platforms/android/builds/key.properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=../builds/upload-keystore.jks
```

### **Step 3: Update Build Config**
```gradle
// android/app/build.gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

## 🧪 **Testing Android Package**

### **Test APK Installation**
```bash
# Install APK
adb install -r platforms/android/binaries/app-release.apk

# Launch app
adb shell am start -n com.yourcompany.credmanager/.MainActivity

# Check logs
adb logcat | grep flutter
```

### **Test on Device**
1. **Enable Developer Options**
2. **Enable USB Debugging**
3. **Connect device via USB**
4. **Install APK**: `flutter install --release`
5. **Test functionality**

### **Test on Emulator**
```bash
# Start emulator
flutter emulators --launch emulator_id

# Install and run
flutter run --release
```

## 🔧 **Troubleshooting**

### **Common Issues**

**❌ Build fails with SDK issues**
```bash
# Update Android SDK
flutter doctor --android-licenses
sdkmanager --update
```

**❌ APK not signed**
```bash
# Check signing config
flutter build apk --release --verbose

# Verify signature
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

**❌ App crashes on startup**
```bash
# Check device logs
adb logcat | grep flutter

# Check minimum SDK
adb shell getprop ro.build.version.sdk
```

**❌ Network permissions**
```bash
# Add to AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## 📋 **Package Contents Checklist**

### **✅ Must Include:**
- [ ] Flutter APK/AAB with encrypted SQLite storage
- [ ] Proper signing for release builds
- [ ] Storage permissions for database access
- [ ] All required assets and resources
- [ ] Minimum SDK requirements
- [ ] App icons for all densities

### **✅ Must Configure:**
- [ ] Application ID
- [ ] Version code/name
- [ ] API endpoints
- [ ] File storage paths
- [ ] Android-specific features

## 📤 **Distribution**

### **Direct APK**
- **File**: `app-release.apk`
- **Size**: ~15-50MB
- **Installation**: Sideloading required
- **Platforms**: Any Android device

### **Google Play Store**
- **File**: `app-release.aab`
- **Size**: ~10-40MB
- **Installation**: Play Store download
- **Requirements**: Google Play Developer account

### **Alternative Stores**
- **Amazon Appstore**: APK format
- **F-Droid**: APK format
- **Huawei AppGallery**: APK format

## 🎯 **Android-Specific Features**

### **✅ Android Integration:**
- Material Design
- Android widgets
- Notification system
- Background services
- File system access
- Camera integration

### **✅ Android Optimization:**
- Battery optimization
- Memory management
- Network efficiency
- Offline capabilities
- Push notifications

## 🔒 **Google Play Store**

### **Prepare for Upload**
1. **Create Google Play Developer Account**
2. **Prepare Store Listing**:
   - App description
   - Screenshots (phone + tablet)
   - Feature graphics
   - Privacy policy
3. **Upload AAB**: `flutter build appbundle --release`
4. **Configure Pricing & Distribution**
5. **Publish**

### **Store Requirements**
- **Target SDK**: API 31+ (Android 12+)
- **Minimum SDK**: API 21+ (Android 5.0+)
- **AAB Format**: Required for new apps
- **64-bit Support**: Required
- **Privacy Policy**: Required

## 📊 **Supported Devices**

### **Minimum Requirements**
- **Android Version**: 5.0 (API 21)
- **Architecture**: ARMv7, ARM64, x86, x86_64
- **Screen Size**: Small to XX-Large
- **RAM**: 1GB minimum
- **Storage**: 100MB free space

### **Recommended Specifications**
- **Android Version**: 8.0+ (API 26)
- **RAM**: 2GB+
- **Storage**: 500MB free space

## 📞 **Support**

### **Debug Commands**
```bash
# Device info
adb shell getprop

# App info
adb shell dumpsys package com.yourcompany.credmanager

# Memory info
adb shell dumpsys meminfo com.yourcompany.credmanager

# Network info
adb shell netstat
```

### **Log Locations**
- **Flutter logs**: `adb logcat | grep flutter`
- **System logs**: `adb logcat`
- **Crash reports**: Device Settings > Developer Options > Bug Report

---

## 🎉 **Success Checklist**

- [ ] APK builds without errors
- [ ] App installs and runs on target devices
- [ ] Encrypted database storage works correctly
- [ ] Authentication and credential management functional
- [ ] UI displays correctly on different screen sizes
- [ ] App handles Android lifecycle properly
- [ ] Signing works correctly for release builds
- [ ] Google Play Store requirements met (if targeting Play Store)

**Now you have COMPLETE, WORKING Android packages!** 📱