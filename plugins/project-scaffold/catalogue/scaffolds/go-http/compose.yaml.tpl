services:
  app:
    image: golang:1.22-alpine
    working_dir: /app
    ports:
      - "8080:8080"
    volumes:
      - .:/app
      - go-cache:/root/go/pkg/mod
    command: go run .
    env_file: .env
    restart: unless-stopped

volumes:
  go-cache:
