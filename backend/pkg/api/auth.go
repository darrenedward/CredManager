package api

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"

	"api-key-manager/internal/auth"
	"api-key-manager/internal/models"
	"api-key-manager/internal/utils"

	"github.com/gorilla/mux"
)

// SetupAuthRoutes sets up authentication-related routes
func SetupAuthRoutes(r *mux.Router, db *sql.DB) {
	// First-time detection endpoint (outside of /auth prefix as per tests)
	r.HandleFunc("/api/auth/first-time", func(w http.ResponseWriter, r *http.Request) {
		isFirstTime, err := auth.IsFirstTimeUser(db)
		if err != nil {
			log.Printf("Error checking first-time status: %v", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Internal server error"})
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]bool{"isFirstTime": isFirstTime})
	}).Methods("GET")

	// Predefined questions endpoint
	r.HandleFunc("/api/auth/predefined-questions", func(w http.ResponseWriter, r *http.Request) {
		// Create auth service
		authService := auth.NewService(db)

		// Get predefined questions
		questions, err := authService.GetPredefinedQuestions()
		if err != nil {
			log.Printf("Error getting predefined questions: %v", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Internal server error"})
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string][]models.SecurityQuestion{"questions": questions})
	}).Methods("GET")

	authRouter := r.PathPrefix("/auth").Subrouter()

	// Setup endpoint for creating first user with passphrase
	authRouter.HandleFunc("/setup", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusMethodNotAllowed)
			json.NewEncoder(w).Encode(map[string]string{"error": "Method not allowed"})
			return
		}

		// Check if request body is nil
		if r.Body == nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": "Request body is required"})
			return
		}

		// Parse request body
		var req struct {
			Email            string                    `json:"email"`
			Passphrase       string                    `json:"passphrase"`
			SecurityQuestions []models.SecurityQuestion `json:"security_questions"`
		}
		
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": "Invalid request body"})
			return
		}

		// Create auth service
		authService := auth.NewService(db)

		// Validate input
		if req.Email == "" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": "Email is required"})
			return
		}

		if req.Passphrase == "" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": "Passphrase is required"})
			return
		}

		// Validate passphrase
		if err := authService.ValidatePassphrase(req.Passphrase); err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}

		// Validate security questions if provided
		for _, q := range req.SecurityQuestions {
			if err := utils.ValidateSecurityQuestion(q.Question, q.Answer); err != nil {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusBadRequest)
				json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
				return
			}
		}

		// Validate that we have exactly 2 predefined and 2 custom questions
		if len(req.SecurityQuestions) > 0 {
			if err := utils.ValidateSecurityQuestionsSet(req.SecurityQuestions); err != nil {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusBadRequest)
				json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
				return
			}
		}

		// Check if this is first time setup
		isFirstTime, err := auth.IsFirstTimeUser(db)
		if err != nil {
			log.Printf("Error checking first-time status: %v", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Internal server error"})
			return
		}

		if !isFirstTime {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusForbidden)
			json.NewEncoder(w).Encode(map[string]string{"error": "Setup already completed"})
			return
		}

		// Check if user already exists
		exists, err := auth.UserExists(db, req.Email)
		if err != nil {
			log.Printf("Error checking if user exists: %v", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Internal server error"})
			return
		}

		if exists {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusConflict)
			json.NewEncoder(w).Encode(map[string]string{"error": "User already exists"})
			return
		}

		// Create user
		if err := authService.CreateUser(req.Email, req.Passphrase); err != nil {
			log.Printf("Error creating user: %v", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Internal server error"})
			return
		}

		// Get user ID
		var userID int
		err = db.QueryRow("SELECT id FROM users WHERE email = ?", req.Email).Scan(&userID)
		if err != nil {
			log.Printf("Error getting user ID: %v", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Internal server error"})
			return
		}

		// Save security questions if provided
		if len(req.SecurityQuestions) > 0 {
			if err := authService.SaveSecurityQuestions(userID, req.SecurityQuestions); err != nil {
				log.Printf("Error saving security questions: %v", err)
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusInternalServerError)
				json.NewEncoder(w).Encode(map[string]string{"error": "Internal server error"})
				return
			}
		}

		// Generate JWT token for automatic login
		token, err := auth.GenerateToken(userID, req.Email)
		if err != nil {
			log.Printf("Error generating token: %v", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "Internal server error"})
			return
		}

		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"status":  "success",
			"message": "User created successfully",
			"token":   token,
		}
		json.NewEncoder(w).Encode(response)
	}).Methods("POST")

	authRouter.HandleFunc("/login", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "login endpoint - to be implemented"})
	}).Methods("POST")

	authRouter.HandleFunc("/recovery", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "recovery endpoint - to be implemented"})
	}).Methods("POST")
}
