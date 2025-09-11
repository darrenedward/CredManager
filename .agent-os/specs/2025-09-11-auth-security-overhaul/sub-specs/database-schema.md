
# Database Schema

This is the database schema implementation for the spec detailed in .agent-os/specs/2025-09-11-auth-security-overhaul/spec.md

## Schema Changes

### New/Modified Tables
- **app_metadata** (extended from existing):
  - New columns:
    - encrypted_passphrase_hash TEXT (stores AES-encrypted Argon2 hash of passphrase; key derived from passphrase itself for bootstrap).
    - encrypted_jwt_token TEXT (AES-encrypted JWT for session persistence).
    - is_first_time INTEGER DEFAULT 1 (0=false, 1=true; migrate from prefs).
    - setup_completed INTEGER DEFAULT 0