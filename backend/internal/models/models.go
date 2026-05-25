// models/models.go
package models

import (
	"time"
)

// User represents a system user
// @Description User account information
type User struct {
	ID       int64  `json:"id" example:"1" description:"Unique user identifier"`
	Login    string `json:"login" example:"admin" description:"User login name"`
	Password string `json:"-" example:"-" description:"User password (never returned)"`
	IsAdmin  bool   `json:"is_admin" example:"true" description:"Administrator privileges flag"`
}

// CreateUserRequest represents user creation payload
// @Description Request body for creating a new user
type CreateUserRequest struct {
	Login    string `json:"login" binding:"required,min=3,max=50" example:"newuser" description:"User login (3-50 characters)"`
	Password string `json:"password" binding:"required,min=6,max=100" example:"password123" description:"User password (6-100 characters)"`
	IsAdmin  bool   `json:"is_admin" example:"false" description:"Administrator privileges"`
}

// UpdateUserRequest represents user update payload
// @Description Request body for updating an existing user
type UpdateUserRequest struct {
	Login    string `json:"login" binding:"required,min=3,max=50" example:"updateduser" description:"User login (3-50 characters)"`
	Password string `json:"password" binding:"omitempty,min=6,max=100" example:"newpassword123" description:"User password (6-100 characters)"`
	IsAdmin  bool   `json:"is_admin" example:"true" description:"Administrator privileges"`
}

// Card represents a MIFARE transport card
// @Description Transport card information
type Card struct {
	ID        int64  `json:"id" example:"1" description:"Unique card identifier"`
	Number    string `json:"number" example:"1234567890" description:"Card number (10 digits)"`
	Balance   int64  `json:"balance" example:"1000" description:"Current balance in cents"`
	Blocked   bool   `json:"blocked" example:"false" description:"Card blocked status"`
	OwnerName string `json:"owner_name" example:"Ivan Ivanov" description:"Card owner full name"`
	KeyID     int64  `json:"key_id" example:"1" description:"Associated cryptographic key ID"`
}

// CreateCardRequest represents card creation payload
// @Description Request body for creating a new transport card
type CreateCardRequest struct {
	Number    string `json:"number" binding:"required,len=10" example:"1234567890" description:"Card number (exactly 10 digits)"`
	Balance   int64  `json:"balance" binding:"required,min=0" example:"500" description:"Initial balance in cents"`
	Blocked   bool   `json:"blocked" example:"false" description:"Initial blocked status"`
	OwnerName string `json:"owner_name" binding:"required" example:"Ivan Ivanov" description:"Card owner full name"`
	KeyID     int64  `json:"key_id" binding:"required" example:"1" description:"Associated cryptographic key ID"`
}

// UpdateCardRequest represents card update payload
// @Description Request body for updating an existing transport card
type UpdateCardRequest struct {
	Number    string `json:"number" binding:"required,len=10" example:"1234567890" description:"Card number (exactly 10 digits)"`
	Balance   int64  `json:"balance" binding:"required,min=0" example:"750" description:"Updated balance in cents"`
	Blocked   bool   `json:"blocked" example:"true" description:"Updated blocked status"`
	OwnerName string `json:"owner_name" binding:"required" example:"Petr Petrov" description:"Updated owner full name"`
	KeyID     int64  `json:"key_id" binding:"required" example:"2" description:"Associated cryptographic key ID"`
}

// Terminal represents a payment terminal
// @Description Payment terminal information
type Terminal struct {
	ID      int64  `json:"id" example:"1" description:"Unique terminal identifier"`
	Serial  string `json:"serial" example:"TERM-001" description:"Terminal serial number"`
	Address string `json:"address" example:"Metro Station 1" description:"Terminal physical address"`
	Name    string `json:"name" example:"Metro Terminal 1" description:"Terminal display name"`
}

// Transaction represents a payment transaction
// @Description Payment transaction record
type Transaction struct {
	ID         int64     `json:"id" example:"1" description:"Unique transaction identifier"`
	Amount     int64     `json:"amount" example:"100" description:"Transaction amount in cents"`
	CardID     int64     `json:"card_id" example:"1" description:"Associated card ID"`
	TerminalID int64     `json:"terminal_id" example:"1" description:"Associated terminal ID"`
	CreatedAt  time.Time `json:"created_at" example:"2024-01-15T10:30:00Z" description:"Transaction timestamp"`
}

// CreateTransactionRequest represents transaction creation payload
// @Description Request body for creating a new transaction record
type CreateTransactionRequest struct {
	Amount     int64 `json:"amount" binding:"required,min=1" example:"150" description:"Transaction amount in cents"`
	CardID     int64 `json:"card_id" binding:"required" example:"1" description:"Associated card ID"`
	TerminalID int64 `json:"terminal_id" binding:"required" example:"1" description:"Associated terminal ID"`
}

// Key represents a cryptographic key for card decryption
// @Description Cryptographic key for MIFARE card decryption
type Key struct {
	ID   int64  `json:"id" example:"1" description:"Unique key identifier"`
	Data string `json:"data" example:"key_a1b2c3d4e5f6" description:"Key data (hex string)"`
}

// LoginRequest represents login credentials
// @Description Authentication request payload
type LoginRequest struct {
	Login    string `json:"login" binding:"required" example:"admin" description:"User login"`
	Password string `json:"password" binding:"required" example:"admin123" description:"User password"`
}

// LoginResponse represents JWT token response
// @Description Authentication response with JWT token
type LoginResponse struct {
	Token string `json:"token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." description:"JWT access token"`
	User  *User  `json:"user" description:"Authenticated user information"`
}

// AuthRequest represents transaction authorization request
// @Description Payment authorization request from terminal
type AuthRequest struct {
	CardNumber string `json:"card_number" binding:"required,len=10" example:"1234567890" description:"Card number (10 digits)"`
	Amount     int64  `json:"amount" binding:"required,min=1" example:"100" description:"Payment amount in cents"`
	TerminalID int64  `json:"terminal_id" binding:"required" example:"1" description:"Terminal ID"`
}

// AuthResponse represents transaction authorization response
// @Description Payment authorization response
type AuthResponse struct {
	Status string `json:"status" example:"approved" description:"Payment status (approved/declined)"`
	Reason string `json:"reason,omitempty" example:"Insufficient funds" description:"Decline reason (if declined)"`
}

// ErrorResponse represents API error response
// @Description Standard error response format
type ErrorResponse struct {
	Error   string `json:"error" example:"INVALID_REQUEST" description:"Error code"`
	Message string `json:"message" example:"Invalid request parameters" description:"Human-readable error message"`
	Status  int    `json:"status" example:"400" description:"HTTP status code"`
}
