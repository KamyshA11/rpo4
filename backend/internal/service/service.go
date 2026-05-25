package service

import (
	"errors"
	"lab3/internal/models"
	"lab3/internal/repository"
	"time"
)

type Service struct {
	repo *repository.Repository
}

func NewService(r *repository.Repository) *Service {
	return &Service{repo: r}
}

// ---- Auth ----

func (s *Service) Authenticate(login, password string) (*models.User, error) {
	user, err := s.repo.GetUserByLogin(login)
	if err != nil {
		return nil, errors.New("пользователь не найден")
	}
	if user.Password != password {
		return nil, errors.New("неверный пароль")
	}
	return user, nil
}

func (s *Service) GetUserByID(id int64) (*models.User, error) {
	return s.repo.GetUserByID(id)
}

// ---- Users CRUD ----

func (s *Service) GetAllUsers() ([]models.User, error) {
	return s.repo.GetAllUsers()
}

func (s *Service) CreateUser(u *models.User) error {
	return s.repo.CreateUser(u)
}

func (s *Service) UpdateUser(u *models.User, isAdmin bool) error {
	if !isAdmin {
		return errors.New("только администратор может редактировать пользователей")
	}
	return s.repo.UpdateUser(u)
}

func (s *Service) DeleteUser(id int64, isAdmin bool) error {
	if !isAdmin {
		return errors.New("только администратор может удалять пользователей")
	}
	return s.repo.DeleteUser(id)
}

// ---- Cards CRUD ----

func (s *Service) GetAllCards() ([]models.Card, error) {
	return s.repo.GetAllCards()
}

func (s *Service) GetCardByID(id int64) (*models.Card, error) {
	return s.repo.GetCardByID(id)
}

func (s *Service) CreateCard(c *models.Card) error {
	_, err := s.repo.GetKeyByID(c.KeyID)
	if err != nil {
		return errors.New("ключ с указанным key_id не найден")
	}
	return s.repo.CreateCard(c)
}

func (s *Service) UpdateCard(c *models.Card) error {
	_, err := s.repo.GetKeyByID(c.KeyID)
	if err != nil {
		return errors.New("ключ с указанным key_id не найден")
	}
	return s.repo.UpdateCard(c)
}

func (s *Service) DeleteCard(id int64) error {
	return s.repo.DeleteCard(id)
}

// ---- Terminals CRUD ----

func (s *Service) GetAllTerminals() ([]models.Terminal, error) {
	return s.repo.GetAllTerminals()
}

func (s *Service) GetTerminalByID(id int64) (*models.Terminal, error) {
	return s.repo.GetTerminalByID(id)
}

func (s *Service) CreateTerminal(t *models.Terminal) error {
	return s.repo.CreateTerminal(t)
}

func (s *Service) UpdateTerminal(t *models.Terminal) error {
	return s.repo.UpdateTerminal(t)
}

func (s *Service) DeleteTerminal(id int64) error {
	return s.repo.DeleteTerminal(id)
}

// ---- Transactions CRUD ----

func (s *Service) GetAllTransactions() ([]models.Transaction, error) {
	return s.repo.GetAllTransactions()
}

func (s *Service) CreateTransaction(tx *models.Transaction) error {
	card, err := s.repo.GetCardByID(tx.CardID)
	if err != nil {
		return errors.New("карта не найдена")
	}
	if card.Blocked {
		return errors.New("карта заблокирована")
	}
	if card.Balance < tx.Amount {
		return errors.New("недостаточно средств")
	}
	card.Balance -= tx.Amount
	if err := s.repo.UpdateCard(card); err != nil {
		return err
	}
	tx.CreatedAt = time.Now()
	return s.repo.CreateTransaction(tx)
}

// ---- Keys CRUD ----

func (s *Service) GetAllKeys() ([]models.Key, error) {
	return s.repo.GetAllKeys()
}

func (s *Service) GetKeyByID(id int64) (*models.Key, error) {
	return s.repo.GetKeyByID(id)
}

func (s *Service) CreateKey(k *models.Key, isAdmin bool) error {
	if !isAdmin {
		return errors.New("только администратор может добавлять ключи")
	}
	return s.repo.CreateKey(k)
}

func (s *Service) UpdateKey(k *models.Key, isAdmin bool) error {
	if !isAdmin {
		return errors.New("только администратор может редактировать ключи")
	}
	return s.repo.UpdateKey(k)
}

func (s *Service) DeleteKey(id int64, isAdmin bool) error {
	if !isAdmin {
		return errors.New("только администратор может удалять ключи")
	}
	return s.repo.DeleteKey(id)
}

// ---- Terminal API ----

func (s *Service) AuthorizeTransaction(cardNumber string, amount int64, terminalID int64) error {
	card, err := s.repo.GetCardByNumber(cardNumber)
	if err != nil {
		return errors.New("карта не найдена")
	}

	if card.Blocked {
		return errors.New("карта заблокирована")
	}

	if card.Balance < amount {
		return errors.New("недостаточно средств")
	}

	newBalance := card.Balance - amount
	if err := s.repo.UpdateBalance(card.ID, newBalance); err != nil {
		return err
	}

	tx := &models.Transaction{
		Amount:     amount,
		CardID:     card.ID,
		TerminalID: terminalID,
		CreatedAt:  time.Now(),
	}

	return s.repo.CreateTransaction(tx)
}

func (s *Service) GetKeysForTerminal() ([]models.Key, error) {
	return s.repo.GetAllKeys()
}

// GetCardByNumber returns card by its number
func (s *Service) GetCardByNumber(number string) (*models.Card, error) {
	return s.repo.GetCardByNumber(number)
}
