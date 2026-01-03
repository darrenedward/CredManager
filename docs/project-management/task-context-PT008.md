# Task Context: PT008 - Fix Duplicate Continue Buttons on Setup/Login Screens

## User Issue
User reported seeing two separate "Continue" buttons underneath the passphrase field on the login/setup screens.

## Investigation Findings
- The issue occurs on the setup screen where the passphrase step is part of a Flutter Stepper widget.
- The `AuthForm` widget contains its own "Continue" button (lines 70-82 in auth_form.dart).
- The Stepper widget also provides its own "Continue" button in the controls section (lines 443-450 in setup_screen.dart).
- This results in two buttons appearing below the passphrase input fields.
- The `AuthForm` button is non-functional when used in the setup screen (no `onSubmit` callback provided).
- In login and reset passphrase screens, the `AuthForm` button is functional and appropriate.

## Root Cause
The `AuthForm` widget always displays a "Continue" button regardless of whether an `onSubmit` callback is provided, leading to duplicate buttons when used within stepper-based navigation.

## Proposed Solution
Modify the `AuthForm` widget to conditionally render the "Continue" button only when the `onSubmit` callback is provided. This will:
- Remove the useless button from the setup screen (stepper handles navigation).
- Keep the functional button in login and reset passphrase screens.
- Maintain clean UI without duplicate buttons.

## Acceptance Criteria
- Setup screen shows only one "Continue" button (from stepper controls).
- Login screen shows only one "Continue" button (from AuthForm).
- Reset passphrase screen shows only one "Continue" button (from AuthForm).
- No functional changes to existing behavior.
- UI appears clean without duplicate buttons.

## Files to Modify
- `frontend/lib/widgets/auth_form.dart`: Add conditional rendering for the Continue button.

## Testing Requirements
- Verify setup screen stepper navigation works correctly.
- Verify login screen button functionality.
- Verify reset passphrase screen button functionality.
- Check UI on different screen sizes.

## Interaction Mode
YOLO MVP