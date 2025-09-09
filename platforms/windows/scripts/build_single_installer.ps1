# Single Windows Installer - Complete Cred Manager
# Creates ONE installer that includes both Go backend AND Flutter frontend

param(
    [string]$Version = "1.0.0",
    [string]$OutputDir = "..\..\binaries"
)

Write-Host "🔨 Building SINGLE Windows Installer for Cred Manager..." -ForegroundColor Green
Write-Host "📦 This will create ONE installer with BOTH Go backend AND Flutter frontend" -ForegroundColor Cyan
Write-Host ""

# Configuration
$APP_NAME = "Cred Manager"
$VERSION = $Version
$OUTPUT_DIR = $OutputDir
$BUILD_DIR = "..\builds"
$SCRIPTS_DIR = $PSScriptRoot

# Inno Setup paths (update these paths for your system)
$INNO_SETUP_PATH = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
$INNO_SETUP_URL = "https://jrsoftware.org/download.php/is.exe"

# Colors for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Blue }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    # Check Go
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Write-Error "Go is not installed. Please install Go from https://golang.org/dl/"
        exit 1
    }

    # Check Flutter
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Error "Flutter is not installed. Please install Flutter from https://flutter.dev/docs/get-started/install/windows"
        exit 1
    }

    # Check Inno Setup
    if (-not (Test-Path $INNO_SETUP_PATH)) {
        Write-Warning "Inno Setup not found at: $INNO_SETUP_PATH"
        Write-Info "Please download and install Inno Setup from: $INNO_SETUP_URL"
        Write-Info "Or update the INNO_SETUP_PATH variable in this script"
        exit 1
    }

    Write-Success "All prerequisites found"
}

# Build Go backend - REMOVED: Backend no longer needed, app is fully local
function Build-GoBackend {
    Write-Info "Skipping Go backend build - app is now fully local with integrated security"
    Write-Success "Backend removal completed - no network ports opened"
}

# Build Flutter frontend
function Build-FlutterFrontend {
    Write-Info "Building Flutter frontend..."

    Push-Location ..\..\..\frontend

    try {
        # Enable Windows desktop
        flutter config --enable-windows-desktop

        # Clean and build
        flutter clean
        flutter pub get

        if (flutter build windows --release) {
            Write-Success "Flutter frontend built successfully"
            $buildPath = "build\windows\x64\runner\Release"
            if (Test-Path $buildPath) {
                $items = Get-ChildItem $buildPath -Recurse | Measure-Object
                Write-Info "Frontend build size: ~$($items.Count) files"
            }
        } else {
            Write-Error "Flutter frontend build failed"
            exit 1
        }
    } finally {
        Pop-Location
    }
}

# Create installer directory structure
function New-InstallerStructure {
    Write-Info "Creating installer directory structure..."

    $installerDir = "$BUILD_DIR\installer"
    if (Test-Path $installerDir) {
        Remove-Item $installerDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $installerDir | Out-Null

    # Skip Go backend - REMOVED: App is fully local
    Write-Info "Skipping Go backend copy - app is fully local with integrated security"

    # Copy Flutter frontend
    Write-Info "Copying Flutter frontend..."
    $flutterBuildPath = "..\..\..\frontend\build\windows\x64\runner\Release"
    if (Test-Path $flutterBuildPath) {
        Copy-Item "$flutterBuildPath\*" "$installerDir\" -Recurse -Force
    } else {
        Write-Error "Flutter build not found at: $flutterBuildPath"
        exit 1
    }

    # Create startup script
    Write-Info "Creating startup script..."
    New-StartupScript -InstallerDir $installerDir

    # Create desktop shortcut
    Write-Info "Creating desktop shortcut..."
    New-DesktopShortcut -InstallerDir $installerDir

    Write-Success "Installer structure created"
    Write-Info "Installer contents:"
    Get-ChildItem $installerDir | Select-Object Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB, 2)}} | Format-Table -AutoSize
}

# Create startup script
function New-StartupScript {
    param([string]$InstallerDir)

    $startupScript = @"
@echo off
REM Cred Manager Startup Script
REM Launches Flutter frontend (fully local with integrated security)

echo Starting Cred Manager...
echo.

REM Set working directory to installation path
cd /d "%~dp0"

REM Start Flutter frontend
echo Starting Cred Manager application...
start "" "cred-manager.exe"

REM Exit this script
exit
"@

    $startupScript | Out-File -FilePath "$InstallerDir\start-cred-manager.bat" -Encoding ASCII
    Write-Success "Startup script created"
}

# Create desktop shortcut
function New-DesktopShortcut {
    param([string]$InstallerDir)

    $shortcutScript = @"
@echo off
REM Create desktop shortcut for Cred Manager

set "TARGET=%~dp0start-cred-manager.bat"
set "SHORTCUT=%USERPROFILE%\Desktop\Cred Manager.lnk"
set "ICON=%~dp0cred-manager.exe"
set "DESCRIPTION=Secure API Key Management"

echo Creating desktop shortcut...
powershell -Command "& {
    \$WshShell = New-Object -comObject WScript.Shell;
    \$Shortcut = \$WshShell.CreateShortcut('%SHORTCUT%');
    \$Shortcut.TargetPath = '%TARGET%';
    \$Shortcut.IconLocation = '%ICON%';
    \$Shortcut.Description = '%DESCRIPTION%';
    \$Shortcut.Save();
}"
echo Desktop shortcut created!
pause
"@

    $shortcutScript | Out-File -FilePath "$InstallerDir\create-shortcut.bat" -Encoding ASCII
    Write-Success "Desktop shortcut script created"
}

