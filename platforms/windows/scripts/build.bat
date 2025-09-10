@echo off
REM Windows Build Script for Credential Manager
REM This script builds the Flutter app for Windows and organizes outputs

echo 🪟 Building Credential Manager for Windows...

REM Navigate to frontend directory
cd /d "%~dp0\..\..\..\frontend"

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get

REM Build for Windows
echo 🔨 Building for Windows...
flutter build windows --release

REM Create build timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "BUILD_TIME=%dt:~0,8%_%dt:~8,6%"
set "BUILD_DIR=..\platforms\windows\builds\release_%BUILD_TIME%"

REM Create build directory
mkdir "%BUILD_DIR%" 2>nul

REM Copy build artifacts
echo 📁 Copying build artifacts to platforms directory...
xcopy /E /I /Y "build\windows\x64\runner\Release\*" "%BUILD_DIR%\"

REM Create version info
echo 📝 Creating version info...
(
echo Build Information
echo =================
echo Platform: Windows x64
echo Build Type: Release
echo Build Time: %date% %time%
flutter --version | findstr /C:"Flutter"
dart --version
) > "%BUILD_DIR%\build_info.txt"

REM Create symlink to latest build (requires admin privileges)
cd /d "%~dp0\..\builds"
if exist latest rmdir latest
mklink /D latest "release_%BUILD_TIME%" 2>nul || (
    echo Note: Could not create 'latest' symlink. Run as administrator for this feature.
)

echo ✅ Windows build completed successfully!
echo 📍 Build location: platforms\windows\builds\release_%BUILD_TIME%
echo 🔗 Latest build: platforms\windows\builds\latest
