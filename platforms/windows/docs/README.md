# Windows Platform Documentation

## 📦 **Distribution Formats**
- **Primary**: `cred-manager-windows-x64-v1.0.0.zip` (Portable application bundle)
- **Alternative**: `cred_manager.exe` (Single executable with dependencies)
- **Future**: `CredManager-Setup-1.0.0.exe` (Windows installer)

## 🎯 **SELF-CONTAINED APPLICATION**

**✅ Application bundle includes:**
- Flutter Windows executable
- Flutter engine DLL
- Application assets and resources
- Build metadata and version info

**Users extract and run - COMPLETE, WORKING application with encrypted storage!**

## 🛠️ **Build Requirements**
- **OS**: Windows 10/11 (64-bit)
- **Flutter**: 3.10.0 or higher
- **Visual Studio**: 2022 with Desktop C++ workload
- **Windows SDK**: 10.0.19041.0 or later
- **Optional**: Windows Installer XML (WiX) for MSI creation

## 🚀 **Quick Build (On Windows)**

### **Command Prompt/PowerShell**
```cmd
# Navigate to Windows build directory
cd platforms\windows\scripts

# Run Windows build script
.\build.bat

# Result: Complete Windows application bundle!
```

### **PowerShell Alternative**
```powershell
# Navigate to Windows build directory
cd platforms\windows\scripts

# Run Windows build script
.\build.bat
```

## 📁 **Build Output Structure**

```
platforms/windows/builds/release_[timestamp]/
├── cred_manager.exe           # Main executable
├── flutter_windows.dll       # Flutter engine
├── data/                      # Application resources
│   ├── icudtl.dat            # ICU data
│   ├── flutter_assets/       # Flutter assets
│   └── [app_resources]       # Application-specific assets
└── build_info.txt            # Build metadata and version info
```

## 🔧 **Manual Build Steps**

### **Step 1: Enable Windows Desktop**
```cmd
flutter config --enable-windows-desktop
```

### **Step 2: Build Flutter Application**
```cmd
cd frontend
flutter build windows --release
```

### **Step 3: Package Application**
```cmd
# Navigate to build script directory
cd platforms\windows\scripts

# Run the build script
build.bat
```

## 📦 **Creating Distribution Package**

### **Portable ZIP (Current)**
The build script automatically creates a portable ZIP package:
```
cred-manager-windows-x64-v1.0.0.zip
├── cred_manager.exe           # Main executable
├── flutter_windows.dll       # Flutter engine
├── data/                      # Application assets
└── README.txt                 # Usage instructions
```

### **Windows Installer (Future Enhancement)**
For professional distribution, consider creating:
- **MSI Installer** using WiX Toolset
- **NSIS Installer** for custom installation experience
- **Inno Setup** for simple installer creation

## 🧪 **Testing Windows Application**

### **Test Portable Version**
```cmd
# Extract ZIP to desired location
# Double-click cred_manager.exe
# Verify application starts correctly
# Test authentication and credential management
```

### **Test System Integration**
```cmd
# Extract ZIP to test location
# Run cred_manager.exe
# Verify application starts correctly
# Test all features and functionality
```

## 🔧 **Troubleshooting**

### **Common Issues**

**❌ "flutter build windows" not recognized**
- Install Visual Studio Desktop C++ workload
- Add Windows 10/11 SDK
- Restart command prompt/PowerShell

**❌ MSVC not found**
```cmd
# Install Visual Studio Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

**❌ Application won't start**
- Check antivirus/firewall (may block executable)
- Verify all DLL files are present
- Check Windows Event Viewer for errors
- Try running from command prompt to see error messages

**❌ Database issues**
- Check user data directory: `%APPDATA%\cred_manager\`
- Verify SQLite libraries are available
- Check file permissions

## 📋 **Application Features**

### **✅ Windows-Specific Features:**
- Native Windows executable
- Encrypted SQLite database storage
- Windows-style file paths and data locations
- High DPI support for modern displays
- Windows 10/11 theme integration

### **✅ Security Features:**
- AES-256-GCM encryption for all credentials
- Argon2 key derivation from user passphrase
- No network dependencies (local-only operation)
- Secure memory handling

## 📤 **Distribution**

### **Portable Package**
- **File**: `cred-manager-windows-x64-v1.0.0.zip`
- **Size**: ~30-50MB (includes Flutter runtime)
- **Installation**: Extract and run
- **No admin rights required**
- **User data**: Stored in `%APPDATA%\cred_manager\`

### **Future Installer Package**
- **File**: `CredManager-Setup-1.0.0.exe`
- **Installation**: Standard Windows installer
- **Uninstallation**: Add/Remove Programs
- **System integration**: Start Menu, desktop shortcuts

## 🎯 **Windows Integration**

### **✅ Current Features:**
- Portable executable (no installation required)
- Windows-native UI with Material 3 design
- Proper Windows file system integration
- Windows-style keyboard shortcuts

### **✅ Future Enhancements:**
- Start Menu shortcuts
- Desktop icons
- File associations for credential files
- Windows Defender SmartScreen compatibility

## 📞 **Support**

### **Debug Commands**
```cmd
# Check running processes
tasklist | findstr cred_manager

# Run with verbose output
cred_manager.exe --verbose

# Check application data
dir "%APPDATA%\cred_manager"
```

### **Data Locations**
- **Application data**: `%APPDATA%\cred_manager\`
- **Database**: `%APPDATA%\cred_manager\database.db`
- **Logs**: Console output (when run from command prompt)

---

## 🎉 **Success Checklist**

- [ ] Application builds without errors
- [ ] Executable runs on target Windows systems
- [ ] Database encryption works correctly
- [ ] All UI features functional
- [ ] Data persists between sessions
- [ ] Export/import functionality works
- [ ] Performance is acceptable

**Now you have a COMPLETE, SECURE Windows application!** 🚀