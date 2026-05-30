---
name: dev-deploy
description: "Start or restart the {{SLUG}} dev stack on vm-160. Uses bind-mounts from src/ — no image build needed for code changes."
---

# Skill: dev-deploy — {{SLUG}}

## Start / restart
```bash
cd ~/projects/{{SLUG}}

# First time or after Dockerfile/compose changes:
docker compose up -d --build

# After code-only changes (hot-reload should pick up automatically, but if not):
docker compose restart app
```

## Tail logs
```bash
docker compose logs -f
docker compose logs -f app   # single service
```

## Status check
```bash
docker compose ps
```

## Stop
```bash
docker compose stop         # preserves containers + named volumes
# docker compose down       # removes containers (keeps named volumes) — confirm before running
```

## Verify
- All services show `Up` in `docker compose ps`
- App responds at the configured dev port (check compose.yaml for the published port)
