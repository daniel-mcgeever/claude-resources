services:
  app:
    build:
      context: .
      target: deps        # only install deps in dev; no full build
    ports:
      - "3000:3000"
    volumes:
      - ./src:/app/src
      - ./public:/app/public
    command: npm run dev
    env_file: .env
    environment:
      - NEXT_TELEMETRY_DISABLED=1
    restart: unless-stopped
