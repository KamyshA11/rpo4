# Transport Card Payment Authorization API

REST API сервер для авторизации платежей транспортными картами.

## Запуск

### Docker

```bash
docker build -t transport-api .
docker run -p 8888:8888 transport-api
```

Или через docker-compose:

```bash
docker-compose up -d
```

### Локальная разработка

```bash
go mod download
go run ./cmd/server
```

## API Endpoints

### Авторизация

- `POST /api/v1/auth/login` - Вход по паролю, получение JWT токена
- `GET /api/v1/auth/me` - Информация о текущем пользователе

### Пользователи (только админ)

- `GET /api/v1/users` - Список пользователей
- `POST /api/v1/users` - Создать пользователя
- `PUT /api/v1/users/:id` - Обновить пользователя
- `DELETE /api/v1/users/:id` - Удалить пользователя

### Карты

- `GET /api/v1/cards` - Список карт
- `GET /api/v1/cards/:id` - Получить карту
- `POST /api/v1/cards` - Создать карту
- `PUT /api/v1/cards/:id` - Обновить карту
- `DELETE /api/v1/cards/:id` - Удалить карту

### Терминалы

- `GET /api/v1/terminals` - Список терминалов
- `GET /api/v1/terminals/:id` - Получить терминал
- `POST /api/v1/terminals` - Создать терминал
- `PUT /api/v1/terminals/:id` - Обновить терминал
- `DELETE /api/v1/terminals/:id` - Удалить терминал
- `POST /api/v1/terminals/authorize` - Авторизация платежа
- `GET /api/v1/terminals/keys` - Загрузка ключей

### Транзакции

- `GET /api/v1/transactions` - Список транзакций
- `POST /api/v1/transactions` - Создать транзакцию

### Ключи (только админ)

- `GET /api/v1/keys` - Список ключей
- `GET /api/v1/keys/:id` - Получить ключ
- `POST /api/v1/keys` - Создать ключ
- `PUT /api/v1/keys/:id` - Обновить ключ
- `DELETE /api/v1/keys/:id` - Удалить ключ

## Swagger документация

Доступна по адресу: https://localhost:8888/api/v1/swagger/index.html

## Примеры использования

### Авторизация

```bash
curl -X POST https://localhost:8888/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"login": "admin", "password": "admin123"}'
```

### Авторизация платежа

```bash
curl -X POST https://localhost:8888/api/v1/terminals/authorize \
  -H "Content-Type: application/json" \
  -d '{"card_number": "1234567890", "amount": 100, "terminal_id": 1}'
```

### Загрузка ключей

```bash
curl https://localhost:8888/api/v1/terminals/keys \
  -H "Authorization: Bearer <token>"
```

## Данные по умолчанию

- Логин: `admin`
- Пароль: `admin123`
