// handlers/handlers.go
package handlers

import (
	"lab3/internal/models"
	"lab3/internal/service"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	svc *service.Service
}

func NewHandler(s *service.Service) *Handler {
	return &Handler{svc: s}
}

// Login godoc
// @Summary User authentication
// @Description Authenticate user with login and password to receive JWT token
// @Tags Authentication
// @Accept json
// @Produce json
// @Param request body models.LoginRequest true "Login credentials"
// @Success 200 {object} models.LoginResponse "Successfully authenticated"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 401 {object} models.ErrorResponse "Invalid credentials"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /auth/login [post]
func (h *Handler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	user, err := h.svc.Authenticate(req.Login, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error:   "AUTHENTICATION_FAILED",
			Message: err.Error(),
			Status:  http.StatusUnauthorized,
		})
		return
	}

	token, err := GenerateToken(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "TOKEN_GENERATION_FAILED",
			Message: "Failed to generate authentication token",
			Status:  http.StatusInternalServerError,
		})
		return
	}

	c.JSON(http.StatusOK, models.LoginResponse{
		Token: token,
		User:  user,
	})
}

// GetCurrentUser godoc
// @Summary Get current user information
// @Description Returns information about the currently authenticated user
// @Tags Authentication
// @Security BearerAuth
// @Produce json
// @Success 200 {object} models.User "Current user details"
// @Failure 401 {object} models.ErrorResponse "Unauthorized - Invalid or missing token"
// @Failure 404 {object} models.ErrorResponse "User not found"
// @Router /auth/me [get]
func (h *Handler) GetCurrentUser(c *gin.Context) {
	userID := c.GetInt64("user_id")
	user, err := h.svc.GetUserByID(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "USER_NOT_FOUND",
			Message: "User not found",
			Status:  http.StatusNotFound,
		})
		return
	}
	c.JSON(http.StatusOK, user)
}

// ListUsers godoc
// @Summary List all users
// @Description Returns a list of all registered users (admin only)
// @Tags Users
// @Security BearerAuth
// @Produce json
// @Success 200 {array} models.User "List of users"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Forbidden - Admin access required"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /users [get]
func (h *Handler) ListUsers(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can list users",
			Status:  http.StatusForbidden,
		})
		return
	}

	users, err := h.svc.GetAllUsers()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "DATABASE_ERROR",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, users)
}

// GetUser godoc
// @Summary Get user by ID
// @Description Returns detailed information about a specific user
// @Tags Users
// @Security BearerAuth
// @Produce json
// @Param id path int true "User ID"
// @Success 200 {object} models.User "User details"
// @Failure 400 {object} models.ErrorResponse "Invalid user ID"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Forbidden"
// @Failure 404 {object} models.ErrorResponse "User not found"
// @Router /users/{id} [get]
func (h *Handler) GetUser(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can view user details",
			Status:  http.StatusForbidden,
		})
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid user ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	user, err := h.svc.GetUserByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "USER_NOT_FOUND",
			Message: "User not found",
			Status:  http.StatusNotFound,
		})
		return
	}
	c.JSON(http.StatusOK, user)
}

// CreateUser godoc
// @Summary Create a new user
// @Description Creates a new user account (admin only)
// @Tags Users
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param user body models.CreateUserRequest true "User creation data"
// @Success 201 {object} models.User "User created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request data"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Forbidden - Admin access required"
// @Failure 409 {object} models.ErrorResponse "User already exists"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /users [post]
func (h *Handler) CreateUser(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can create users",
			Status:  http.StatusForbidden,
		})
		return
	}

	var req models.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	user := &models.User{
		Login:    req.Login,
		Password: req.Password,
		IsAdmin:  req.IsAdmin,
	}

	if err := h.svc.CreateUser(user); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "CREATION_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusCreated, user)
}

