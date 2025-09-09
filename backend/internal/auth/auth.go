package auth

import (
	"database/sql"
	"errors"
	"strings"

	"api-key-manager/internal/models"
)

// Service handles authentication operations
type Service struct {
	db *sql.DB
}

// NewService creates a new authentication service
func NewService(db *sql.DB) *Service {
	return &Service{db: db}
}

// IsFirstTimeSetup checks if the application has been set up
func (s *Service) IsFirstTimeSetup() (bool, error) {
	// Check if user table has any records
	var count int
	err := s.db.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return true, nil
		}
		return false, err
	}
	return count == 0, nil
}

// IsFirstTimeUser checks if this is the first time the application is being used
func IsFirstTimeUser(db *sql.DB) (bool, error) {
	// Check if user table has any records
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
	if err != nil {
		return false, err
	}
	return count == 0, nil
}

// UserExists checks if a user with the given email exists
func UserExists(db *sql.DB, email string) (bool, error) {
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM users WHERE email = ?", email).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// IsFirstTimeSetupFlagSet checks if the first time setup flag is set
func IsFirstTimeSetupFlagSet(db *sql.DB) (bool, error) {
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM setup_flags WHERE flag_name = 'first_time_setup_completed' AND flag_value = 1").Scan(&count)
	if err != nil {
		// If the table doesn't exist, we assume setup is not complete
		// Check if it's a table not found error
		// For SQLite, this would be "no such table"
		if strings.Contains(err.Error(), "no such table") {
			return false, nil
		}
		// For other errors, return the error
		return false, err
	}
	return count > 0, nil
}

// ValidatePassphrase validates passphrase requirements
func (s *Service) ValidatePassphrase(passphrase string) error {
	if len(passphrase) < 12 {
		return errors.New("passphrase must be at least 12 characters long")
	}
	
	// Check for at least one uppercase letter
	hasUpper := false
	// Check for at least one lowercase letter
	hasLower := false
	// Check for at least one digit
	hasDigit := false
	
	for _, char := range passphrase {
		if char >= 'A' && char <= 'Z' {
			hasUpper = true
		} else if char >= 'a' && char <= 'z' {
			hasLower = true
		} else if char >= '0' && char <= '9' {
			hasDigit = true
		}
	}
	
	if !hasUpper || !hasLower || !hasDigit {
		return errors.New("passphrase must contain at least one uppercase letter, one lowercase letter, and one digit")
	}
	
	return nil
}

// CreateUser creates a new user with the given email and passphrase
func (s *Service) CreateUser(email, passphrase string) error {
	// Hash passphrase
	hashedPassphrase, err := HashPassword(passphrase, nil)
	if err != nil {
		return err
	}

	// Create user in database
	_, err = s.db.Exec(`INSERT INTO users (email, passphrase_hash, created_at, updated_at) VALUES (?, ?, datetime('now'), datetime('now'))`, 
		email, hashedPassphrase)
	if err != nil {
		return err
	}

	// Set first time setup flag
	_, err = s.db.Exec(`INSERT OR REPLACE INTO setup_flags (flag_name, flag_value, created_at) VALUES ('first_time_setup_completed', 1, datetime('now'))`)
	if err != nil {
		return err
	}

	return nil
}

// SaveSecurityQuestions saves security questions for a user
func (s *Service) SaveSecurityQuestions(userID int, questions []models.SecurityQuestion) error {
	// Begin transaction
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Save each question
	for _, q := range questions {
		// Hash the answer
		hashedAnswer, err := HashPassword(q.Answer, nil)
		if err != nil {
			return err
		}

		// Save question to database
		_, err = tx.Exec(`INSERT INTO security_questions (user_id, question, answer_hash, is_custom, created_at, updated_at) VALUES (?, ?, ?, ?, datetime('now'), datetime('now'))`,
			userID, q.Question, hashedAnswer, q.IsCustom)
		if err != nil {
			return err
		}
	}

	// Commit transaction
	return tx.Commit()
}

// GetPredefinedQuestions retrieves all predefined security questions
func (s *Service) GetPredefinedQuestions() ([]models.SecurityQuestion, error) {
	rows, err := s.db.Query("SELECT id, question FROM security_questions WHERE user_id = 0 AND is_custom = 0 ORDER BY id")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var questions []models.SecurityQuestion
	for rows.Next() {
		var q models.SecurityQuestion
		err := rows.Scan(&q.ID, &q.Question)
		if err != nil {
			return nil, err
		}
		q.IsCustom = false
		questions = append(questions, q)
	}

	return questions, nil
}

// Placeholder for future authentication methods
// LoginUser, etc.
