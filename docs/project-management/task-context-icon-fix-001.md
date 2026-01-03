# Task Context: Icon Fix (icon-fix-001)

## User Request
The user reported: "for some reason the icon is still the ugly old white icon showing when i search cred in the system menu the ugly white icon is showing and not the new icon we created"

## Details
- New icon location: `frontend/assets/icons/shield_icon.svg`
- Issue: System menu search for "cred" shows old white icon instead of new shield icon
- Platform: Linux (Debian packaging)
- Interaction Mode: YOLO MVP

## Relevant Files
- `docs/debian/cred-manager.metainfo.xml`
- `docs/debian/cred-manager.1`
- `platforms/linux/scripts/build_complete_deb.sh`
- `frontend/pubspec.yaml`
- `frontend/assets/icons/shield_icon.svg`

## Expected Outcome
The system menu should display the new shield icon when searching for the cred-manager application.