// UpdateUser godoc
// @Summary Update a user
// @Description Updates user information (admin only)
// @Tags Users
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path int true "User ID"
// @Param user body models.UpdateUserRequest true "User update data"
// @Success 200 {object} models.User "User updated successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request data"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Forbidden"
// @Failure 404 {object} models.ErrorResponse "User not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /users/{id} [put]
func (h *Handler) UpdateUser(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can update users",
			Status:  http.StatusForbidden,
		})
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid user ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	var req models.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	_, err = h.svc.GetUserByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	user := &models.User{
		ID:       id,
		Login:    req.Login,
		Password: req.Password,
		IsAdmin:  req.IsAdmin,
	}

	if err := h.svc.UpdateUser(user, isAdmin); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "UPDATE_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, user)
}

// DeleteUser godoc
// @Summary Delete a user
// @Description Permanently deletes a user account (admin only)
// @Tags Users
// @Security BearerAuth
// @Produce json
// @Param id path int true "User ID"
// @Success 204 "User deleted successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid user ID"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Forbidden"
// @Failure 404 {object} models.ErrorResponse "User not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /users/{id} [delete]
func (h *Handler) DeleteUser(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can delete users",
			Status:  http.StatusForbidden,
		})
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid user ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	_, err = h.svc.GetUserByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	if err := h.svc.DeleteUser(id, isAdmin); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// ListCards godoc
// @Summary List all transport cards
// @Description Returns a list of all registered transport cards
// @Tags Cards
// @Security BearerAuth
// @Produce json
// @Success 200 {array} models.Card "List of cards"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /cards [get]
func (h *Handler) ListCards(c *gin.Context) {
	cards, err := h.svc.GetAllCards()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "DATABASE_ERROR",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, cards)
}

// GetCard godoc
// @Summary Get card by ID
// @Description Returns detailed information about a specific transport card
// @Tags Cards
// @Security BearerAuth
// @Produce json
// @Param id path int true "Card ID"
// @Success 200 {object} models.Card "Card details"
// @Failure 400 {object} models.ErrorResponse "Invalid card ID"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "Card not found"
// @Router /cards/{id} [get]
func (h *Handler) GetCard(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid card ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	card, err := h.svc.GetCardByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "CARD_NOT_FOUND",
			Message: "Card not found",
			Status:  http.StatusNotFound,
		})
		return
	}
	c.JSON(http.StatusOK, card)
}

// CreateCard godoc
// @Summary Create a new transport card
// @Description Creates a new transport card with initial balance
// @Tags Cards
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param card body models.CreateCardRequest true "Card creation data"
// @Success 201 {object} models.Card "Card created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request data"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 409 {object} models.ErrorResponse "Card number already exists"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /cards [post]
func (h *Handler) CreateCard(c *gin.Context) {
	var req models.CreateCardRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	card := &models.Card{
		Number:    req.Number,
		Balance:   req.Balance,
		Blocked:   req.Blocked,
		OwnerName: req.OwnerName,
		KeyID:     req.KeyID,
	}

	if err := h.svc.CreateCard(card); err != nil {
		// Проверяем, ошибка ли это дубликата
		if err.Error() == "card with this number already exists" {
			c.JSON(http.StatusConflict, models.ErrorResponse{
				Error:   "DUPLICATE_CARD",
				Message: "Карта с таким номером уже существует",
				Status:  http.StatusConflict,
			})
			return
		}
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "CREATION_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusCreated, card)
}

// UpdateCard godoc
// @Summary Update a transport card
// @Description Updates card information (balance, blocked status, owner)
// @Tags Cards
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path int true "Card ID"
// @Param card body models.UpdateCardRequest true "Card update data"
// @Success 200 {object} models.Card "Card updated successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request data"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "Card not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /cards/{id} [put]
func requireAdmin(c *gin.Context) bool {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "FORBIDDEN",
			Message: "доступ запрещен",
			Status:  http.StatusForbidden,
		})
		return false
	}
	return true
}

