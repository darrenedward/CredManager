# Linux Platform Documentation

## 📁 **Directory Structure**

```
platforms/linux/
├── docs/           # Documentation
│   └── README.md   # This file
├── builds/         # Build artifacts and timestamped releases
│   ├── release_YYYYMMDD_HHMMSS/  # Timestamped build directories
│   └── latest/     # Symlink to latest build
├── binaries/       # Final distribution packages
│   └── *.tar.gz   # Distribution-ready archives
└── scripts/        # Build automation
    └── build.sh    # Linux build script
```

## 🚀 **Quick Build**

```bash
# From project root
cd platforms/linux/scripts
./build.sh
```

## 📦 **What Gets Built**

### **✅ Linux Build Includes:**
- **Flutter Executable** - Native Linux application with encrypted SQLite storage
- **Flutter Engine Libraries** - Required runtime libraries
- **Application Assets** - UI resources, fonts, images
- **Desktop Integration** - Menu shortcuts and icons
- **Encrypted Database** - Local SQLite storage with AES-256 encryption
- **Build Metadata** - Version and build information

### **✅ Architecture Benefits:**
- Self-contained application with no external dependencies
- Local-only operation (no network requirements)
- Encrypted credential storage
- Cross-platform consistency

## 🔧 **Build Output Structure**

### **Build Directory Layout:**
```
platforms/linux/builds/release_[timestamp]/
├── cred_manager                    # Main executable
├── lib/                           # Flutter engine libraries
│   ├── libflutter_linux_gtk.so   # Flutter engine
│   └── [other_libs]              # Additional libraries
├── data/                          # Application resources
│   ├── icudtl.dat                # ICU data
│   ├── flutter_assets/           # Flutter assets
│   └── [app_resources]           # Application-specific assets
└── build_info.txt                # Build metadata and version info
```

### **Application Startup:**
1. User launches `cred_manager` executable
2. Flutter engine initializes
3. Application loads encrypted SQLite database
4. User authenticates with master passphrase
5. Credentials decrypted and available for management

## 🧪 **Testing**

### **Test Built Application:**
```bash
# Navigate to build directory
cd platforms/linux/builds/latest

# Run the application
./cred_manager

# Check application process
ps aux | grep cred_manager

# Verify database creation (after first run)
ls -la ~/.local/share/cred_manager/
```

### **Debug Issues:**
```bash
# Run with verbose output
./cred_manager --verbose

# Check Flutter logs
flutter logs

# Verify database file permissions
ls -la ~/.local/share/cred_manager/database.db

# Check for missing libraries
ldd ./cred_manager
```

## 📋 **Dependencies**

### **Build Dependencies:**
- `flutter` (Flutter SDK 3.10.0+)
- `clang` (C++ compiler)
- `cmake` (Build system)
- `ninja-build` (Build tool)
- `pkg-config` (Package configuration)
- `libgtk-3-dev` (GTK development libraries)

### **Runtime Dependencies:**
- `libc6` (>= 2.17)
- `libgtk-3-0` (>= 3.10)
- `libglib2.0-0` (>= 2.37)
- `libsqlite3-0` (>= 3.7)

## 🎯 **Distribution**

### **Archive Naming:**
```
cred-manager-linux-x64-v1.0.0.tar.gz
```

### **Installation:**
```bash
# Extract archive
tar -xzf cred-manager-linux-x64-v1.0.0.tar.gz

# Move to desired location
sudo mv cred_manager /opt/cred-manager/

# Create desktop shortcut (optional)
sudo ln -s /opt/cred-manager/cred_manager /usr/local/bin/cred-manager
```

### **Uninstallation:**
```bash
# Remove application
sudo rm -rf /opt/cred-manager/
sudo rm -f /usr/local/bin/cred-manager

# Remove user data (optional)
rm -rf ~/.local/share/cred_manager/
```

## 🔧 **Customization**

### **Modify Build:**
1. Edit `build.sh` for custom build steps
2. Modify build output directory structure
3. Add custom assets or configuration files
4. Update build metadata and version information

### **Add Desktop Integration:**
```bash
# Create desktop entry
cat > ~/.local/share/applications/cred-manager.desktop << EOF
[Desktop Entry]
Name=Credential Manager
Comment=Secure credential management
Exec=/opt/cred-manager/cred_manager
Icon=application-default-icon
Terminal=false
Type=Application
Categories=Utility;Security;
EOF
```

## 🚨 **Important Notes**

1. **Self-Contained Application** - No external server dependencies
2. **Local Database** - SQLite database with AES-256 encryption
3. **User Data Location** - `~/.local/share/cred_manager/`
4. **Portable** - Can be run from any location
5. **Secure** - All credentials encrypted at rest

## 📞 **Troubleshooting**

### **Common Issues:**

**Application Won't Start:**
- Check file permissions: `ls -la ./cred_manager`
- Make executable: `chmod +x ./cred_manager`
- Check missing libraries: `ldd ./cred_manager`

**Database Issues:**
- Check database location: `ls -la ~/.local/share/cred_manager/`
- Verify permissions: `chmod 600 ~/.local/share/cred_manager/database.db`
- Check SQLite installation: `sqlite3 --version`

**UI Issues:**
- Check GTK installation: `pkg-config --modversion gtk+-3.0`
- Update system: `sudo apt update && sudo apt upgrade`
- Check display: `echo $DISPLAY`

**Performance Issues:**
- Check available memory: `free -h`
- Monitor CPU usage: `top -p $(pgrep cred_manager)`
- Check disk space: `df -h ~/.local/share/cred_manager/`

---

## 🎉 **Success Checklist**

- [ ] Application builds without errors
- [ ] Executable runs on target Linux systems
- [ ] Database encryption works correctly
- [ ] All UI features functional
- [ ] Data persists between sessions
- [ ] Export/import functionality works
- [ ] Performance is acceptable

**Now you have a COMPLETE, SECURE Linux application!** 🚀