# Create Inno Setup script
function New-InnoSetupScript {
    Write-Info "Creating Inno Setup script..."

    $innoScript = @"
; Inno Setup Script for Cred Manager - SINGLE INSTALLER
; This creates ONE installer with both Go backend AND Flutter frontend

#define MyAppName "Cred Manager"
#define MyAppVersion "$VERSION"
#define MyAppPublisher "Darren Edward House of Jones"
#define MyAppURL "https://github.com/yourusername/cred-manager"
#define MyAppExeName "start-cred-manager.bat"

[Setup]
AppId={{CRED-MANAGER-SINGLE-INSTALLER}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=LICENSE
OutputDir=$OUTPUT_DIR
OutputBaseFilename=CredManager-Setup-{#MyAppVersion}
SetupIconFile=cred-manager.exe
Compression=lzma
SolidCompression=yes
WizardStyle=modern
Uninstallable=yes
CreateUninstallRegKey=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "$BUILD_DIR\installer\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\cred-manager.exe"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\cred-manager.exe"

[Run]
Filename: "{app}\create-shortcut.bat"; Description: "Create desktop shortcut"; Flags: postinstall skipifsilent runhidden

[UninstallRun]
Filename: "taskkill"; Parameters: "/f /im cred-manager.exe"; Flags: runhidden

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then begin
    // Create start menu shortcut
    CreateShellLink(
      ExpandConstant('{autoprograms}\{#MyAppName}\{#MyAppName}.lnk'),
      'Cred Manager',
      ExpandConstant('{app}\{#MyAppExeName}'),
      '',
      ExpandConstant('{app}\cred-manager.exe'),
      0,
      SW_SHOWNORMAL,
      ExpandConstant('{app}\cred-manager.exe')
    );
  end;
end;
"@

    $innoScript | Out-File -FilePath "$BUILD_DIR\installer.iss" -Encoding UTF8
    Write-Success "Inno Setup script created"
}

# Build installer
function New-Installer {
    Write-Info "Building Windows installer..."

    if (-not (Test-Path $INNO_SETUP_PATH)) {
        Write-Error "Inno Setup not found at: $INNO_SETUP_PATH"
        Write-Info "Please install Inno Setup from: $INNO_SETUP_URL"
        exit 1
    }

    $innoScriptPath = "$BUILD_DIR\installer.iss"
    if (-not (Test-Path $innoScriptPath)) {
        Write-Error "Inno Setup script not found: $innoScriptPath"
        exit 1
    }

    Write-Info "Compiling installer with Inno Setup..."
    $process = Start-Process -FilePath $INNO_SETUP_PATH -ArgumentList "`"$innoScriptPath`"" -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0) {
        Write-Success "Windows installer created successfully!"

        # Show installer info
        $installerPath = "$OUTPUT_DIR\CredManager-Setup-$VERSION.exe"
        if (Test-Path $installerPath) {
            $size = (Get-Item $installerPath).Length / 1MB
            Write-Info "Installer location: $installerPath"
            Write-Info "Installer size: $([math]::Round($size, 2)) MB"
        }

        Write-Info "Installer contents:"
        Write-Info "- ✅ Flutter frontend with integrated Argon2 security (cred-manager.exe + DLLs)"
        Write-Info "- ✅ Local-only operation (no network ports)"
        Write-Info "- ✅ Startup script (start-cred-manager.bat)"
        Write-Info "- ✅ Desktop shortcut creator"
        Write-Info "- ✅ Uninstaller"

    } else {
        Write-Error "Installer compilation failed with exit code: $($process.ExitCode)"
        exit 1
    }
}

# Main build process
function Main {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "🔨 BUILDING SINGLE WINDOWS INSTALLER" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    Test-Prerequisites
    Write-Host ""

    Build-GoBackend
    Write-Host ""

    Build-FlutterFrontend
    Write-Host ""

    New-InstallerStructure
    Write-Host ""

    New-InnoSetupScript
    Write-Host ""

    New-Installer
    Write-Host ""

    Write-Host "==========================================" -ForegroundColor Green
    Write-Success "SINGLE INSTALLER BUILD COMPLETE!"
    Write-Info "Your complete Windows installer is ready!"
    Write-Info "Location: $OUTPUT_DIR\CredManager-Setup-$VERSION.exe"
    Write-Host "==========================================" -ForegroundColor Green

    Write-Host ""
    Write-Info "What this installer includes:"
    Write-Host "  ✅ Flutter Frontend with Argon2 Security" -ForegroundColor Green
    Write-Host "  ✅ Local-Only Operation (Zero Network Exposure)" -ForegroundColor Green
    Write-Host "  ✅ Military-Grade Password Hashing" -ForegroundColor Green
    Write-Host "  ✅ Automatic Startup Script" -ForegroundColor Green
    Write-Host "  ✅ Desktop Shortcuts" -ForegroundColor Green
    Write-Host "  ✅ Windows Integration" -ForegroundColor Green
    Write-Host "  ✅ Professional Uninstaller" -ForegroundColor Green

    Write-Host ""
    Write-Success "SECURE local-only installer! 🔐 No network ports opened!"
}

# Run main function
Main