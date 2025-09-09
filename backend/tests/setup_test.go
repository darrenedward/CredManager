package tests

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"api-key-manager/internal/auth"
	"api-key-manager/pkg/api"
	"api-key-manager/internal/models"

	"github.com/gorilla/mux"
	_ "github.com/mattn/go-sqlite3"
)

func initializeTestDB(db *sql.DB) error {
	// Initialize database schema
	schema := `
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
	`

	_, err := db.Exec(schema)
	return err
}

func TestSetupEndpoint_Success(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize schema
	if err := initializeTestDB(db); err != nil {
		t.Fatalf("Failed to initialize schema: %v", err)
	}

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test setup endpoint with valid data (2 predefined + 2 custom questions)
	setupData := map[string]interface{}{
		"email":      "test@example.com",
		"passphrase": "ValidPass123",
		"security_questions": []models.SecurityQuestion{
			{
				ID:       1,
				Question: "What was the name of your first pet?",
				Answer:   "Fluffy",
				IsCustom: false,
			},
			{
				ID:       2,
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
		},
	}
	jsonData, _ := json.Marshal(setupData)

	req, err := http.NewRequest("POST", "/auth/setup", bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Setup endpoint returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	var response map[string]interface{}
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}

	if response["status"] != "success" {
		t.Errorf("Unexpected response: %v", response)
	}

	// Check that token is returned
	token, ok := response["token"].(string)
	if !ok || token == "" {
		t.Error("Expected token in response")
	}

	// Verify that the token is valid
	claims, err := auth.ValidateToken(token)
	if err != nil {
		t.Errorf("Generated token is invalid: %v", err)
	}

	if claims.Email != "test@example.com" {
		t.Errorf("Token has wrong email: got %v want %v", claims.Email, "test@example.com")
	}
}

func TestSetupEndpoint_InvalidPassphrase(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize schema
	if err := initializeTestDB(db); err != nil {
		t.Fatalf("Failed to initialize schema: %v", err)
	}

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test setup endpoint with invalid passphrase
	setupData := map[string]interface{}{
		"email":      "test@example.com",
		"passphrase": "short", // Too short
		"security_questions": []models.SecurityQuestion{
			{
				ID:       1,
				Question: "What was the name of your first pet?",
				Answer:   "Fluffy",
				IsCustom: false,
			},
			{
				ID:       2,
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
		},
	}
	jsonData, _ := json.Marshal(setupData)

	req, err := http.NewRequest("POST", "/auth/setup", bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusBadRequest {
		t.Errorf("Setup endpoint returned wrong status code: got %v want %v", status, http.StatusBadRequest)
	}
}

func TestSetupEndpoint_MissingEmail(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize schema
	if err := initializeTestDB(db); err != nil {
		t.Fatalf("Failed to initialize schema: %v", err)
	}

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test setup endpoint with missing email
	setupData := map[string]interface{}{
		"passphrase": "ValidPass123",
		"security_questions": []models.SecurityQuestion{
			{
				ID:       1,
				Question: "What was the name of your first pet?",
				Answer:   "Fluffy",
				IsCustom: false,
			},
			{
				ID:       2,
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
		},
		// email is missing
	}
	jsonData, _ := json.Marshal(setupData)

	req, err := http.NewRequest("POST", "/auth/setup", bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusBadRequest {
		t.Errorf("Setup endpoint returned wrong status code: got %v want %v", status, http.StatusBadRequest)
	}
}

func TestSetupEndpoint_AlreadySetup(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Initialize schema
	if err := initializeTestDB(db); err != nil {
		t.Fatalf("Failed to initialize schema: %v", err)
	}

	// Insert a user to simulate already setup
	_, err = db.Exec(`INSERT INTO users (email, passphrase_hash, created_at, updated_at) 
		VALUES ('existing@example.com', 'hash', datetime('now'), datetime('now'));`)
	if err != nil {
		t.Fatal(err)
	}

	// Set the setup flag
	_, err = db.Exec(`INSERT OR REPLACE INTO setup_flags (flag_name, flag_value, created_at) VALUES ('first_time_setup_completed', 1, datetime('now'))`)
	if err != nil {
		t.Fatal(err)
	}

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test setup endpoint when already setup
	setupData := map[string]interface{}{
		"email":      "test@example.com",
		"passphrase": "ValidPass123",
		"security_questions": []models.SecurityQuestion{
			{
				ID:       1,
				Question: "What was the name of your first pet?",
				Answer:   "Fluffy",
				IsCustom: false,
			},
			{
				ID:       2,
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
		},
	}
	jsonData, _ := json.Marshal(setupData)

	req, err := http.NewRequest("POST", "/auth/setup", bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusForbidden {
		t.Errorf("Setup endpoint returned wrong status code: got %v want %v", status, http.StatusForbidden)
	}
}

func TestSetupEndpoint_InvalidSecurityQuestion(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize schema
	if err := initializeTestDB(db); err != nil {
		t.Fatalf("Failed to initialize schema: %v", err)
	}

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test setup endpoint with invalid security question (too short)
	setupData := map[string]interface{}{
		"email":      "test@example.com",
		"passphrase": "ValidPass123",
		"security_questions": []models.SecurityQuestion{
			{
				ID:       1,
				Question: "Short?", // Too short
				Answer:   "Fluffy",
				IsCustom: false,
			},
			{
				ID:       2,
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
		},
	}
	jsonData, _ := json.Marshal(setupData)

	req, err := http.NewRequest("POST", "/auth/setup", bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusBadRequest {
		t.Errorf("Setup endpoint returned wrong status code: got %v want %v", status, http.StatusBadRequest)
	}
}

func TestSetupEndpoint_WrongNumberOfQuestions(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize schema
	if err := initializeTestDB(db); err != nil {
		t.Fatalf("Failed to initialize schema: %v", err)
	}

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test setup endpoint with wrong number of questions (only 3 instead of 4)
	setupData := map[string]interface{}{
		"email":      "test@example.com",
		"passphrase": "ValidPass123",
		"security_questions": []models.SecurityQuestion{
			{
				ID:       1,
				Question: "What was the name of your first pet?",
				Answer:   "Fluffy",
				IsCustom: false,
			},
			{
				ID:       2,
				Question: "What is your mother's maiden name?",
				Answer:   "Smith",
				IsCustom: false,
			},
			{
				Question: "What is your favorite color?",
				Answer:   "Blue",
				IsCustom: true,
			},
			// Missing one custom question
		},
	}
	jsonData, _ := json.Marshal(setupData)

	req, err := http.NewRequest("POST", "/auth/setup", bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusBadRequest {
		t.Errorf("Setup endpoint returned wrong status code: got %v want %v", status, http.StatusBadRequest)
	}
}

func TestSetupEndpoint_WrongMixOfQuestions(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize schema
	if err := initializeTestDB(db); err != nil {
		t.Fatalf("Failed to initialize schema: %v", err)
	}

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test setup endpoint with wrong mix (3 predefined, 1 custom instead of 2 each)
	setupData := map[string]interface{}{
		"email":      "test@example.com",
		"passphrase": "ValidPass123",
		"security_questions": []models.SecurityQuestion{
			{
				ID:       1,
				Question: "What was the name of your first pet?",
				Answer:   "Fluffy",
				IsCustom: false,
			},
			{
				ID:       2,
				Question: "What is your mother's maiden name?",
				Answer:   "Smith",
				IsCustom: false,
			},
			{
				ID:       3,
				Question: "What was the name of your first school?",
				Answer:   "Elementary",
				IsCustom: false,
			},
			{
				Question: "What is your favorite color?",
				Answer:   "Blue",
				IsCustom: true,
			},
		},
	}
	jsonData, _ := json.Marshal(setupData)

	req, err := http.NewRequest("POST", "/auth/setup", bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusBadRequest {
		t.Errorf("Setup endpoint returned wrong status code: got %v want %v", status, http.StatusBadRequest)
	}
}