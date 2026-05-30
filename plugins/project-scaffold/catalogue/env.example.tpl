# {{SLUG}} — environment variables
# Copy this file to .env and fill in values before running
# .env is gitignored and must never be committed

# ── Application ──────────────────────────────────────────────
PORT=8000
APP_ENV=development
LOG_LEVEL=info
# SECRET_KEY=change-me-in-production

# ── Database (uncomment if using postgres sidecar) ───────────
# POSTGRES_DB={{SLUG}}
# POSTGRES_USER=app
# POSTGRES_PASSWORD=changeme
# DATABASE_URL=postgresql://app:changeme@db:5432/{{SLUG}}

# ── Redis (uncomment if using redis sidecar) ─────────────────
# REDIS_URL=redis://redis:6379/0

# ── External services ─────────────────────────────────────────
# Add API keys and external service URLs here
