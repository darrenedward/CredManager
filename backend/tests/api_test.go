package tests

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"api-key-manager/internal/database"
	"api-key-manager/pkg/api"

	"github.com/gorilla/mux"
	_ "github.com/mattn/go-sqlite3"
)

func TestSetupAuthRoutes(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize schema
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

	-- Insert predefined security questions
	INSERT OR IGNORE INTO security_questions (user_id, question, answer_hash, is_custom, created_at, updated_at)
	VALUES
		(0, 'What was the name of your first pet?', '', 0, datetime('now'), datetime('now')),
		(0, 'What is your mother''s maiden name?', '', 0, datetime('now'), datetime('now')),
		(0, 'What was the name of your first school?', '', 0, datetime('now'), datetime('now')),
		(0, 'What is your favorite book?', '', 0, datetime('now'), datetime('now')),
		(0, 'What city were you born in?', '', 0, datetime('now'), datetime('now'));
	`
	_, err = db.Exec(schema)
	if err != nil {
		t.Fatalf("Failed to initialize schema: %v", err)
	}

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test setup endpoint with empty body (should return bad request)
	req, err := http.NewRequest("POST", "/auth/setup", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	// Should return bad request for empty body
	if status := rr.Code; status != http.StatusBadRequest {
		t.Errorf("Setup endpoint returned wrong status code: got %v want %v", status, http.StatusBadRequest)
	}
}

func TestLoginEndpoint(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := database.InitDB()
	if err != nil {
		t.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test login endpoint
	req, err := http.NewRequest("POST", "/auth/login", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Login endpoint returned wrong status code: got %v want %v", status, http.StatusOK)
	}
}

func TestRecoveryEndpoint(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := database.InitDB()
	if err != nil {
		t.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Create router
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	// Test recovery endpoint
	req, err := http.NewRequest("POST", "/auth/recovery", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Recovery endpoint returned wrong status code: got %v want %v", status, http.StatusOK)
	}
}

func TestLoggingMiddleware(t *testing.T) {
	// Create a simple handler
	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Apply middleware
	handler := api.LoggingMiddleware(testHandler)

	// Create request
	req, err := http.NewRequest("GET", "/test", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	if rr.Body.String() != "OK" {
		t.Errorf("Handler returned unexpected body: got %v want %v", rr.Body.String(), "OK")
	}
}

// ST001 API Tests: First-time detection API endpoint

func TestFirstTimeDetectionAPI_EmptyDB(t *testing.T) {
	// Use in-memory DB
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Create users table empty
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

	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	req, err := http.NewRequest("GET", "/api/auth/first-time", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("First-time API returned wrong status: got %v want %v", status, http.StatusOK)
	}

	var response struct {
		IsFirstTime bool `json:"isFirstTime"`
	}
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}

	if !response.IsFirstTime {
		t.Error("API should return isFirstTime: true for empty DB")
	}
}

func TestFirstTimeDetectionAPI_NonEmptyDB(t *testing.T) {
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

	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	req, err := http.NewRequest("GET", "/api/auth/first-time", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("First-time API returned wrong status: got %v want %v", status, http.StatusOK)
	}

	var response struct {
		IsFirstTime bool `json:"isFirstTime"`
	}
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}

	if response.IsFirstTime {
		t.Error("API should return isFirstTime: false for non-empty DB")
	}
}

func TestFirstTimeDetectionAPI_DatabaseError(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Don't create table to simulate error
	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	req, err := http.NewRequest("GET", "/api/auth/first-time", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusInternalServerError {
		t.Errorf("First-time API should return 500 on DB error: got %v want %v", status, http.StatusInternalServerError)
	}

	var response map[string]string
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse error response: %v", err)
	}

	if response["error"] == "" {
		t.Error("API should return error message on DB failure")
	}
}

func TestPredefinedQuestionsAPI(t *testing.T) {
	// Initialize database (in-memory for testing)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// Initialize schema with predefined questions
	schema := `
	CREATE TABLE security_questions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER NOT NULL,
		question TEXT NOT NULL,
		answer_hash TEXT NOT NULL,
		is_custom BOOLEAN NOT NULL DEFAULT 0,
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL
	);

	INSERT INTO security_questions (user_id, question, answer_hash, is_custom, created_at, updated_at)
	VALUES
		(0, 'What was the name of your first pet?', '', 0, datetime('now'), datetime('now')),
		(0, 'What is your mother''s maiden name?', '', 0, datetime('now'), datetime('now')),
		(0, 'What was the name of your first school?', '', 0, datetime('now'), datetime('now'));
	`
	_, err = db.Exec(schema)
	if err != nil {
		t.Fatal(err)
	}

	r := mux.NewRouter()
	api.SetupAuthRoutes(r, db)

	req, err := http.NewRequest("GET", "/api/auth/predefined-questions", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	r.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Predefined questions API returned wrong status: got %v want %v", status, http.StatusOK)
	}

	var response struct {
		Questions []struct {
			ID       int    `json:"id"`
			Question string `json:"question"`
		} `json:"questions"`
	}
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}

	if len(response.Questions) != 3 {
		t.Errorf("API should return 3 predefined questions, got %d", len(response.Questions))
	}
}
