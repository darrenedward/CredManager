# Windows Platform Documentation

## 📦 **Distribution Formats**
- **Primary**: `CredManager-Setup-1.0.0.exe` (SINGLE installer with everything)
- **Alternative**: `CredManager-Portable.zip` (portable ZIP)
- **Single EXE**: `cred-manager.exe` (requires DLLs)

## 🎯 **ONE INSTALLER - COMPLETE APPLICATION**

**❌ NO MULTIPLE INSTALLATIONS!**
**✅ ONE installer includes:**
- Go backend server
- Flutter frontend application
- Startup automation
- Desktop shortcuts
- Professional uninstaller

**Users run ONE installer and get a COMPLETE, WORKING application!**

## 🛠️ **Build Requirements**
- **OS**: Windows 10/11 (64-bit)
- **Flutter**: Latest stable version
- **Visual Studio**: 2022 with Desktop C++ workload
- **Windows SDK**: 10.0.19041.0 or later
- **Optional**: Inno Setup (for installer creation)

## 🚀 **Quick Build (On Windows)**

### **PowerShell (Recommended) - SINGLE INSTALLER**
```powershell
# Navigate to Windows build directory
cd platforms\windows\scripts

# Run SINGLE installer build (includes both Go + Flutter)
.\build_single_installer.ps1

# Result: ONE complete installer!
```

### **Command Prompt**
```cmd
# Navigate to Windows build directory
cd platforms\windows\scripts

# Run SINGLE installer build
powershell -ExecutionPolicy Bypass -File build_single_installer.ps1
```

## 📁 **Build Output Structure**

```
platforms/windows/
├── builds/
│   ├── installer.iss          # Inno Setup script (auto-generated)
│   └── installer/             # Complete app files (auto-generated)
│       ├── server.exe         # Go backend
│       ├── cred-manager.exe   # Flutter frontend
│       ├── *.dll              # Dependencies
│       ├── start-cred-manager.bat  # Startup script
│       └── create-shortcut.bat     # Desktop shortcut
├── scripts/
│   └── build_single_installer.ps1   # ⭐ SINGLE installer build script
└── binaries/
    └── CredManager-Setup-1.0.0.exe  # ⭐ ONE complete installer
```

## 🔧 **Manual Build Steps**

### **Step 1: Enable Windows Desktop**
```powershell
flutter config --enable-windows-desktop
```

### **Step 2: Build Go Backend**
```powershell
cd backend
$env:GOOS="windows"
$env:GOARCH="amd64"
go build -o server.exe ./cmd/server
```

### **Step 3: Build Flutter Frontend**
```powershell
cd frontend
flutter build windows --release
```

### **Step 4: Create Complete Package**
```powershell
# Copy files to distribution
mkdir dist\windows
copy "backend\server.exe" "dist\windows\"
copy "frontend\build\windows\x64\runner\Release\*" "dist\windows\"

# Create portable ZIP
Compress-Archive -Path "dist\windows\*" -DestinationPath "CredManager-Portable.zip"
```

## 📦 **Creating Professional Installer**

### **Using Inno Setup (Recommended)**
1. **Download Inno Setup**: https://jrsoftware.org/isinfo.php
2. **Update installer script**: `platforms/windows/builds/installer.iss`
3. **Convert icon**: `magick assets/icons/shield_icon.png assets/icons/shield_icon.ico`
4. **Compile installer**:
   ```cmd
   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" platforms\windows\builds\installer.iss
   ```

### **Using NSIS (Alternative)**
```cmd
# Create NSIS installer
makensis platforms\windows\builds\installer.nsi
```

## 🧪 **Testing Windows Package**

### **Test Portable Version**
```cmd
# Extract ZIP
# Run cred-manager.exe
# Verify backend starts automatically
# Test login and dashboard
```

### **Test Installer Version**
```cmd
# Run CredManager-Setup-1.0.0.exe
# Follow installation wizard
# Launch from Start Menu
# Verify all features work
# Test uninstaller
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

**❌ Go build fails**
```powershell
# Set correct environment
$env:GOOS="windows"
$env:GOARCH="amd64"
$env:CGO_ENABLED="1"
go build -o server.exe ./cmd/server
```

**❌ Application won't start**
- Check antivirus/firewall
- Run as administrator
- Check Windows Event Viewer for errors

## 📋 **Package Contents Checklist**

### **✅ Must Include:**
- [ ] Go backend server (server.exe)
- [ ] Flutter frontend (cred-manager.exe + DLLs)
- [ ] Startup script (startup.bat)
- [ ] Configuration files
- [ ] Database migrations
- [ ] Desktop shortcuts
- [ ] Uninstaller

### **✅ Must Configure:**
- [ ] Correct API endpoints (localhost:8080)
- [ ] Database file paths
- [ ] Windows-specific paths
- [ ] Registry entries (optional)

## 📤 **Distribution**

### **Installer Package**
- **File**: `CredManager-Setup-1.0.0.exe`
- **Size**: ~50-100MB (includes all dependencies)
- **Installation**: Standard Windows installer
- **Uninstallation**: Add/Remove Programs

### **Portable Package**
- **File**: `CredManager-Portable.zip`
- **Size**: ~30-80MB
- **Installation**: Just extract and run
- **No admin rights required**

## 🎯 **Windows-Specific Features**

### **✅ Windows Integration:**
- Start Menu shortcuts
- Desktop icons
- File associations
- Registry integration
- Windows Event Log
- Task Scheduler integration

### **✅ Windows Optimization:**
- Windows Defender compatibility
- UAC compatibility
- Windows 10/11 optimization
- Dark mode support
- High DPI support

## 📞 **Support**

### **Debug Commands**
```cmd
# Check running processes
tasklist | findstr cred-manager

# Check Windows services
sc query cred-manager

# Check Event Viewer
eventvwr.msc

# Check firewall
wf.msc
```

### **Log Locations**
- **Application logs**: `%APPDATA%\Cred Manager\logs\`
- **Windows Event Logs**: `Windows Logs > Application`
- **Flutter logs**: Console output when running

---

## 🎉 **Success Checklist**

- [ ] Package builds without errors
- [ ] Both Go backend and Flutter frontend included
- [ ] Startup script launches both components
- [ ] Windows integration works (shortcuts, uninstaller)
- [ ] Application functions completely
- [ ] Can be installed/uninstalled cleanly
- [ ] Works on target Windows versions

**Now you have COMPLETE, WORKING Windows packages!** 🚀