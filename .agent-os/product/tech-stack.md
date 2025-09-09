# Technical Stack

## Application Framework
- **Backend:** Go 1.21+ 
- **Frontend:** Flutter 3.13+ with Dart
- **Architecture:** Client-server with local communication

## Database System
- **Primary:** SQLite3 with encrypted storage
- **Encryption:** AES-256 encryption at rest
- **Migrations:** Goose database migration tool

## JavaScript Framework
- **Frontend:** Flutter/Dart (no JavaScript required)
- **Web Components:** N/A (desktop application)

## Import Strategy
- **Backend:** Go modules with standard import system
- **Frontend:** Dart packages with pub.dev dependencies
- **Build System:** Go build system + Flutter build tools

## CSS Framework
- **Frontend:** Flutter Material Design 3
- **Styling:** Flutter's built-in styling system
- **Theming:** Material You dynamic theming support

## UI Component Library
- **Primary:** Flutter Material Components
- **Additional:** Flutter Cupertino for iOS-style components (if needed)
- **Custom:** Custom Flutter widgets for specialized components

## Fonts Provider
- **Primary:** Google Fonts via Flutter google_fonts package
- **Fallback:** System fonts with font family fallbacks
- **Icons:** Material Design Icons

## Icon Library
- **Primary:** Material Design Icons
- **Custom:** Custom SVG icons for application-specific needs
- **Implementation:** Flutter vector_graphics or custom painting

## Application Hosting
- **Distribution:** Standalone binaries for each platform
- **Packaging:** Snap, Flatpak, or AppImage for Linux
- **Windows:** EXE installer with MSI packaging
- **macOS:** DMG package with notarization

## Database Hosting
- **Location:** Local filesystem storage
- **Path:** Platform-specific application data directories
- **Backup:** Encrypted backup files with user-controlled location

## Asset Hosting
- **Local:** Bundled with application binaries
- **Remote:** N/A (all assets local for security)
- **Updates:** Application self-update mechanism

## Deployment Solution
- **CI/CD:** GitHub Actions for automated builds
- **Testing:** Unit tests (Go test, Flutter test)
- **Packaging:** Goreleaser for Go, Flutter build for frontend
- **Distribution:** GitHub Releases with multiple platform support

## Code Repository URL
- **Primary:** GitHub repository (to be created)
- **Structure:** Monorepo with backend and frontend directories
- **License:** MIT License for open source development

## Development Tools
- **IDE:** VS Code with Go and Flutter extensions
- **Debugging:** Delve for Go, Flutter DevTools for frontend
- **Testing:** Go test, Flutter test, integration tests
- **Linting:** golangci-lint, dart analyze, flutter analyze

## Security Components
- **Encryption:** Go crypto package with AES-256-GCM
- **Key Derivation:** Argon2 for passphrase key derivation
- **Secure Storage:** Encrypted SQLite using SQLCipher-like approach
- **Session Management:** JWT tokens with configurable expiration

## Communication Protocol
- **Backend-Frontend:** REST API with JSON over HTTP/HTTPS
- **Local Server:** Go HTTP server running on localhost
- **Port Management:** Dynamic port allocation with fallback

## Platform Support
- **Primary:** Linux (various distributions)
- **Secondary:** Windows 10/11, macOS 10.15+
- **Architectures:** x86_64, arm64 (Apple Silicon support)

## Dependencies
- **Go Backend:**
  - github.com/mattn/go-sqlite3 - SQLite3 driver
  - golang.org/x/crypto - Encryption utilities
  - github.com/golang-jwt/jwt - JWT token handling
  - github.com/gorilla/mux - HTTP router

- **Flutter Frontend:**
  - http - HTTP client for API communication
  - shared_preferences - Local storage for settings
  - flutter_secure_storage - Secure credential storage
  - provider - State management
  - google_fonts - Typography styling