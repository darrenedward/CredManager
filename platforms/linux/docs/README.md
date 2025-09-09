# Linux Platform Documentation

## 📁 **Directory Structure**

```
platforms/linux/
├── docs/           # Documentation
│   └── README.md   # This file
├── builds/         # Build artifacts and configs
│   ├── package/    # DEB package structure
│   └── control/    # DEB control files
├── binaries/       # Final compiled packages
│   └── *.deb      # Distribution-ready packages
└── scripts/        # Build automation
    └── build_complete_deb.sh  # Complete build script
```

## 🚀 **Quick Build**

```bash
# From project root
cd platforms/linux/scripts
chmod +x build_complete_deb.sh
./build_complete_deb.sh
```

## 📦 **What Gets Built**

### **✅ Complete Package Includes:**
- **Go Backend Server** - API, authentication, database
- **Flutter Frontend** - GUI application
- **Startup Script** - Launches both components
- **Desktop Integration** - Menu shortcuts, icons
- **Configuration Files** - Proper paths and settings
- **Database Migrations** - Initial schema setup

### **❌ Previous Broken Packages Had:**
- Only Flutter frontend (useless)
- No backend server
- No startup automation
- Broken user experience

## 🔧 **Package Architecture**

### **File Structure in DEB:**
```
/usr/bin/
├── cred-manager-server     # Go backend binary
└── cred-manager-startup    # Startup script

/usr/lib/cred-manager/
└── *                       # Flutter frontend files

/usr/share/applications/
└── cred-manager.desktop    # Desktop menu entry

/usr/share/icons/
└── cred-manager.png        # Application icon

/var/lib/cred-manager/
└── 001_init.sql           # Database schema
```

### **Startup Process:**
1. User clicks desktop icon
2. `cred-manager-startup` script runs
3. Launches Go backend server (port 8080)
4. Launches Flutter frontend
5. Frontend connects to `http://localhost:8080/api`

## 🧪 **Testing**

### **Test Complete Package:**
```bash
# Install package
sudo dpkg -i cred-manager_1.0.0_amd64.deb

# Launch from applications menu
# Or run: cred-manager-startup

# Check backend is running
curl http://localhost:8080/api/health

# Check processes
ps aux | grep cred-manager
```

### **Debug Issues:**
```bash
# Check backend logs
tail -f /var/log/cred-manager.log

# Check if port is listening
netstat -tlnp | grep 8080

# Test API endpoints
curl http://localhost:8080/api/status
```

## 📋 **Dependencies**

### **Build Dependencies:**
- `go` (Go programming language)
- `flutter` (Flutter SDK)
- `dpkg-dev` (DEB packaging tools)

### **Runtime Dependencies:**
- `libc6` (>= 2.17)
- `libgtk-3-0` (>= 3.10)
- `libglib2.0-0` (>= 2.37)

## 🎯 **Distribution**

### **Package Naming:**
```
cred-manager_1.0.0_amd64.deb
```

### **Installation:**
```bash
sudo dpkg -i cred-manager_1.0.0_amd64.deb
sudo apt-get install -f  # Fix any missing dependencies
```

### **Uninstallation:**
```bash
sudo dpkg -r cred-manager
```

## 🔧 **Customization**

### **Modify Package:**
1. Edit `build_complete_deb.sh` for custom build steps
2. Modify `DEBIAN/control` for package metadata
3. Update `usr/share/applications/cred-manager.desktop` for menu integration
4. Customize startup script for different launch behavior

### **Add Files:**
- Place additional files in `builds/package/` structure
- Update `build_complete_deb.sh` to copy them
- Modify `DEBIAN/control` if adding dependencies

## 🚨 **Important Notes**

1. **Complete Packages Only** - Always include both Go backend AND Flutter frontend
2. **Test on Clean Systems** - Don't assume dependencies are installed
3. **Proper Permissions** - Set executable permissions in postinst script
4. **Database Initialization** - Handle first-run database setup
5. **Error Handling** - Graceful failure if backend doesn't start

## 📞 **Troubleshooting**

### **Common Issues:**

**Backend Won't Start:**
- Check file permissions: `ls -la /usr/bin/cred-manager*`
- Check logs: `tail -f /var/log/cred-manager.log`
- Test manually: `/usr/bin/cred-manager-server --help`

**Frontend Won't Connect:**
- Verify backend is running: `ps aux | grep cred-manager-server`
- Check port: `netstat -tlnp | grep 8080`
- Test connection: `curl http://localhost:8080/api/health`

**Package Installation Fails:**
- Check dependencies: `sudo apt-get install -f`
- Verify package integrity: `dpkg-deb -I package.deb`
- Check disk space: `df -h`

**Application Won't Launch:**
- Check desktop file: `cat /usr/share/applications/cred-manager.desktop`
- Update desktop database: `update-desktop-database`
- Try manual launch: `/usr/bin/cred-manager-startup`

---

## 🎉 **Success Checklist**

- [ ] Package builds without errors
- [ ] Both Go backend and Flutter frontend included
- [ ] Startup script launches both components
- [ ] Desktop integration works
- [ ] Application functions completely
- [ ] Can be installed/uninstalled cleanly
- [ ] Works on target Linux distributions

**Now you have COMPLETE, WORKING Linux packages!** 🚀