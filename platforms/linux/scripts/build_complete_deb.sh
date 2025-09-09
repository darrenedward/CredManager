#!/bin/bash

# Complete Linux DEB Build Script
# Builds BOTH Go backend AND Flutter frontend into a working package

set -e

echo "🔨 Building SECURE Cred Manager for Linux..."
echo "📦 Local-only app with integrated Argon2 security (no network ports)"
echo

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_NAME="cred-manager"
VERSION="1.0.0"
ARCH="amd64"
MAINTAINER="Darren Edward House of Jones"

# Directories
PROJECT_ROOT="$(cd .. && cd .. && cd .. && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
BUILD_DIR="$PROJECT_ROOT/platforms/linux/builds"
BINARIES_DIR="$PROJECT_ROOT/platforms/linux/binaries"
PACKAGE_DIR="$BUILD_DIR/package"

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."

    if ! command -v go &> /dev/null; then
        print_error "Go is not installed. Please install Go first."
        exit 1
    fi

    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi

    if ! command -v dpkg-deb &> /dev/null; then
        print_error "dpkg-deb is not available. Please install dpkg-dev."
        exit 1
    fi

    print_status "All dependencies found"
}

# Build Go backend - REMOVED: Backend no longer needed
build_backend() {
    print_info "Skipping Go backend build - app is now fully local with integrated Argon2 security"
    print_status "Backend removal completed - no network ports opened"
}

# Build Flutter frontend
build_frontend() {
    print_info "Building Flutter frontend..."

    cd "$FRONTEND_DIR"

    # Enable Linux desktop
    flutter config --enable-linux-desktop

    # Clean and build
    flutter clean
    flutter pub get

    if flutter build linux --release; then
        print_status "Flutter frontend built successfully"
        ls -la build/linux/x64/release/bundle/
    else
        print_error "Flutter frontend build failed"
        exit 1
    fi
}

# Create package structure
create_package_structure() {
    print_info "Creating DEB package structure..."

    # Clean previous package
    rm -rf "$PACKAGE_DIR"
    mkdir -p "$PACKAGE_DIR"

    # Create DEBIAN directory
    mkdir -p "$PACKAGE_DIR/DEBIAN"

    # Create application directories
    mkdir -p "$PACKAGE_DIR/usr/bin"
    mkdir -p "$PACKAGE_DIR/usr/lib/$APP_NAME"
    mkdir -p "$PACKAGE_DIR/usr/share/applications"
    mkdir -p "$PACKAGE_DIR/usr/share/icons/hicolor/512x512/apps"
    mkdir -p "$PACKAGE_DIR/usr/share/doc/$APP_NAME"
    mkdir -p "$PACKAGE_DIR/var/lib/$APP_NAME"

    print_status "Package structure created"
}

# Copy files to package
copy_files() {
    print_info "Copying files to package..."

    # Skip Go backend - REMOVED: App is fully local
    print_info "Skipping Go backend copy - app is fully local with integrated security"

    # Copy Flutter frontend
    cp -r "$FRONTEND_DIR/build/linux/x64/release/bundle/"* "$PACKAGE_DIR/usr/lib/$APP_NAME/"
    print_status "Flutter frontend copied"

    # Copy icon
    if [ -f "$FRONTEND_DIR/assets/icons/shield_icon.png" ]; then
        cp "$FRONTEND_DIR/assets/icons/shield_icon.png" "$PACKAGE_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
        print_status "Icon copied"
    fi

    # Copy database migration
    if [ -f "$BACKEND_DIR/migrations/001_init.sql" ]; then
        cp "$BACKEND_DIR/migrations/001_init.sql" "$PACKAGE_DIR/var/lib/$APP_NAME/"
        print_status "Database migration copied"
    fi
}

# Create control file
create_control_file() {
    print_info "Creating DEB control file..."

    cat > "$PACKAGE_DIR/DEBIAN/control" << EOF
Package: $APP_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: $MAINTAINER
Description: Cred Manager - Secure API Key Management
 A desktop application for securely managing API keys, credentials,
 and sensitive data with local encryption and authentication.
 .
 Features:
  * Local encrypted storage
  * Secure authentication
  * Project-based organization
  * Password generation
  * Cross-platform support
Depends: libc6 (>= 2.17), libgtk-3-0 (>= 3.10), libglib2.0-0 (>= 2.37)
Homepage: https://github.com/yourusername/cred-manager
EOF

    print_status "Control file created"
}

