services:
  app:
    build: .
    ports:
      - "8080:80"
    volumes:
      - ./src:/usr/share/nginx/html    # live-reload via bind-mount
    restart: unless-stopped