func (h *Handler) UpdateCard(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid card ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	var req models.UpdateCardRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	// Проверяем, существует ли карта
	_, err = h.svc.GetCardByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "CARD_NOT_FOUND",
			Message: "Card not found",
			Status:  http.StatusNotFound,
		})
		return
	}

	// Проверяем, не занят ли новый номер другой картой
	if req.Number != "" {
		existing, _ := h.svc.GetCardByNumber(req.Number)
		if existing != nil && existing.ID != id {
			c.JSON(http.StatusConflict, models.ErrorResponse{
				Error:   "DUPLICATE_NUMBER",
				Message: "Card with this number already exists",
				Status:  http.StatusConflict,
			})
			return
		}
	}

	card := &models.Card{
		ID:        id,
		Number:    req.Number,
		Balance:   req.Balance,
		Blocked:   req.Blocked,
		OwnerName: req.OwnerName,
		KeyID:     req.KeyID,
	}

	if err := h.svc.UpdateCard(card); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "UPDATE_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, card)
}

// DeleteCard godoc
// @Summary Delete a transport card
// @Description Permanently deletes a transport card
// @Tags Cards
// @Security BearerAuth
// @Produce json
// @Param id path int true "Card ID"
// @Success 204 "Card deleted successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid card ID"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "Card not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /cards/{id} [delete]
func (h *Handler) DeleteCard(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid card ID format"})
		return
	}

	_, err = h.svc.GetCardByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "card not found"})
		return
	}

	if err := h.svc.DeleteCard(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// AuthorizeTransaction godoc
// @Summary Authorize payment transaction
// @Description Process payment authorization request from terminal
// @Tags Terminal Operations
// @Accept json
// @Produce json
// @Param request body models.AuthRequest true "Payment authorization request"
// @Success 200 {object} models.AuthResponse "Payment approved"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 403 {object} models.ErrorResponse "Payment declined"
// @Failure 404 {object} models.ErrorResponse "Card not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /terminals/authorize [post]
func (h *Handler) AuthorizeTransaction(c *gin.Context) {
	var req models.AuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	card, err := h.svc.GetCardByNumber(req.CardNumber)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "card not found"})
		return
	}

	if card.Blocked {
		c.JSON(http.StatusForbidden, gin.H{"error": "card blocked"})
		return
	}

	// Убираем UpdateBalance!
	// Только создаём транзакцию
	tx := &models.Transaction{
		Amount:     req.Amount,
		CardID:     card.ID,
		TerminalID: req.TerminalID,
		CreatedAt:  time.Now(),
	}

	if err := h.svc.CreateTransaction(tx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, models.AuthResponse{
		Status: "approved",
	})
}

// GetKeysForTerminal godoc
// @Summary Get all cryptographic keys for terminal
// @Description Download all cryptographic keys for payment terminal authentication
// @Tags Terminal Operations
// @Security BearerAuth
// @Produce json
// @Success 200 {array} models.Key "List of cryptographic keys"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /terminals/keys [get]
func (h *Handler) GetKeysForTerminal(c *gin.Context) {
	keys, err := h.svc.GetKeysForTerminal()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "DATABASE_ERROR",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, keys)
}

// ListTransactions godoc
// @Summary List all transactions
// @Description Returns a list of all payment transactions
// @Tags Transactions
// @Security BearerAuth
// @Produce json
// @Param limit query int false "Maximum number of transactions to return" default(100)
// ListTransactions godoc
// @Summary List all transactions
// @Description Get all payment transactions
// @Tags Transactions
// @Security BearerAuth
// @Produce json
// @Success 200 {array} models.Transaction
// @Failure 401 {object} map[string]string
// @Router /transactions [get]
func (h *Handler) ListTransactions(c *gin.Context) {
	txs, err := h.svc.GetAllTransactions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, txs)
}

// CreateTransaction godoc
// @Summary Create a new transaction
// @Description Creates a new transaction record (for testing purposes)
// @Tags Transactions
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param transaction body models.CreateTransactionRequest true "Transaction creation data"
// @Success 201 {object} models.Transaction "Transaction created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request data"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /transactions [post]
func (h *Handler) CreateTransaction(c *gin.Context) {
	var req models.CreateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	tx := &models.Transaction{
		Amount:     req.Amount,
		CardID:     req.CardID,
		TerminalID: req.TerminalID,
	}

	if err := h.svc.CreateTransaction(tx); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "CREATION_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusCreated, tx)
}

