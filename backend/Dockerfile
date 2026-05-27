# ---- BACKEND BUILDER ----
FROM golang:1.22-alpine AS backend-builder

WORKDIR /app

# 1. Сначала копируем только go.mod и go.sum (для кэширования зависимостей)
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# 2. Копируем остальной код
COPY . .

# 3. Сборка с оптимизациями
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o server ./cmd/server

# ---- FRONTEND BUILDER ----
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# 1. Сначала копируем package.json (для кэширования node_modules)
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci --legacy-peer-deps --ignore-scripts

# 2. Копируем остальной код фронтенда
COPY frontend/ ./

ENV REACT_APP_API_URL=/api/v1
RUN npm run build

# ---- FINAL IMAGE ----
FROM alpine:3.19

# Устанавливаем только необходимые пакеты
RUN apk add --no-cache nginx openssl && \
    # Очищаем кэш apk
    rm -rf /var/cache/apk/*

WORKDIR /app

# Копируем бинарники
COPY --from=backend-builder /app/server /app/server
COPY --from=backend-builder /app/migrations /app/migrations
COPY --from=backend-builder /app/docs /app/docs
COPY --from=frontend-builder /app/build /usr/share/nginx/html

# Копируем конфиги
COPY frontend/nginx.conf /etc/nginx/nginx.conf

# Генерация SSL сертификата
RUN mkdir -p /etc/nginx/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/key.pem \
    -out /etc/nginx/certs/cert.pem \
    -subj "/C=RU/ST=Moscow/O=TransportCards/CN=localhost" && \
    mkdir -p /run/nginx && \
    touch /run/nginx/nginx.pid

EXPOSE 8888

ENV DB_PATH=/app/transport.db
ENV PORT=8080

# Используем exec-формат для лучшего управления сигналами
CMD ["sh", "-c", "/app/server & nginx -g 'daemon off;'"]