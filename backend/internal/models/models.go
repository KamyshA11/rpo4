// models/models.go
package models

import (
	"encoding/json"
	"reflect"
	"time"
)

type User struct {
	ID       int64  `json:"id"`
	Login    string `json:"login"`
	Password string `json:"-"`
	IsAdmin  bool   `json:"is_admin"`
	CardID   *int64 `json:"card_id,omitempty"`
}

type CreateUserRequest struct {
	Login    string `json:"login" binding:"required,min=3,max=50"`
	Password string `json:"password" binding:"required,min=6,max=100"`
	IsAdmin  bool   `json:"is_admin"`
	CardID   *int64 `json:"card_id"`
}

type UpdateUserRequest struct {
	Login    string `json:"login" binding:"required,min=3,max=50"`
	Password string `json:"password" binding:"omitempty,min=6,max=100"`
	IsAdmin  bool   `json:"is_admin"`
	CardID   *int64 `json:"card_id"`
}

type Card struct {
	ID        int64  `json:"id"`
	Number    string `json:"number"` // UID карты
	Balance   int64  `json:"balance"`
	Blocked   bool   `json:"blocked"`
	OwnerName string `json:"owner_name"`
	KeyID     int64  `json:"key_id"`
}

type CreateCardRequest struct {
	Number    string `json:"number" binding:"required"`  // ← было uid, стало number
	Balance   int64  `json:"balance"`
	Blocked   bool   `json:"blocked"`
	OwnerName string `json:"owner_name" binding:"required"`
	KeyID     int64  `json:"key_id" binding:"required"`
}

type UpdateCardRequest struct {
	UID       string `json:"uid" binding:"required"`
	Balance   int64  `json:"balance"`
	Blocked   bool   `json:"blocked"`
	OwnerName string `json:"owner_name" binding:"required"`
	KeyID     int64  `json:"key_id"`
}

type Terminal struct {
	ID      int64  `json:"id"`
	Serial  string `json:"serial"`
	Address string `json:"address"`
	Name    string `json:"name"`
}

type Transaction struct {
	ID         int64     `json:"id"`
	Amount     int64     `json:"amount"`
	CardID     int64     `json:"card_id"`
	TerminalID int64     `json:"terminal_id"`
	CreatedAt  time.Time `json:"created_at"`
}

type CustomTime struct {
	time.Time
}

func (ct CustomTime) MarshalJSON() ([]byte, error) {
	return []byte(`"` + ct.Time.Format("02.01.2006 15:04") + `"`), nil
}

func (ct *CustomTime) UnmarshalJSON(b []byte) error {
	s := string(b)
	if len(s) >= 2 {
		s = s[1 : len(s)-1]
	}
	if t, err := time.Parse("02.01.2006 15:04", s); err == nil {
		ct.Time = t
		return nil
	}
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		ct.Time = t
		return nil
	}
	return &json.UnmarshalTypeError{Value: s, Type: reflect.TypeOf(ct)}
}

type CreateTransactionRequest struct {
	Amount     int64       `json:"amount" binding:"required,min=1"`
	CardID     int64       `json:"card_id" binding:"required"`
	TerminalID int64       `json:"terminal_id" binding:"required"`
	CreatedAt  *CustomTime `json:"created_at"`
}

type UpdateTransactionRequest struct {
	Amount     int64      `json:"amount" binding:"required,min=1"`
	CardID     int64      `json:"card_id" binding:"required"`
	TerminalID int64      `json:"terminal_id" binding:"required"`
	CreatedAt  CustomTime `json:"created_at" binding:"required"`
}

type Key struct {
	ID   int64  `json:"id"`
	Data string `json:"data"`
}

type LoginRequest struct {
	Login    string `json:"login" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	Token string `json:"token"`
	User  *User  `json:"user"`
}

type AuthRequest struct {
	CardNumber string `json:"card_number" binding:"required"`
	Amount     int64  `json:"amount" binding:"required,min=1"`
	TerminalID int64  `json:"terminal_id" binding:"required"`
}

type AuthResponse struct {
	Status string `json:"status"`
	Reason string `json:"reason,omitempty"`
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Status  int    `json:"status"`
}