// ---- Terminals ----

// ListTerminals godoc
// @Summary List all terminals
// @Description Get all payment terminals
// @Tags Terminals
// @Security BearerAuth
// @Produce json
// @Success 200 {array} models.Terminal
// @Failure 401 {object} map[string]string
// @Router /terminals [get]
func (h *Handler) ListTerminals(c *gin.Context) {
	terminals, err := h.svc.GetAllTerminals()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, terminals)
}

// GetTerminal godoc
// @Summary Get a terminal by ID
// @Description Get terminal details by ID
// @Tags Terminals
// @Security BearerAuth
// @Produce json
// @Param id path int true "Terminal ID"
// @Success 200 {object} models.Terminal
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /terminals/{id} [get]
func (h *Handler) GetTerminal(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	terminal, err := h.svc.GetTerminalByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "terminal not found"})
		return
	}
	c.JSON(http.StatusOK, terminal)
}

// CreateTerminal godoc
// @Summary Create a new terminal (admin only)
// @Description Create a new payment terminal
// @Tags Terminals
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param terminal body models.Terminal true "Terminal data"
// @Success 201 {object} models.Terminal
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string "Admin only"
// @Router /terminals [post]
func (h *Handler) CreateTerminal(c *gin.Context) {
	var t models.Terminal
	if err := c.ShouldBindJSON(&t); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.svc.CreateTerminal(&t); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, t)
}

// UpdateTerminal godoc
// @Summary Update a terminal (admin only)
// @Description Update terminal data
// @Tags Terminals
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path int true "Terminal ID"
// @Param terminal body models.Terminal true "Terminal data"
// @Success 200 {object} models.Terminal
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string "Admin only"
// @Router /terminals/{id} [put]
func (h *Handler) UpdateTerminal(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	var t models.Terminal
	if err := c.ShouldBindJSON(&t); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	t.ID = id
	_, err := h.svc.GetTerminalByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "terminal not found"})
		return
	}
	if err := h.svc.UpdateTerminal(&t); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, t)
}

// DeleteTerminal godoc
// @Summary Delete a terminal (admin only)
// @Description Delete a payment terminal
// @Tags Terminals
// @Security BearerAuth
// @Produce json
// @Param id path int true "Terminal ID"
// @Success 204 "No Content"
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string "Admin only"
// @Router /terminals/{id} [delete]
func (h *Handler) DeleteTerminal(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	_, err := h.svc.GetTerminalByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "terminal not found"})
		return
	}
	if err := h.svc.DeleteTerminal(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// ---- Keys ----

// ListKeys godoc
// @Summary List all keys
// @Description Get all crypto keys
// @Tags Keys
// @Security BearerAuth
// @Produce json
// @Success 200 {array} models.Key
// @Failure 401 {object} map[string]string
// @Router /keys [get]
func (h *Handler) ListKeys(c *gin.Context) {
	keys, err := h.svc.GetAllKeys()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, keys)
}

// GetKey godoc
// @Summary Get a key by ID
// @Description Get key details by ID
// @Tags Keys
// @Security BearerAuth
// @Produce json
// @Param id path int true "Key ID"
// @Success 200 {object} models.Key
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /keys/{id} [get]
func (h *Handler) GetKey(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	key, err := h.svc.GetKeyByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "key not found"})
		return
	}
	c.JSON(http.StatusOK, key)
}

// CreateKey godoc
// @Summary Create a new key
// @Description Create a new crypto key (admin only)
// @Tags Keys
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param key body models.Key true "Key data"
// @Success 201 {object} models.Key
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Router /keys [post]
func (h *Handler) CreateKey(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	var key models.Key
	if err := c.ShouldBindJSON(&key); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.svc.CreateKey(&key, isAdmin); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, key)
}

