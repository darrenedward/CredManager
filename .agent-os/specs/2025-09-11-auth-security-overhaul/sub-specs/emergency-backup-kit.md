# Technical Spec: Emergency Backup Passphrase Kit

> Parent Spec: Auth Security Overhaul
> Feature: PT006 - Emergency Backup Passphrase Kit
> Created: 2025-01-03

## Overview

Implement an emergency backup passphrase system that provides users with a secure recovery mechanism if they forget their master passphrase. Following industry best practices from 1Password Emergency Kit and Bitwarden Emergency Sheet, this feature generates a printable PDF document with a cryptographically secure backup code, QR code option, and clear storage guidance.

## User Stories

### Emergency Kit Generation
As a user setting up the app, I want to generate a printable emergency kit with a backup recovery code, so that if I forget my master passphrase, I can still access my credentials without losing data.

**Detailed Workflow:**
1. User navigates to Settings → Security → Emergency Kit
2. System generates a cryptographically random 256-bit backup code (encoded as readable words/base32)
3. User can preview the emergency kit PDF with branding, instructions, and backup code
4. User downloads PDF and/or prints it directly
5. System stores encrypted hash of backup code in database for verification
6. User confirms they've stored it safely

### Backup Code Recovery
As a user who has forgotten their master passphrase, I want to use my emergency backup code to reset my passphrase, so that I can regain access to my credentials.

**Detailed Workflow:**
1. User clicks "Forgot Passphrase" on login screen
2. System presents two recovery options: Security Questions OR Backup Code
3. User selects "Backup Code" and enters their emergency code
4. System verifies the code against the stored hash
5. User creates a new master passphrase
6. System re-encrypts all data with new passphrase
7. Old backup code is invalidated; user must generate new emergency kit

### Onboarding Integration
As a new user, I want to be prompted to create an emergency kit during setup, so that I don't forget this critical safety step.

**Detailed Workflow:**
1. After completing initial setup (passphrase + security questions)
2. System presents "Create Emergency Kit" screen
3. User can "Create Now" or "Remind Me Later"
4. If "Later", system shows periodic reminders in settings
5. Emergency kit marked as "not created" until user completes

## Technical Requirements

### Backup Code Generation

**Format:** Word-based (BIP39-style) or Base32 for readability
**Entropy:** 256 bits (32 bytes) cryptographically secure random
**Encoding Options:**
- Option 1: 24-word mnemonic (BIP39 wordlist, 256-bit entropy)
- Option 2: Base32 encoded with checksum (RFC 4648)
- Option 3: 6 groups of 4 characters for readability

**Storage:**
- Code hashed with Argon2id before storing in database
- Separate from master passphrase hash
- Cannot be retrieved, only verified

### PDF Generation

**Content Sections:**
1. Header with app name, branding, and "EMERGENCY KIT" label
2. Instructions: "Keep this document safe and secure"
3. Backup code (large, readable font)
4. QR code encoding the backup code (optional, for mobile users)
5. How to use this kit instructions
6. Safe storage guidance (bullet points)
7. Security warning: "Anyone with this code can access your vault"
8. Footer with generation date and app version

**Security Considerations:**
- PDF generated locally (no network transmission)
- No copy-paste protection (user needs to be able to store it)
- Watermark with "UNAUTHORIZED ACCESS WARNING"

### QR Code Generation

**Format:** QR Code version 4+ (depends on data size)
**Error Correction:** Level H (High, ~30% redundancy)
**Data:** Encodes the backup code (plaintext for scanning)
**Fallback:** If QR code is too large, fall back to shorter encoding

### Database Schema Changes

```sql
-- New table for backup codes
CREATE TABLE emergency_backup_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code_hash TEXT NOT NULL UNIQUE,        -- Argon2id hash of backup code
  salt TEXT NOT NULL,                     -- Salt for Argon2 hashing
  created_at INTEGER NOT NULL,            -- Unix timestamp
  is_used INTEGER DEFAULT 0,              -- 0 = active, 1 = used/invalid
  used_at INTEGER,                        -- When it was redeemed
  device_identifier TEXT                  -- Optional device fingerprint
);

-- Metadata table flag
ALTER TABLE metadata ADD COLUMN emergency_kit_created INTEGER DEFAULT 0;
ALTER TABLE metadata ADD COLUMN emergency_kit_created_at INTEGER;
```

## Security Best Practices

### Backup Code Properties

