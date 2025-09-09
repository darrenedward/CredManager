package main

import (
	"log"
	"net/http"

	"api-key-manager/internal/database"
	"api-key-manager/pkg/api"

	"github.com/gorilla/mux"
)

func main() {
	// Initialize database
	db, err := database.InitDB()
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	defer db.Close()

	// Create router
	r := mux.NewRouter()

	// API routes
	api.SetupAuthRoutes(r, db)

	// Middleware
	r.Use(api.LoggingMiddleware)

	// Start server
	log.Println("Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", r))
}