// UpdateKey godoc
// @Summary Update a key
// @Description Update key data (admin only)
// @Tags Keys
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path int true "Key ID"
// @Param key body models.Key true "Key data"
// @Success 200 {object} models.Key
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Router /keys/{id} [put]
func (h *Handler) UpdateKey(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	var key models.Key
	if err := c.ShouldBindJSON(&key); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	key.ID = id
	_, err := h.svc.GetKeyByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "key not found"})
		return
	}
	if err := h.svc.UpdateKey(&key, isAdmin); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, key)
}

// DeleteKey godoc
// @Summary Delete a key
// @Description Delete a crypto key (admin only)
// @Tags Keys
// @Security BearerAuth
// @Produce json
// @Param id path int true "Key ID"
// @Success 204 "No Content"
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Router /keys/{id} [delete]
func (h *Handler) DeleteKey(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	if err := h.svc.DeleteKey(id, isAdmin); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// GetCardByNumber godoc
// @Summary Get card by number
// @Param number path string true "Card number"
// @Router /cards/by-number/{number} [get]
func (h *Handler) GetCardByNumber(c *gin.Context) {
	number := c.Param("number")
	card, err := h.svc.GetCardByNumber(number)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "card not found"})
		return
	}
	c.JSON(http.StatusOK, card)
}

// RegisterCard godoc
// @Router /cards/register [post]
func (h *Handler) RegisterCard(c *gin.Context) {
	var req struct {
		Number    string `json:"number"`
		OwnerName string `json:"owner_name"`
		Balance   int64  `json:"balance"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Определяем, какое поле использовать для номера карты
	cardNumber := req.Number
	if cardNumber == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "either number or uid is required"})
		return
	}

	// Проверяем, не существует ли уже карта с таким номером
	existing, _ := h.svc.GetCardByNumber(cardNumber)
	if existing != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "card with this number already exists"})
		return
	}

	card := &models.Card{
		Number:    cardNumber,
		Balance:   req.Balance,
		Blocked:   false,
		OwnerName: req.OwnerName,
		KeyID:     1,
	}

	if err := h.svc.RegisterCard(card); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, card)
}

// DebitCard godoc
// @Router /cards/debit [post]
func (h *Handler) DebitCard(c *gin.Context) {
	var req struct {
		Number     string `json:"number"`
		Amount     int64  `json:"amount"`
		TerminalID int64  `json:"terminal_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	card, err := h.svc.GetCardByNumber(req.Number)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "card not found"})
		return
	}

	if card.Blocked {
		c.JSON(http.StatusForbidden, gin.H{"error": "card blocked"})
		return
	}

	// Создаём транзакцию с ОТРИЦАТЕЛЬНОЙ суммой для списания
	tx := &models.Transaction{
		Amount:     -req.Amount, // ← минус для списания
		CardID:     card.ID,
		TerminalID: req.TerminalID,
		CreatedAt:  time.Now(),
	}

	if err := h.svc.CreateTransaction(tx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "approved"})
}

// RechargeCard godoc
// @Router /cards/recharge [post]
func (h *Handler) RechargeCard(c *gin.Context) {
	var req struct {
		Number     string `json:"number"` // ← было uid
		Amount     int64  `json:"amount"`
		TerminalID int64  `json:"terminal_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	card, err := h.svc.GetCardByUID(req.Number)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "card not found"})
		return
	}

	tx := &models.Transaction{
		Amount:     req.Amount,
		CardID:     card.ID,
		TerminalID: req.TerminalID,
		CreatedAt:  time.Now(),
	}

	if err := h.svc.CreateTransaction(tx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// GetCardByUID godoc
// @Router /cards/by-uid/{uid} [get]
func (h *Handler) GetCardByUID(c *gin.Context) {
	number := c.Param("uid") // параметр в URL может остаться uid
	card, err := h.svc.GetCardByNumber(number)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "card not found"})
		return
	}
	c.JSON(http.StatusOK, card)
}

// SyncBalance godoc
// @Router /cards/sync-balance [put]
func (h *Handler) SyncBalance(c *gin.Context) {
	var req struct {
		Number  string `json:"number"`
		Balance int64  `json:"balance"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.svc.SyncBalance(req.Number, req.Balance); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}
