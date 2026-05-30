# Redis 7 sidecar — merge this block into your compose.yaml services section
# Also add `redis_data:` under the top-level `volumes:` key
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 5s
    restart: unless-stopped
