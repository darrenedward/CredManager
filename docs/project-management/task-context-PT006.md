# Task Context: PT006 - Login Screen UI Fixes and Secret Questions Investigation

## User Request
- Remove the shorter continue button on the login screen (likely the biometric button)
- Ensure the wider continue button is navy/dark blue (already is Color(0xFF0f172a))
- Investigate why secret questions are not showing up after clicking continue after entering passphrase

## Current State Analysis
- **Login Screen Structure**:
  - Main passphrase input field with Continue button (width: double.infinity, color: AppConstants.primaryColor = navy blue)
  - Biometric authentication button (narrower, conditional display)
  - "Forgot Passphrase?" text button

- **Security Questions Usage**:
  - Only used during initial setup (setup_screen.dart)
  - Only used during passphrase recovery (recovery_screen.dart)
  - No implementation for showing security questions after login for additional verification

- **Color Constants**:
  - primaryColor: Color(0xFF0f172a) // Navy Blue - already correct
  - Continue button already uses primaryColor

## Investigation Points
- Check if there's any intended flow for security questions post-login
- Verify biometric button removal doesn't break functionality
- Confirm button styling is consistent

## Expected Deliverables
- Updated login_screen.dart with biometric button removed
- Confirmation that Continue button is navy/dark blue
- Analysis of security questions flow and any missing implementation
- Code review for any related bugs

## Dependencies
- None

## Acceptance Criteria
- Biometric button removed from login screen
- Continue button confirmed to be navy/dark blue
- Clear explanation of security questions behavior
- No breaking changes to login functionality