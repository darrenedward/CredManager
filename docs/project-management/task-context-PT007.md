# Task Context: PT007 - Implement Hybrid Biometric Flow

## User Request
Implement a hybrid biometric authentication approach where:
- Users must always enter passphrase first (primary security)
- If biometrics is available on device, offer optional biometric setup during initial login/setup
- Biometric becomes a convenience feature for quick unlock after passphrase authentication
- Users can enable/disable biometrics in settings at any time

## Current State Analysis
- **Current Implementation**:
  - Biometric button removed from login screen (PT006 completed)
  - Settings screen has biometric toggle but not connected to functionality
  - Biometric service exists but needs updating for new flow

- **Target Implementation**:
  - **Setup Flow**: During initial setup, if device has biometrics, show optional setup prompt
  - **Login Flow**: Always require passphrase, biometric as optional quick unlock
  - **Settings**: Enable/disable biometric authentication
  - **Security**: Passphrase always required first, biometric as secondary convenience

## Required Changes
1. **Setup Screen**: Add optional biometric setup prompt if device supports it
2. **Settings Screen**: Connect biometric toggle to actual enable/disable functionality
3. **AuthState**: Update biometric methods for configuration, not login
4. **BiometricAuthService**: Refactor for configuration and quick unlock
5. **Storage**: Ensure biometric settings persist correctly
6. **Login Screen**: Clean up any remaining biometric code

## User Flow
1. **First Time Setup**:
   - User creates passphrase and security questions
   - If device has biometrics available → Show optional biometric setup
   - User can enable or skip biometric setup
   - Complete setup

2. **Subsequent Logins**:
   - Always enter passphrase first
   - If biometric enabled → Can use biometric for quick unlock
   - Settings allow enable/disable biometric at any time

## Files to Modify
- `frontend/lib/screens/setup_screen.dart` - Add biometric setup option
- `frontend/lib/screens/settings_screen.dart` - Connect toggle to functionality
- `frontend/lib/models/auth_state.dart` - Update biometric methods
- `frontend/lib/services/biometric_auth_service.dart` - Refactor for new flow
- `frontend/lib/screens/login_screen.dart` - Final cleanup

## Acceptance Criteria
- Passphrase always required for initial authentication
- Biometric setup offered optionally during initial setup if device supports it
- Biometric works as quick unlock after passphrase login
- Settings toggle properly enables/disables biometric functionality
- Clean, intuitive user experience
- No breaking changes to existing security model

## Dependencies
- PT006 completion (biometric button removal)

## Expected Outcome
Balanced security and convenience: strong passphrase security with optional biometric convenience for supported devices.