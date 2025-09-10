#!/bin/bash

# iOS Build Script for Credential Manager
# This script builds the Flutter app for iOS and organizes outputs

set -e

echo "📱 Building Credential Manager for iOS..."

# Navigate to frontend directory
cd "$(dirname "$0")/../../../frontend"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for iOS (requires macOS and Xcode)
echo "🔨 Building for iOS..."
flutter build ios --release --no-codesign

# Create build timestamp
BUILD_TIME=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="../platforms/iphone/builds/release_${BUILD_TIME}"

# Create build directory
mkdir -p "$BUILD_DIR"

# Copy build artifacts
echo "📁 Copying build artifacts to platforms directory..."
cp -r build/ios/Release-iphoneos/* "$BUILD_DIR/"

# Create version info
echo "📝 Creating version info..."
cat > "$BUILD_DIR/build_info.txt" << EOF
Build Information
=================
Platform: iOS
Build Type: Release (No Code Sign)
Build Time: $(date)
Flutter Version: $(flutter --version | head -n 1)
Dart Version: $(dart --version)
Xcode Version: $(xcodebuild -version | head -n 1)
Note: This build is not code-signed. Use Xcode for final signing and distribution.
EOF

# Create symlink to latest build
cd "$(dirname "$0")/../builds"
rm -f latest
ln -s "release_${BUILD_TIME}" latest

echo "✅ iOS build completed successfully!"
echo "📍 Build location: platforms/iphone/builds/release_${BUILD_TIME}"
echo "🔗 Latest build: platforms/iphone/builds/latest"
echo "⚠️  Note: Build is not code-signed. Use Xcode for final signing and App Store submission."