1. **High Entropy:** 256 bits ensures brute-force is impractical
2. **No Derivation:** Independent from master passphrase (single point of failure prevention)
3. **One-Time Use:** Invalidated after redemption; must generate new kit
4. **Separate Storage:** Hash stored in DB, not tied to passphrase encryption

### Safe Storage Guidance (in PDF)

**DO:**
- Store in a secure physical location (safe, lockbox)
- Keep multiple copies in different locations
- Consider a bank safety deposit box
- Store separately from your device
- Mark as "CONFIDENTIAL - EMERGENCY BACKUP"

**DON'T:**
- Don't store in the same location as your device
- Don't share photos or digital copies
- Don't upload to cloud storage
- Don't leave unencrypted on computer
- Don't share with anyone unless absolutely necessary

### User Flow Protection

1. **Rate Limiting:** 3 backup code attempts, 10-minute lockout
2. **Invalidation:** Old code immediately invalidated after successful redemption
3. **Re-creation Required:** User must create new emergency kit after reset
4. **Audit Logging:** Log all redemption attempts (with timestamp)

## UI/UX Requirements

### Emergency Kit Screen

**Navigation:** Settings → Security → Emergency Kit

**States:**
1. **Not Created:** Show "Create Emergency Kit" CTA with explanation
2. **Preview:** Show PDF preview with download/print buttons
3. **Created:** Show "View Emergency Kit", "Create New Kit" options
4. **Redeemed:** Show "Previous Kit Used - Create New Kit" warning

**Actions:**
- "Generate Emergency Kit" button
- "Download PDF" button
- "Print PDF" button
- "I've Stored It Safely" confirmation

### Recovery Screen Updates

**Current Flow:** Login → Forgot Passphrase → Security Questions

**New Flow:** Login → Forgot Passphrase → [Security Questions] OR [Backup Code]

**Backup Code Input:**
- 6 text entry groups (for word-based or character-based format)
- Auto-advance between groups
- Show/hide toggle option
- Clear error messaging

### Onboarding Integration

**Placement:** After security questions setup

**Screen Content:**
- Title: "Create Your Emergency Kit"
- Explanation: "If you forget your master passphrase, this backup code can help you recover your data"
- Preview of what the kit looks like
- "Create Now" (primary) / "Remind Me Later" (secondary)

**Reminders:**
- Settings banner: "⚠️ Emergency kit not created"
- Dashboard widget (dismissible)
- No more than once per week

## Implementation Tasks

See tasks.md PT006 subtasks (ST037-ST046)

## Testing Requirements

### Unit Tests

1. **Backup Code Generation**
   - Verify 256-bit entropy generation
   - Test encoding/decoding (word-based, base32)
   - Validate uniqueness across generations

2. **Hash Verification**
   - Argon2 hashing of backup codes
   - Correct code verification
   - Incorrect code rejection

3. **QR Code Encoding**
   - Correct encoding of backup code
   - QR scannability validation
   - Fallback to shorter encoding if needed

### Integration Tests

1. **Full Emergency Kit Flow**
   - Generate → Download → Verify code
   - Invalidate → Generate new kit

2. **Recovery Flow**
   - Forgot passphrase → Enter backup code → Reset passphrase
   - Verify old code is invalidated
   - Verify new passphrase works

3. **Rate Limiting**
   - 3 failed attempts → lockout
   - Lockout expires after 10 minutes

### Security Tests

1. **Brute Force Resistance**
   - Verify Argon2 parameters are secure
   - Measure verification time (should be >100ms)

2. **Code Uniqueness**
   - Generate 10,000 codes, verify no duplicates
   - Verify no correlation with master passphrase

3. **Data Recovery**
   - After passphrase reset, verify all data accessible
   - Verify old passphrase no longer works

## Dependencies

- PT003 (Dynamic Secrets) - Uses Argon2Service for hashing
- PDF generation package (e.g., `pdf` or `printing` packages)
- QR code generation package (e.g., `qr_flutter`)

## Success Criteria

1. User can generate emergency kit with cryptographically secure backup code
2. PDF is printable and contains all required sections
3. QR code successfully encodes and decodes backup code
4. Backup code successfully resets master passphrase
5. Old backup code is invalidated after redemption
6. Rate limiting prevents brute force attacks
7. All tests pass (unit, integration, security)

## Out of Scope

- Cloud storage of emergency kit (user can do this manually)
- Multi-signature or shamir's secret sharing (future enhancement)
- Biometric unlock for emergency kit (adds complexity)
- Automatic regeneration (user must manually create)
