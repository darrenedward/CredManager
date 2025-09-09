package database

import (
	"database/sql"
	"time"
)

// User represents a user in the system
type User struct {
	ID                int                `json:"id"`
	Email             string             `json:"email"`
	PassphraseHash    string             `json:"passphrase_hash"`
	SecurityQuestions []SecurityQuestion `json:"security_questions"`
	CreatedAt         time.Time          `json:"created_at"`
	UpdatedAt         time.Time          `json:"updated_at"`
}

// SecurityQuestion represents a security question
type SecurityQuestion struct {
	ID       int    `json:"id"`
	UserID   int    `json:"user_id"`
	Question string `json:"question"`
	Answer   string `json:"answer"`
	IsCustom bool   `json:"is_custom"`
}

// CreateUser creates a new user in the database
func CreateUser(db *sql.DB, email, passphraseHash string) (*User, error) {
	query := `
		INSERT INTO users (email, passphrase_hash, created_at, updated_at)
		VALUES (?, ?, ?, ?)
	`

	now := time.Now()
	result, err := db.Exec(query, email, passphraseHash, now, now)
	if err != nil {
		return nil, err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return nil, err
	}

	return &User{
		ID:             int(id),
		Email:          email,
		PassphraseHash: passphraseHash,
		CreatedAt:      now,
		UpdatedAt:      now,
	}, nil
}

// GetUserByEmail retrieves a user by email
func GetUserByEmail(db *sql.DB, email string) (*User, error) {
	query := `
		SELECT id, email, passphrase_hash, created_at, updated_at
		FROM users
		WHERE email = ?
	`

	user := &User{}
	err := db.QueryRow(query, email).Scan(
		&user.ID,
		&user.Email,
		&user.PassphraseHash,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return user, nil
}

// GetUserByID retrieves a user by ID
func GetUserByID(db *sql.DB, id int) (*User, error) {
	query := `
		SELECT id, email, passphrase_hash, created_at, updated_at
		FROM users
		WHERE id = ?
	`

	user := &User{}
	err := db.QueryRow(query, id).Scan(
		&user.ID,
		&user.Email,
		&user.PassphraseHash,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return user, nil
}
