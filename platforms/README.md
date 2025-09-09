# Cred Manager Platform Builds

## 🏗️ **Clean Project Structure**

```
APIKeyManager/
├── backend/           # Go backend server
├── frontend/          # Flutter frontend
├── platforms/         # Platform-specific builds ⭐
│   ├── linux/
│   │   ├── docs/      # Linux documentation
│   │   ├── builds/    # Build artifacts & configs
│   │   ├── binaries/  # Compiled binaries
│   │   └── scripts/   # Build scripts
│   ├── windows/
│   │   ├── docs/      # Windows documentation
│   │   ├── builds/    # Build artifacts & configs
│   │   ├── binaries/  # Compiled binaries
│   │   └── scripts/   # Build scripts
│   ├── macos/
│   │   ├── docs/      # macOS documentation
│   │   ├── builds/    # Build artifacts & configs
│   │   ├── binaries/  # Compiled binaries
│   │   └── scripts/   # Build scripts
│   ├── iphone/
│   │   ├── docs/      # iOS documentation
│   │   ├── builds/    # Build artifacts & configs
│   │   ├── binaries/  # Compiled binaries
│   │   └── scripts/   # Build scripts
│   └── android/
│       ├── docs/      # Android documentation
│       ├── builds/    # Build artifacts & configs
│       ├── binaries/  # Compiled binaries
│       └── scripts/   # Build scripts
└── docs/             # General documentation
```

## 🚨 **CRITICAL: Complete Package Requirements**

**❌ WRONG:** Previous builds only included Flutter frontend
**✅ CORRECT:** Each package must include BOTH:

1. **Go Backend Server** - API, authentication, database
2. **Flutter Frontend** - GUI application
3. **Startup Script** - Launches both components
4. **Configuration** - Proper paths and ports

### **Why Previous Builds Failed:**
- Flutter app calls `http://localhost:8080/api` for backend
- Without Go server running, app shows connection errors
- Users get broken, non-functional application

## 🛠️ **Building Complete Packages**

### **Step 1: Build Go Backend**
```bash
# Build Go server for target platform
cd backend
GOOS=linux GOARCH=amd64 go build -o server ./cmd/server  # Linux
GOOS=windows GOARCH=amd64 go build -o server.exe ./cmd/server  # Windows
GOOS=darwin GOARCH=amd64 go build -o server ./cmd/server  # macOS Intel
GOOS=darwin GOARCH=arm64 go build -o server-arm64 ./cmd/server  # macOS Apple Silicon
```

### **Step 2: Build Flutter Frontend**
```bash
# Build Flutter for target platform
cd frontend
flutter build linux --release   # Linux
flutter build windows --release # Windows (on Windows)
flutter build macos --release   # macOS (on macOS)
```

### **Step 3: Create Complete Package**
Each platform needs:
- Go backend binary
- Flutter frontend binary/bundle
- Startup script that launches both
- Configuration files
- Desktop integration (shortcuts, icons)

## 📦 **Platform-Specific Instructions**

### **Linux (.deb Package)**
```
platforms/linux/
├── builds/
│   ├── control/           # DEB control files
│   ├── postinst           # Post-install script
│   └── prerm             # Pre-remove script
├── scripts/
│   ├── build_deb.sh      # Build complete DEB
│   └── create_package.sh # Package creation
└── binaries/
    ├── cred-manager      # Flutter binary
    ├── cred-manager-server # Go server
    └── startup.sh        # Launch script
```

### **Windows (.exe + Installer)**
```
platforms/windows/
├── builds/
│   ├── installer.iss     # Inno Setup script
│   └── nsis/            # NSIS installer files
├── scripts/
│   ├── build_windows.ps1 # PowerShell build
│   └── create_installer.ps1 # Installer creation
└── binaries/
    ├── CredManager.exe   # Flutter exe
    ├── server.exe        # Go server
    └── startup.bat       # Launch script
```

### **macOS (.app + .dmg)**
```
platforms/macos/
├── builds/
│   ├── app_template/     # App bundle template
│   └── dmg_config/      # DMG creation config
├── scripts/
│   ├── build_app.sh     # Create .app bundle
│   └── create_dmg.sh    # Create DMG installer
└── binaries/
    ├── Cred Manager.app/ # Complete app bundle
    ├── server           # Go server
    └── startup.sh       # Launch script
```

## 🚀 **Quick Start Guide**

### **For Linux:**
```bash
# 1. Build Go backend
cd backend && go build -o server ./cmd/server

# 2. Build Flutter frontend
cd frontend && flutter build linux --release

# 3. Create complete package
cd platforms/linux/scripts
./build_deb.sh
```

### **For Windows (on Windows):**
```powershell
# 1. Build Go backend
cd backend
$env:GOOS="windows"; $env:GOARCH="amd64"; go build -o server.exe ./cmd/server

# 2. Build Flutter frontend
cd frontend
flutter build windows --release

# 3. Create complete package
cd platforms\windows\scripts
.\build_windows.ps1
```

### **For macOS (on macOS):**
```bash
# 1. Build Go backend
cd backend && go build -o server ./cmd/server

# 2. Build Flutter frontend
cd frontend && flutter build macos --release

# 3. Create complete package
cd platforms/macos/scripts
./build_app.sh
```

## 📋 **Package Contents Checklist**

### **✅ Must Include:**
- [ ] Go backend server binary
- [ ] Flutter frontend binary/bundle
- [ ] Startup script (launches both)
- [ ] Configuration files
- [ ] Database migration files
- [ ] Desktop shortcuts/icons
- [ ] Uninstaller (optional)

### **✅ Must Configure:**
- [ ] Correct API endpoints
- [ ] Database paths
- [ ] Port configurations
- [ ] File permissions
- [ ] Auto-startup (optional)

## 🔧 **Common Issues & Solutions**

### **Connection Refused Errors:**
- **Problem:** Flutter can't connect to Go server
- **Solution:** Ensure startup script launches Go server first
- **Check:** `netstat -tlnp | grep 8080`

### **Permission Denied:**
- **Problem:** Can't execute binaries
- **Solution:** Set proper permissions in package
- **Fix:** `chmod +x /usr/bin/cred-manager*`

### **Missing Dependencies:**
- **Problem:** Go server needs certain libraries
- **Solution:** Use static linking or include dependencies
- **Check:** `ldd server` (Linux) or `otool -L server` (macOS)

## 🎯 **Testing Complete Packages**

### **Test Checklist:**
1. **Install package** on clean system
2. **Launch application** from desktop/menu
3. **Verify backend starts** (check port 8080)
4. **Test login functionality**
5. **Test all features** (projects, keys, settings)
6. **Test uninstall** (if applicable)

### **Debug Commands:**
```bash
# Check if backend is running
curl http://localhost:8080/api/health

# Check processes
ps aux | grep cred-manager

# Check logs
tail -f /var/log/cred-manager.log
```

## 📤 **Distribution Ready**

Once built, each platform will have:
- **Linux:** `cred-manager_1.0.0_amd64.deb`
- **Windows:** `CredManager-Setup-1.0.0.exe`
- **macOS:** `CredManager-macOS-1.0.0.dmg`

**These packages will be COMPLETE and FUNCTIONAL!** 🎉

---

## 🚨 **Important Notes**

1. **Always build both components** - Go backend + Flutter frontend
2. **Test on clean systems** - Don't assume dependencies
3. **Include startup scripts** - Users shouldn't need to manually start services
4. **Configure paths correctly** - Use relative paths in packages
5. **Test thoroughly** - Complete user journey from install to use

**Now we build COMPLETE, WORKING applications!** ✨