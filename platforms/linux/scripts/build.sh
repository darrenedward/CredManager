#!/bin/bash

# Linux Build Script for Credential Manager
# This script builds the Flutter app for Linux and organizes outputs

set -e

echo "🐧 Building Credential Manager for Linux..."

# Navigate to frontend directory
cd "$(dirname "$0")/../../../frontend"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for Linux
echo "🔨 Building for Linux..."
flutter build linux --release

# Create build timestamp
BUILD_TIME=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="../platforms/linux/builds/release_${BUILD_TIME}"

# Create build directory
mkdir -p "$BUILD_DIR"

# Copy build artifacts
echo "📁 Copying build artifacts to platforms directory..."
cp -r build/linux/x64/release/bundle/* "$BUILD_DIR/"

# Create version info
echo "📝 Creating version info..."
cat > "$BUILD_DIR/build_info.txt" << EOF
Build Information
=================
Platform: Linux x64
Build Type: Release
Build Time: $(date)
Flutter Version: $(flutter --version | head -n 1)
Dart Version: $(dart --version)
EOF

# Create symlink to latest build
cd "$(dirname "$0")/../builds"
rm -f latest
ln -s "release_${BUILD_TIME}" latest

echo "✅ Linux build completed successfully!"
echo "📍 Build location: platforms/linux/builds/release_${BUILD_TIME}"
echo "🔗 Latest build: platforms/linux/builds/latest"
