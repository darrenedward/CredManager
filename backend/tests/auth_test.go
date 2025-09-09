package tests

import (
	"database/sql"
	"testing"

	"api-key-manager/internal/auth"
	"api-key-manager/internal/models"
	"api-key-manager/internal/utils"

	_ "github.com/mattn/go-sqlite3"
)

func TestValidatePassphrase(t *testing.T) {
	tests := []struct {
		name        string
		passphrase  string
		expectError bool
	}{
		{"Valid passphrase", "ValidPass123", false},
		{"Too short", "Short1", true},
		{"No uppercase", "nouppercase123", true},
		{"No lowercase", "NOLOWERCASE123", true},
		{"No digit", "NoDigitPass", true},
		{"Empty", "", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := utils.ValidatePassphrase(tt.passphrase)
			if (err != nil) != tt.expectError {
				t.Errorf("ValidatePassphrase() error = %v, expectError %v", err, tt.expectError)
			}
		})
	}
}

func TestAuthServiceValidatePassphrase(t *testing.T) {
	// Create a mock database connection (not used in this test)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Create auth service
	authService := auth.NewService(db)

	tests := []struct {
		name        string
		passphrase  string
		expectError bool
	}{
		{"Valid passphrase", "ValidPass123", false},
		{"Too short", "Short1", true},
		{"No uppercase", "nouppercase123", true},
		{"No lowercase", "NOLOWERCASE123", true},
		{"No digit", "NoDigitPass", true},
		{"Empty", "", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := authService.ValidatePassphrase(tt.passphrase)
			if (err != nil) != tt.expectError {
				t.Errorf("AuthService.ValidatePassphrase() error = %v, expectError %v", err, tt.expectError)
			}
		})
	}
}

func TestValidateSecurityQuestion(t *testing.T) {
	tests := []struct {
		name        string
		question    string
		answer      string
		expectError bool
	}{
		{"Valid question and answer", "What is your favorite color?", "Blue", false},
		{"Empty question", "", "Blue", true},
		{"Empty answer", "What is your favorite color?", "", true},
		{"Question too short", "Short?", "Blue", true},
		{"Answer too short", "What is your favorite color?", "A", true},
		{"Both empty", "", "", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := utils.ValidateSecurityQuestion(tt.question, tt.answer)
			if (err != nil) != tt.expectError {
				t.Errorf("ValidateSecurityQuestion() error = %v, expectError %v", err, tt.expectError)
			}
		})
	}
}

func TestValidateSecurityQuestionsSet(t *testing.T) {
	tests := []struct {
		name        string
		questions   []models.SecurityQuestion
		expectError bool
	}{
		{
			name: "Valid set (2 predefined, 2 custom)",
			questions: []models.SecurityQuestion{
				{IsCustom: false},
				{IsCustom: false},
				{IsCustom: true},
				{IsCustom: true},
			},
			expectError: false,
		},
		{
			name: "Wrong total count",
			questions: []models.SecurityQuestion{
				{IsCustom: false},
				{IsCustom: false},
				{IsCustom: true},
			},
			expectError: true,
		},
		{
			name: "Wrong predefined count (3, 1)",
			questions: []models.SecurityQuestion{
				{IsCustom: false},
				{IsCustom: false},
				{IsCustom: false},
				{IsCustom: true},
			},
			expectError: true,
		},
		{
			name: "Wrong custom count (1, 3)",
			questions: []models.SecurityQuestion{
				{IsCustom: false},
				{IsCustom: false},
				{IsCustom: true},
				{IsCustom: true},
				{IsCustom: true},
			},
			expectError: true,
		},
		{
			name:        "Empty set",
			questions:   []models.SecurityQuestion{},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := utils.ValidateSecurityQuestionsSet(tt.questions)
			if (err != nil) != tt.expectError {
				t.Errorf("ValidateSecurityQuestionsSet() error = %v, expectError %v", err, tt.expectError)
			}
		})
	}
}

func TestValidateEmail(t *testing.T) {
	tests := []struct {
		name        string
		email       string
		expectError bool
	}{
		{"Valid email", "test@example.com", false},
		{"Invalid format", "invalid-email", true},
		{"Empty", "", true},
		{"No domain", "test@", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := utils.ValidateEmail(tt.email)
			if (err != nil) != tt.expectError {
				t.Errorf("ValidateEmail() error = %v, expectError %v", err, tt.expectError)
			}
		})
	}
}

func TestHashPassword(t *testing.T) {
	password := "TestPassword123"
	hash, err := auth.HashPassword(password, nil)
	if err != nil {
		t.Fatalf("HashPassword() error = %v", err)
	}

	if hash == "" {
		t.Error("HashPassword() returned empty hash")
	}

	// Test verification
	valid, err := auth.VerifyPassword(password, hash)
	if err != nil {
		t.Fatalf("VerifyPassword() error = %v", err)
	}

	if !valid {
		t.Error("VerifyPassword() should return true for correct password")
	}

	// Test with wrong password
	valid, err = auth.VerifyPassword("WrongPassword", hash)
	if err != nil {
		t.Fatalf("VerifyPassword() error = %v", err)
	}

	if valid {
		t.Error("VerifyPassword() should return false for incorrect password")
	}
}

