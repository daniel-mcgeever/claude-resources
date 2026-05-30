services:
  app:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./src:/app/src          # bind-mount for hot-reload in dev
    command: uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
    env_file: .env
    restart: unless-stopped
    # depends_on:
    #   db:
    #     condition: service_healthy

# volumes:   # uncomment when adding db/redis sidecars
#   db_data:
#   redis_data:
