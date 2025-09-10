#!/bin/bash

# Master Build Script for Credential Manager
# Builds the Flutter app for all supported platforms

set -e

echo "🚀 Credential Manager - Multi-Platform Build Script"
echo "=================================================="

# Function to check if a platform is available
check_platform() {
    case $1 in
        "linux")
            if command -v flutter >/dev/null 2>&1; then
                return 0
            fi
            ;;
        "windows")
            if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
                return 0
            fi
            ;;
        "macos")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                return 0
            fi
            ;;
        "android")
            if command -v flutter >/dev/null 2>&1; then
                return 0
            fi
            ;;
        "ios")
            if [[ "$OSTYPE" == "darwin"* ]] && command -v xcodebuild >/dev/null 2>&1; then
                return 0
            fi
            ;;
    esac
    return 1
}

# Parse command line arguments
PLATFORMS=()
BUILD_ALL=false

if [ $# -eq 0 ]; then
    BUILD_ALL=true
else
    for arg in "$@"; do
        case $arg in
            --all)
                BUILD_ALL=true
                ;;
            --linux)
                PLATFORMS+=("linux")
                ;;
            --windows)
                PLATFORMS+=("windows")
                ;;
            --macos)
                PLATFORMS+=("macos")
                ;;
            --android)
                PLATFORMS+=("android")
                ;;
            --ios)
                PLATFORMS+=("ios")
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --all       Build for all available platforms (default)"
                echo "  --linux     Build for Linux"
                echo "  --windows   Build for Windows"
                echo "  --macos     Build for macOS"
                echo "  --android   Build for Android"
                echo "  --ios       Build for iOS"
                echo "  --help      Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $arg"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
fi

# If --all or no specific platforms, build for all available
if [ "$BUILD_ALL" = true ]; then
    PLATFORMS=("linux" "windows" "macos" "android" "ios")
fi

# Build for each platform
SUCCESSFUL_BUILDS=()
FAILED_BUILDS=()

for platform in "${PLATFORMS[@]}"; do
    echo ""
    echo "🔍 Checking $platform platform..."
    
    if check_platform "$platform"; then
        echo "✅ $platform platform available"
        echo "🔨 Building for $platform..."
        
        case $platform in
            "linux")
                if ./linux/scripts/build.sh; then
                    SUCCESSFUL_BUILDS+=("$platform")
                else
                    FAILED_BUILDS+=("$platform")
                fi
                ;;
            "windows")
                if ./windows/scripts/build.bat; then
                    SUCCESSFUL_BUILDS+=("$platform")
                else
                    FAILED_BUILDS+=("$platform")
                fi
                ;;
            "macos")
                if ./macos/scripts/build.sh; then
                    SUCCESSFUL_BUILDS+=("$platform")
                else
                    FAILED_BUILDS+=("$platform")
                fi
                ;;
            "android")
                if ./android/scripts/build.sh; then
                    SUCCESSFUL_BUILDS+=("$platform")
                else
                    FAILED_BUILDS+=("$platform")
                fi
                ;;
            "ios")
                if ./iphone/scripts/build.sh; then
                    SUCCESSFUL_BUILDS+=("$platform")
                else
                    FAILED_BUILDS+=("$platform")
                fi
                ;;
        esac
    else
        echo "❌ $platform platform not available on this system"
        FAILED_BUILDS+=("$platform (not available)")
    fi
done

# Summary
echo ""
echo "📊 Build Summary"
echo "================"

if [ ${#SUCCESSFUL_BUILDS[@]} -gt 0 ]; then
    echo "✅ Successful builds:"
    for platform in "${SUCCESSFUL_BUILDS[@]}"; do
        echo "   - $platform"
    done
fi

if [ ${#FAILED_BUILDS[@]} -gt 0 ]; then
    echo "❌ Failed/Unavailable builds:"
    for platform in "${FAILED_BUILDS[@]}"; do
        echo "   - $platform"
    done
fi

echo ""
echo "🎉 Multi-platform build process completed!"
echo "📁 All builds are organized in the platforms/ directory"
