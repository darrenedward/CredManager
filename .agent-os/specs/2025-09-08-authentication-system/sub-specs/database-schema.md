# Local Storage Schema

This is the local storage schema implementation for the spec detailed in @.agent-os/specs/2025-09-08-authentication-system/spec.md. All data is stored locally with no server dependencies.

## Storage Structure

### Data Entities
- **users** - Main user authentication data
- **security_questions** - Security questions for passphrase recovery
- **sessions** - Active user sessions for timeout management

### Data Fields
- **users.encrypted_passphrase** - Argon2-hashed passphrase
- **users.salt** - Unique salt for passphrase hashing
- **security_questions.question_type** - Distinguishes predefined vs custom questions
- **sessions.expires_at** - Session expiration timestamp

### Storage Characteristics
- Encryption of all authentication-related data at rest using platform-specific secure storage
- Efficient data access patterns optimized for local storage
- Data relationships maintained through local identifiers

### Implementation
```sql
-- Create users table
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    encrypted_passphrase TEXT NOT NULL,
    salt TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create security_questions table
CREATE TABLE security_questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    answer_hash TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('predefined', 'custom')),
    question_order INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Create sessions table
CREATE TABLE sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    token TEXT NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX idx_sessions_token ON sessions(token);
CREATE INDEX idx_sessions_expires ON sessions(expires_at);
CREATE INDEX idx_security_questions_user ON security_questions(user_id);
```

## Specifications

### Data Organization
- **users:** Stores minimal authentication data with strong encryption
- **security_questions:** Encrypted question answers with type differentiation
- **sessions:** JWT token storage with automatic expiration handling

### Data Integrity
- Unique constraints on session tokens
- Referential integrity maintained through foreign key relationships
- Data consistency ensured through transactional operations
- Type validation enforced through check constraints

### Data Relationships
- security_questions.user_id → users.id (CASCADE delete)
- sessions.user_id → users.id (CASCADE delete)

## Rationale

### Security Considerations
- **Argon2 Hashing:** Chosen for resistance to GPU and side-channel attacks
- **Unique Salts:** Each user gets unique salt to prevent rainbow table attacks
- **Encrypted Answers:** Security question answers are hashed, not stored plaintext
- **Platform Security:** Utilization of platform-specific secure storage mechanisms
- **Local Only:** No network transmission of authentication data

### Performance Considerations
- **Efficient Access:** Optimized for local file-based storage
- **Minimal Overhead:** Only essential data fields to reduce storage footprint
- **Fast Queries:** Optimized for common local authentication patterns

### Data Integrity Rules
- **Question Order Preservation:** question_order ensures consistent recovery flow
- **Session Expiration:** Automatic cleanup of expired sessions
- **Type Validation:** question_type restricted to valid values only
- **Local Consistency:** Data integrity maintained without server coordination

## Data Initialization

All data is initialized locally during first-time setup. No external data seeding required.

### Initial Data
```sql
-- Insert predefined security questions
INSERT INTO security_questions (question_text, question_type, question_order) VALUES
('What was the name of your first pet?', 'predefined', 1),
('What city were you born in?', 'predefined', 2),
('What is your mother''s maiden name?', 'predefined', 3),
('What was the name of your elementary school?', 'predefined', 4),
('What was your childhood nickname?', 'predefined', 5);
```

### Test Data Approach
- Use realistic but non-sensitive test data
- Ensure all question types are represented in test data
- Include edge cases (empty strings, maximum lengths)
- Test both predefined and custom question workflows
- All test data stored locally with no external dependencies