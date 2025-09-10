#!/bin/bash

# Android Build Script for Credential Manager
# This script builds the Flutter app for Android and organizes outputs

set -e

echo "🤖 Building Credential Manager for Android..."

# Navigate to frontend directory
cd "$(dirname "$0")/../../../frontend"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build APK
echo "🔨 Building APK..."
flutter build apk --release

# Build App Bundle (for Play Store)
echo "🔨 Building App Bundle..."
flutter build appbundle --release

# Create build timestamp
BUILD_TIME=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="../platforms/android/builds/release_${BUILD_TIME}"

# Create build directory
mkdir -p "$BUILD_DIR"

# Copy build artifacts
echo "📁 Copying build artifacts to platforms directory..."
cp build/app/outputs/flutter-apk/app-release.apk "$BUILD_DIR/cred_manager_${BUILD_TIME}.apk"
cp build/app/outputs/bundle/release/app-release.aab "$BUILD_DIR/cred_manager_${BUILD_TIME}.aab"

# Create version info
echo "📝 Creating version info..."
cat > "$BUILD_DIR/build_info.txt" << EOF
Build Information
=================
Platform: Android
Build Type: Release
Build Time: $(date)
Flutter Version: $(flutter --version | head -n 1)
Dart Version: $(dart --version)
APK: cred_manager_${BUILD_TIME}.apk
App Bundle: cred_manager_${BUILD_TIME}.aab
EOF

# Create symlink to latest build
cd "$(dirname "$0")/../builds"
rm -f latest
ln -s "release_${BUILD_TIME}" latest

echo "✅ Android build completed successfully!"
echo "📍 Build location: platforms/android/builds/release_${BUILD_TIME}"
echo "🔗 Latest build: platforms/android/builds/latest"
echo "📱 APK: cred_manager_${BUILD_TIME}.apk"
echo "📦 App Bundle: cred_manager_${BUILD_TIME}.aab"
