# Backend multi-stage build
FROM golang:1.22-alpine AS backend-builder

WORKDIR /app

COPY go.mod ./
RUN go mod tidy

COPY . .

RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o server ./cmd/server

# Frontend build
FROM node:20-alpine AS frontend-builder

WORKDIR /app

COPY frontend/package.json frontend/package-lock.json* ./
RUN npm install --legacy-peer-deps --ignore-scripts

COPY frontend/ ./

ENV REACT_APP_API_URL=/api/v1
RUN npm run build

# Final image
FROM alpine:3.19

RUN apk add --no-cache nginx openssl

WORKDIR /app

COPY --from=backend-builder /app/server /app/server
COPY --from=backend-builder /app/migrations /app/migrations
COPY --from=backend-builder /app/docs /app/docs
COPY --from=frontend-builder /app/build /usr/share/nginx/html

COPY frontend/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/key.pem \
    -out /etc/nginx/certs/cert.pem \
    -subj "/C=RU/ST=Moscow/O=TransportCards/CN=localhost"

RUN mkdir -p /run/nginx && touch /run/nginx/nginx.pid

EXPOSE 8888

ENV DB_PATH=/app/transport.db
ENV PORT=8080

CMD ["sh", "-c", "/app/server & nginx -g 'daemon off;'"]