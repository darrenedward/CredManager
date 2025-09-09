package utils

import (
	"errors"
	"regexp"
	"strings"

	"api-key-manager/internal/models"
)

// ValidateEmail validates email format
func ValidateEmail(email string) error {
	email = strings.TrimSpace(email)
	if email == "" {
		return errors.New("email is required")
	}

	// Basic email regex
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(email) {
		return errors.New("invalid email format")
	}

	return nil
}

// ValidatePassphrase validates passphrase requirements
func ValidatePassphrase(passphrase string) error {
	if len(passphrase) < 12 {
		return errors.New("passphrase must be at least 12 characters long")
	}

	// Check for at least one uppercase letter
	hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(passphrase)
	// Check for at least one lowercase letter
	hasLower := regexp.MustCompile(`[a-z]`).MatchString(passphrase)
	// Check for at least one digit
	hasDigit := regexp.MustCompile(`[0-9]`).MatchString(passphrase)

	if !hasUpper || !hasLower || !hasDigit {
		return errors.New("passphrase must contain at least one uppercase letter, one lowercase letter, and one digit")
	}

	return nil
}

// SanitizeInput removes potentially harmful characters
func SanitizeInput(input string) string {
	// Remove null bytes and other control characters
	return strings.Map(func(r rune) rune {
		if r < 32 && r != 9 && r != 10 && r != 13 { // Allow tab, newline, carriage return
			return -1
		}
		return r
	}, input)
}

// ValidateSecurityQuestion validates security question input
func ValidateSecurityQuestion(question, answer string) error {
	question = strings.TrimSpace(question)
	answer = strings.TrimSpace(answer)

	if question == "" {
		return errors.New("security question is required")
	}

	if answer == "" {
		return errors.New("security answer is required")
	}

	if len(question) < 10 {
		return errors.New("security question must be at least 10 characters long")
	}

	if len(answer) < 3 {
		return errors.New("security answer must be at least 3 characters long")
	}

	return nil
}

// ValidateSecurityQuestionsSet validates that we have exactly 2 predefined and 2 custom questions
func ValidateSecurityQuestionsSet(questions []models.SecurityQuestion) error {
	if len(questions) != 4 {
		return errors.New("exactly 4 security questions are required (2 predefined and 2 custom)")
	}

	predefinedCount := 0
	customCount := 0

	for _, q := range questions {
		if q.IsCustom {
			customCount++
		} else {
			predefinedCount++
		}
	}

	if predefinedCount != 2 {
		return errors.New("exactly 2 predefined questions are required")
	}

	if customCount != 2 {
		return errors.New("exactly 2 custom questions are required")
	}

	return nil
}
