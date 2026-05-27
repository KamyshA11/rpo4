# ---- FRONTEND BUILDER ----
FROM node:20-alpine AS frontend-builder

WORKDIR /frontend

# Копируем только package.json для кэширования зависимостей
COPY frontend/package*.json ./

# Используем npm ci вместо npm install (быстрее и детерминированнее)
# Убираем rm -f package-lock.json, чтобы использовать точные версии
RUN npm ci --legacy-peer-deps --ignore-scripts

# Копируем остальной код
COPY frontend/ .

# Сборка фронтенда
RUN npm run build

# ---- BACKEND BUILDER ----
FROM golang:1.22-alpine AS backend-builder

WORKDIR /app

# 1. Копируем только go.mod и go.sum (для кэширования зависимостей)
COPY backend/go.mod backend/go.sum ./
RUN go mod download && go mod verify

# 2. Копируем остальной код
COPY backend/ .

# 3. Сборка с оптимизациями
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o server ./cmd/server

# ---- RUNTIME STAGE ----
FROM alpine:3.19

# Устанавливаем пакеты и очищаем кэш в одном слое
RUN apk add --no-cache ca-certificates bash nginx openssl && \
    rm -rf /var/cache/apk/*

WORKDIR /app

# Копируем бинарники и файлы
COPY --from=backend-builder /app/server /app/server
COPY --from=backend-builder /app/migrations /app/migrations
COPY --from=backend-builder /app/docs /app/docs
COPY --from=frontend-builder /frontend/build /usr/share/nginx/html

# Копируем конфиги
COPY deploy/nginx.conf /etc/nginx/nginx.conf
COPY deploy/start.sh /start.sh

# Генерируем SSL и настраиваем права (объединяем RUN команды)
RUN mkdir -p /etc/nginx/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/key.pem \
    -out /etc/nginx/certs/cert.pem \
    -subj "/C=RU/ST=Moscow/O=TransportCards/CN=localhost" && \
    chmod +x /start.sh && \
    chmod +x /app/server && \
    mkdir -p /run/nginx && \
    touch /run/nginx/nginx.pid

EXPOSE 8888

ENV DB_PATH=/app/transport.db
ENV PORT=8080

CMD ["/start.sh"]