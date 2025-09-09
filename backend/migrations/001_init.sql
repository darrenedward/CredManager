-- Initial database schema for API Key Manager

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    passphrase_hash TEXT NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
);

-- Create security_questions table
CREATE TABLE IF NOT EXISTS security_questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    question TEXT NOT NULL,
    answer_hash TEXT NOT NULL,
    is_custom BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create setup_flags table
CREATE TABLE IF NOT EXISTS setup_flags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    flag_name TEXT UNIQUE NOT NULL,
    flag_value BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_security_questions_user_id ON security_questions(user_id);
CREATE INDEX IF NOT EXISTS idx_setup_flags_name ON setup_flags(flag_name);

-- Insert predefined security questions
INSERT OR IGNORE INTO security_questions (user_id, question, answer_hash, is_custom, created_at, updated_at)
VALUES
    (0, 'What was the name of your first pet?', '', 0, datetime('now'), datetime('now')),
    (0, 'What is your mother''s maiden name?', '', 0, datetime('now'), datetime('now')),
    (0, 'What was the name of your first school?', '', 0, datetime('now'), datetime('now')),
    (0, 'What is your favorite book?', '', 0, datetime('now'), datetime('now')),
    (0, 'What city were you born in?', '', 0, datetime('now'), datetime('now'));