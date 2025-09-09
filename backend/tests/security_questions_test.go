package tests

import (
	"database/sql"
	"testing"

	"api-key-manager/internal/auth"
	"api-key-manager/internal/models"
	"api-key-manager/internal/utils"

	_ "github.com/mattn/go-sqlite3"
)

func TestMixedPredefinedCustomQuestions(t *testing.T) {
	// Test that we can properly validate mixed predefined/custom questions (2 of each)
	questions := []models.SecurityQuestion{
		{IsCustom: false}, // Predefined
		{IsCustom: false}, // Predefined
		{IsCustom: true},  // Custom
		{IsCustom: true},  // Custom
	}

	err := utils.ValidateSecurityQuestionsSet(questions)
	if err != nil {
		t.Errorf("ValidateSecurityQuestionsSet() should pass for 2 predefined and 2 custom questions, got: %v", err)
	}
}

func TestSaveMixedSecurityQuestions(t *testing.T) {
	// Test that we can save mixed predefined/custom questions to the database
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Initialize schema
	schema := `
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		email TEXT UNIQUE NOT NULL,
		passphrase_hash TEXT NOT NULL,
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL
	);

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
	`

	_, err = db.Exec(schema)
	if err != nil {
		t.Fatal(err)
	}

	// Create auth service
	authService := auth.NewService(db)

	// Insert a test user
	_, err = db.Exec(`INSERT INTO users (email, passphrase_hash, created_at, updated_at) VALUES (?, ?, datetime('now'), datetime('now'))`, "test@example.com", "test_hash")
	if err != nil {
		t.Fatal(err)
	}

	// Get user ID
	var userID int
	err = db.QueryRow("SELECT id FROM users WHERE email = ?", "test@example.com").Scan(&userID)
	if err != nil {
		t.Fatal(err)
	}

	// Test security questions (2 predefined, 2 custom)
	questions := []models.SecurityQuestion{
		{
			Question: "What was the name of your first pet?",
			Answer:   "Fluffy",
			IsCustom: false,
		},
		{
			Question: "What is your mother's maiden name?",
			Answer:   "Smith",
			IsCustom: false,
		},
		{
			Question: "What is your favorite color?",
			Answer:   "Blue",
			IsCustom: true,
		},
		{
			Question: "What was your first car?",
			Answer:   "Toyota",
			IsCustom: true,
		},
	}

	// Save questions
	err = authService.SaveSecurityQuestions(userID, questions)
	if err != nil {
		t.Errorf("SaveSecurityQuestions() failed: %v", err)
	}

	// Verify questions were saved correctly
	rows, err := db.Query("SELECT question, is_custom FROM security_questions WHERE user_id = ? ORDER BY id", userID)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()

	savedQuestions := []struct {
		Question string
		IsCustom bool
	}{}

	for rows.Next() {
		var question string
		var isCustom bool
		err := rows.Scan(&question, &isCustom)
		if err != nil {
			t.Fatal(err)
		}
		savedQuestions = append(savedQuestions, struct {
			Question string
			IsCustom bool
		}{Question: question, IsCustom: isCustom})
	}

	// Check that we have 4 questions
	if len(savedQuestions) != 4 {
		t.Errorf("Expected 4 questions, got %d", len(savedQuestions))
	}

	// Check that we have 2 predefined (isCustom = false) and 2 custom (isCustom = true)
	predefinedCount := 0
	customCount := 0
	for _, q := range savedQuestions {
		if q.IsCustom {
			customCount++
		} else {
			predefinedCount++
		}
	}

	if predefinedCount != 2 {
		t.Errorf("Expected 2 predefined questions, got %d", predefinedCount)
	}

	if customCount != 2 {
		t.Errorf("Expected 2 custom questions, got %d", customCount)
	}
}