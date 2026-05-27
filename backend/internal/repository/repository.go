package repository

import (
	"database/sql"
	"errors"
	"lab3/internal/models"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// ---- Users ----

func (r *Repository) GetUserByLogin(login string) (*models.User, error) {
	row := r.db.QueryRow("SELECT id, login, password, is_admin FROM users WHERE login = ?", login)
	var u models.User
	var isAdmin int
	err := row.Scan(&u.ID, &u.Login, &u.Password, &isAdmin)
	if err != nil {
		return nil, err
	}
	u.IsAdmin = isAdmin != 0
	return &u, nil
}

func (r *Repository) GetUserByID(id int64) (*models.User, error) {
	row := r.db.QueryRow("SELECT id, login, password, is_admin FROM users WHERE id = ?", id)
	var u models.User
	var isAdmin int
	err := row.Scan(&u.ID, &u.Login, &u.Password, &isAdmin)
	if err != nil {
		return nil, err
	}
	u.IsAdmin = isAdmin != 0
	return &u, nil
}

func (r *Repository) CreateUser(u *models.User) error {
	result, err := r.db.Exec("INSERT INTO users (login, password, is_admin) VALUES (?, ?, ?)",
		u.Login, u.Password, u.IsAdmin)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	u.ID = id
	return nil
}

func (r *Repository) UpdateUser(u *models.User) error {
	_, err := r.db.Exec("UPDATE users SET login = ?, password = ?, is_admin = ? WHERE id = ?",
		u.Login, u.Password, u.IsAdmin, u.ID)
	return err
}

func (r *Repository) DeleteUser(id int64) error {
	_, err := r.db.Exec("DELETE FROM users WHERE id = ?", id)
	return err
}

func (r *Repository) GetAllUsers() ([]models.User, error) {
	rows, err := r.db.Query("SELECT id, login, password, is_admin FROM users")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []models.User
	for rows.Next() {
		var u models.User
		var isAdmin int
		if err := rows.Scan(&u.ID, &u.Login, &u.Password, &isAdmin); err != nil {
			return nil, err
		}
		u.IsAdmin = isAdmin != 0
		users = append(users, u)
	}
	return users, nil
}

// ---- Cards ----

func (r *Repository) GetCardByID(id int64) (*models.Card, error) {
	row := r.db.QueryRow("SELECT id, number, balance, blocked, owner_name, key_id FROM cards WHERE id = ?", id)
	var c models.Card
	var blocked int
	err := row.Scan(&c.ID, &c.Number, &c.Balance, &blocked, &c.OwnerName, &c.KeyID)
	if err != nil {
		return nil, err
	}
	c.Blocked = blocked != 0
	return &c, nil
}

func (r *Repository) GetCardByNumber(number string) (*models.Card, error) {
	row := r.db.QueryRow("SELECT id, number, balance, blocked, owner_name, key_id FROM cards WHERE number = ?", number)
	var c models.Card
	var blocked int
	err := row.Scan(&c.ID, &c.Number, &c.Balance, &blocked, &c.OwnerName, &c.KeyID)
	if err != nil {
		return nil, err
	}
	c.Blocked = blocked != 0
	return &c, nil
}

func (r *Repository) GetAllCards() ([]models.Card, error) {
	rows, err := r.db.Query("SELECT id, number, balance, blocked, owner_name, key_id FROM cards")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cards []models.Card
	for rows.Next() {
		var c models.Card
		var blocked int
		if err := rows.Scan(&c.ID, &c.Number, &c.Balance, &blocked, &c.OwnerName, &c.KeyID); err != nil {
			return nil, err
		}
		c.Blocked = blocked != 0
		cards = append(cards, c)
	}
	return cards, nil
}

func (r *Repository) CreateCard(c *models.Card) error {
	// Проверяем, существует ли уже карта с таким номером
	var existingID int64
	err := r.db.QueryRow("SELECT id FROM cards WHERE number = ?", c.Number).Scan(&existingID)
	if err == nil {
		return errors.New("card with this number already exists")
	}
	if err != sql.ErrNoRows {
		return err
	}

	result, err := r.db.Exec("INSERT INTO cards (number, balance, blocked, owner_name, key_id) VALUES (?, ?, ?, ?, ?)",
		c.Number, c.Balance, c.Blocked, c.OwnerName, c.KeyID)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	c.ID = id
	return nil
}

func (r *Repository) UpdateCard(c *models.Card) error {
    // Проверяем, что новый номер не принадлежит другой карте
    var existingID int64
    err := r.db.QueryRow("SELECT id FROM cards WHERE number = ? AND id != ?", c.Number, c.ID).Scan(&existingID)
    if err == nil {
        return errors.New("another card with this number already exists")
    }
    if err != sql.ErrNoRows {
        return err
    }

    _, err = r.db.Exec("UPDATE cards SET number = ?, balance = ?, blocked = ?, owner_name = ?, key_id = ? WHERE id = ?",
        c.Number, c.Balance, c.Blocked, c.OwnerName, c.KeyID, c.ID)
    return err
}

func (r *Repository) DeleteCard(id int64) error {
	_, err := r.db.Exec("DELETE FROM cards WHERE id = ?", id)
	return err
}

func (r *Repository) UpdateBalance(cardID int64, newBalance int64) error {
	_, err := r.db.Exec("UPDATE cards SET balance = ? WHERE id = ?", newBalance, cardID)
	return err
}

// ---- Terminals ----

func (r *Repository) GetTerminalByID(id int64) (*models.Terminal, error) {
	row := r.db.QueryRow("SELECT id, serial, address, name FROM terminals WHERE id = ?", id)
	var t models.Terminal
	err := row.Scan(&t.ID, &t.Serial, &t.Address, &t.Name)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *Repository) GetAllTerminals() ([]models.Terminal, error) {
	rows, err := r.db.Query("SELECT id, serial, address, name FROM terminals")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var terminals []models.Terminal
	for rows.Next() {
		var t models.Terminal
		if err := rows.Scan(&t.ID, &t.Serial, &t.Address, &t.Name); err != nil {
			return nil, err
		}
		terminals = append(terminals, t)
	}
	return terminals, nil
}

func (r *Repository) CreateTerminal(t *models.Terminal) error {
	result, err := r.db.Exec("INSERT INTO terminals (serial, address, name) VALUES (?, ?, ?)",
		t.Serial, t.Address, t.Name)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	t.ID = id
	return nil
}

func (r *Repository) UpdateTerminal(t *models.Terminal) error {
	_, err := r.db.Exec("UPDATE terminals SET serial = ?, address = ?, name = ? WHERE id = ?",
		t.Serial, t.Address, t.Name, t.ID)
	return err
}

func (r *Repository) DeleteTerminal(id int64) error {
	_, err := r.db.Exec("DELETE FROM terminals WHERE id = ?", id)
	return err
}

// ---- Transactions ----

func (r *Repository) GetAllTransactions() ([]models.Transaction, error) {
	rows, err := r.db.Query("SELECT id, amount, card_id, terminal_id, created_at FROM transactions ORDER BY created_at DESC")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var txs []models.Transaction
	for rows.Next() {
		var t models.Transaction
		if err := rows.Scan(&t.ID, &t.Amount, &t.CardID, &t.TerminalID, &t.CreatedAt); err != nil {
			return nil, err
		}
		txs = append(txs, t)
	}
	return txs, nil
}

func (r *Repository) CreateTransaction(tx *models.Transaction) error {
	result, err := r.db.Exec("INSERT INTO transactions (amount, card_id, terminal_id, created_at) VALUES (?, ?, ?, ?)",
		tx.Amount, tx.CardID, tx.TerminalID, tx.CreatedAt)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	tx.ID = id
	return nil
}

// ---- Keys ----

func (r *Repository) GetKeyByID(id int64) (*models.Key, error) {
	row := r.db.QueryRow("SELECT id, data FROM keys WHERE id = ?", id)
	var k models.Key
	err := row.Scan(&k.ID, &k.Data)
	if err != nil {
		return nil, err
	}
	return &k, nil
}

func (r *Repository) GetAllKeys() ([]models.Key, error) {
	rows, err := r.db.Query("SELECT id, data FROM keys")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var keys []models.Key
	for rows.Next() {
		var k models.Key
		if err := rows.Scan(&k.ID, &k.Data); err != nil {
			return nil, err
		}
		keys = append(keys, k)
	}
	return keys, nil
}

func (r *Repository) CreateKey(k *models.Key) error {
	result, err := r.db.Exec("INSERT INTO keys (data) VALUES (?)", k.Data)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	k.ID = id
	return nil
}

func (r *Repository) UpdateKey(k *models.Key) error {
	_, err := r.db.Exec("UPDATE keys SET data = ? WHERE id = ?", k.Data, k.ID)
	return err
}

func (r *Repository) DeleteKey(id int64) error {
	_, err := r.db.Exec("DELETE FROM keys WHERE id = ?", id)
	return err
}

// GetCardByUID — теперь ищет по полю number
func (r *Repository) GetCardByUID(uid string) (*models.Card, error) {
	row := r.db.QueryRow("SELECT id, number, balance, blocked, owner_name, key_id FROM cards WHERE number = ?", uid)
	var c models.Card
	var blocked int
	err := row.Scan(&c.ID, &c.Number, &c.Balance, &blocked, &c.OwnerName, &c.KeyID)
	if err != nil {
		return nil, err
	}
	c.Blocked = blocked != 0
	return &c, nil
}

// CreateCardWithUID — создаёт карту с number = uid
func (r *Repository) CreateCardWithUID(c *models.Card) error {
	result, err := r.db.Exec(`
        INSERT INTO cards (number, balance, blocked, owner_name, key_id) 
        VALUES (?, ?, ?, ?, ?)`,
		c.Number, c.Balance, c.Blocked, c.OwnerName, c.KeyID)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	c.ID = id
	return nil
}
