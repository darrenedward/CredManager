package database

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

var DB *sql.DB

// InitDB initializes the SQLite database connection
func InitDB() (*sql.DB, error) {
	var err error
	DB, err = sql.Open("sqlite3", "./api_key_manager.db")
	if err != nil {
		return nil, err
	}

	// Test the connection
	if err = DB.Ping(); err != nil {
		return nil, err
	}

	log.Println("Database connected successfully")
	return DB, nil
}

// Close closes the database connection
func Close() error {
	if DB != nil {
		return DB.Close()
	}
	return nil
}
