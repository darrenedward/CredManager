package models

import "time"

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

// NewUser creates a new user instance
func NewUser(email, passphraseHash string) *User {
	now := time.Now()
	return &User{
		Email:          email,
		PassphraseHash: passphraseHash,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
}

// Validate validates user data
func (u *User) Validate() error {
	if u.Email == "" {
		return ErrInvalidEmail
	}
	if u.PassphraseHash == "" {
		return ErrInvalidPassphrase
	}
	return nil
}

// Common errors
var (
	ErrInvalidEmail      = NewValidationError("invalid email")
	ErrInvalidPassphrase = NewValidationError("invalid passphrase")
)

// ValidationError represents a validation error
type ValidationError struct {
	Message string
}

func NewValidationError(message string) *ValidationError {
	return &ValidationError{Message: message}
}

func (e *ValidationError) Error() string {
	return e.Message
}