# Create desktop file
create_desktop_file() {
    print_info "Creating desktop integration..."

    cat > "$PACKAGE_DIR/usr/share/applications/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=Cred Manager
Comment=Secure API Key Management
Exec=/usr/bin/$APP_NAME-startup
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Utility;Security;
StartupWMClass=cred-manager
EOF

    print_status "Desktop file created"
}

# Create startup script
create_startup_script() {
    print_info "Creating startup script..."

    cat > "$PACKAGE_DIR/usr/bin/$APP_NAME-startup" << 'EOF'
#!/bin/bash

# Cred Manager Startup Script
# Launches Flutter frontend (fully local with integrated Argon2 security)

APP_NAME="cred-manager"
APP_DIR="/usr/lib/$APP_NAME"

# Launch Flutter frontend
echo "Starting Cred Manager (local-only with Argon2 security)..."
cd "$APP_DIR"
exec ./cred-manager
EOF

    # Make startup script executable
    chmod +x "$PACKAGE_DIR/usr/bin/$APP_NAME-startup"

    print_status "Startup script created"
}

# Create post-install script
create_postinst_script() {
    print_info "Creating post-install script..."

    cat > "$PACKAGE_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash

# Post-installation script for Cred Manager

APP_NAME="cred-manager"
DATA_DIR="/var/lib/$APP_NAME"
LOG_DIR="/var/log"

# Create data directory
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

# Set permissions
chown root:root "$DATA_DIR"
chmod 755 "$DATA_DIR"

# Initialize database if migration file exists
if [ -f "$DATA_DIR/001_init.sql" ]; then
    echo "Database migration file found"
    # Note: Database initialization would happen when server first starts
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database
fi

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null || true
fi

echo "Cred Manager installation completed successfully!"
echo "You can now launch it from your applications menu."
EOF

    chmod +x "$PACKAGE_DIR/DEBIAN/postinst"

    print_status "Post-install script created"
}

# Build DEB package
build_deb() {
    print_info "Building DEB package..."

    cd "$BUILD_DIR"

    # Calculate installed size
    INSTALLED_SIZE=$(du -sk "$PACKAGE_DIR" | cut -f1)
    sed -i "s/^Installed-Size: .*/Installed-Size: $INSTALLED_SIZE/" "$PACKAGE_DIR/DEBIAN/control"

    # Build package
    PACKAGE_NAME="${APP_NAME}_${VERSION}_${ARCH}.deb"
    if dpkg-deb --build "$PACKAGE_DIR" "$PACKAGE_NAME"; then
        print_status "DEB package built successfully!"

        # Move to binaries directory
        mkdir -p "$BINARIES_DIR"
        mv "$PACKAGE_NAME" "$BINARIES_DIR/"

        # Show package info
        echo
        print_info "Package Information:"
        dpkg-deb -I "$BINARIES_DIR/$PACKAGE_NAME"

        echo
        print_info "Package Contents:"
        dpkg-deb -c "$BINARIES_DIR/$PACKAGE_NAME" | head -20

        echo
        print_status "SECURE PACKAGE CREATED: $BINARIES_DIR/$PACKAGE_NAME"
        print_info "This package includes Flutter frontend with integrated Argon2 security!"
        print_info "Local-only operation - NO network ports opened!"
        print_info "Users can install with: sudo dpkg -i $PACKAGE_NAME"

    else
        print_error "DEB package build failed"
        exit 1
    fi
}

# Main build process
main() {
    echo "=========================================="
    echo "🔨 BUILDING COMPLETE CRED MANAGER PACKAGE"
    echo "=========================================="
    echo

    check_dependencies
    echo

    build_backend
    echo

    build_frontend
    echo

    create_package_structure
    copy_files
    create_control_file
    create_desktop_file
    create_startup_script
    create_postinst_script
    echo

    build_deb
    echo

    echo "=========================================="
    print_status "SECURE BUILD COMPLETE!"
    print_info "Your Cred Manager package is ready for distribution!"
    print_info "Features: Local-only operation with Argon2 security"
    print_info "Location: $BINARIES_DIR/${APP_NAME}_${VERSION}_${ARCH}.deb"
    echo "=========================================="
}

# Run main function
main "$@"