services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - ./src:/app/src           # bind-mount for dev
    command: node --watch src/app.js
    env_file: .env
    restart: unless-stopped
