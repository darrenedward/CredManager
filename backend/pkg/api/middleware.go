package api

import (
	"log"
	"net/http"
	"time"
)

// LoggingMiddleware logs HTTP requests
func LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Log the request
		log.Printf("[%s] %s %s", r.Method, r.RequestURI, time.Since(start))

		// Call the next handler
		next.ServeHTTP(w, r)
	})
}