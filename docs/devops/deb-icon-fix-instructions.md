# Cred Manager DEB Icon Fix Instructions

## Summary
The DEB package now includes the correct shield icon (`shield_icon.svg`) for Linux desktop integration. The desktop file references the icon as `cred-manager`, matching the SVG filename in the scalable icon directory.

## Installation Steps

1. **Uninstall any previous version (if installed):**
   ```sh
   sudo apt remove cred-manager
   ```

2. **Install the updated package:**
   ```sh
   cd platforms/linux/binaries
   sudo dpkg -i cred-manager_1.0.0_amd64.deb
   ```

3. **Update desktop and icon caches (recommended):**
   ```sh
   sudo update-desktop-database
   sudo gtk-update-icon-cache -f /usr/share/icons/hicolor/
   ```

4. **Log out and log back in, or restart your system menu, to refresh the icon display.**

## Verification

- The icon file is installed at:
  ```
  /usr/share/icons/hicolor/scalable/apps/cred-manager.svg
  ```
- The desktop entry references:
  ```
  Icon=cred-manager
  ```
- The system menu should now show the shield icon for Cred Manager.

## Troubleshooting

- If the old icon still appears, clear icon caches and restart your session.
- Ensure no legacy icon files remain in `/usr/share/icons/hicolor/scalable/apps/` or `/usr/share/icons/hicolor/512x512/apps/`.

## Notes

- The SVG format is preferred for modern Linux desktop environments.
- No legacy PNG icon is shipped; only the new shield SVG is included.