// ST001 Tests: First-time user detection mechanism

func TestIsFirstTimeUser_EmptyDB(t *testing.T) {
	// Use in-memory DB for testing
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Create the users table but leave it empty to simulate first-time state
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			email TEXT UNIQUE NOT NULL,
			passphrase_hash TEXT NOT NULL,
			created_at DATETIME NOT NULL,
			updated_at DATETIME NOT NULL
		);
	`)
	if err != nil {
		t.Fatal(err)
	}

	// Call the function - should return true for empty DB
	isFirstTime, err := auth.IsFirstTimeUser(db)
	if err != nil {
		t.Errorf("IsFirstTimeUser() unexpected error: %v", err)
	}
	if !isFirstTime {
		t.Error("IsFirstTimeUser() should return true for empty database")
	}
}

func TestIsFirstTimeUser_NonEmptyDB(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			email TEXT UNIQUE NOT NULL,
			passphrase_hash TEXT NOT NULL,
			created_at DATETIME NOT NULL,
			updated_at DATETIME NOT NULL
		);
		INSERT INTO users (email, passphrase_hash, created_at, updated_at) 
		VALUES ('test@example.com', 'test_hash', datetime('now'), datetime('now'));
	`)
	if err != nil {
		t.Fatal(err)
	}

	isFirstTime, err := auth.IsFirstTimeUser(db)
	if err != nil {
		t.Errorf("IsFirstTimeUser() unexpected error: %v", err)
	}
	if isFirstTime {
		t.Error("IsFirstTimeUser() should return false for non-empty database")
	}
}

func TestIsFirstTimeUser_DatabaseError(t *testing.T) {
	// Simulate corrupted database by opening without creating table
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Don't create table to simulate corruption/error state
	_, err = auth.IsFirstTimeUser(db)
	if err == nil {
		t.Error("IsFirstTimeUser() should return error for database error/corruption")
	}
}

func TestUserExists_Exists(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			email TEXT UNIQUE NOT NULL,
			passphrase_hash TEXT NOT NULL,
			created_at DATETIME NOT NULL,
			updated_at DATETIME NOT NULL
		);
		INSERT INTO users (email, passphrase_hash, created_at, updated_at) 
		VALUES ('test@example.com', 'test_hash', datetime('now'), datetime('now'));
	`)
	if err != nil {
		t.Fatal(err)
	}

	exists, err := auth.UserExists(db, "test@example.com")
	if err != nil {
		t.Errorf("UserExists() unexpected error: %v", err)
	}
	if !exists {
		t.Error("UserExists() should return true when user exists")
	}
}

func TestUserExists_NotExists(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			email TEXT UNIQUE NOT NULL,
			passphrase_hash TEXT NOT NULL,
			created_at DATETIME NOT NULL,
			updated_at DATETIME NOT NULL
		);
	`)
	if err != nil {
		t.Fatal(err)
	}

	exists, err := auth.UserExists(db, "nonexistent@example.com")
	if err != nil {
		t.Errorf("UserExists() unexpected error: %v", err)
	}
	if exists {
		t.Error("UserExists() should return false when user does not exist")
	}
}

func TestUserExists_DatabaseError(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Simulate permission/error by not creating table
	_, err = auth.UserExists(db, "test@example.com")
	if err == nil {
		t.Error("UserExists() should return error for database error")
	}
}

func TestIsFirstTimeSetupFlagLogic_Empty(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Assume setup_flags table doesn't exist yet or is empty
	flagSet, err := auth.IsFirstTimeSetupFlagSet(db)
	if err != nil {
		t.Errorf("IsFirstTimeSetupFlagSet() unexpected error: %v", err)
	}
	if flagSet {
		t.Error("IsFirstTimeSetupFlagSet() should return false when flag not set")
	}
}

func TestIsFirstTimeSetupFlagLogic_Set(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS setup_flags (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			flag_name TEXT UNIQUE NOT NULL,
			flag_value BOOLEAN NOT NULL DEFAULT 0,
			created_at DATETIME NOT NULL
		);
		INSERT INTO setup_flags (flag_name, flag_value, created_at) 
		VALUES ('first_time_setup_completed', true, datetime('now'));
	`)
	if err != nil {
		t.Fatal(err)
	}

	flagSet, err := auth.IsFirstTimeSetupFlagSet(db)
	if err != nil {
		t.Errorf("IsFirstTimeSetupFlagSet() unexpected error: %v", err)
	}
	if !flagSet {
		t.Error("IsFirstTimeSetupFlagSet() should return true when flag is set")
	}
}

func TestIsFirstTimeSetupFlagLogic_Error(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Simulate error state
	flagSet, err := auth.IsFirstTimeSetupFlagSet(db)
	if err != nil {
		t.Errorf("IsFirstTimeSetupFlagSet() unexpected error: %v", err)
	}
	if flagSet {
		t.Error("IsFirstTimeSetupFlagSet() should return false when flag not set")
	}
}
