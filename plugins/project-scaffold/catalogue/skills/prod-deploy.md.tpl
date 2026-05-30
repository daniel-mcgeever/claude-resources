---
name: prod-deploy
description: "Deploy a new release of {{SLUG}} to the production stack at /srv/infra/stacks/{{SLUG}}/ on vm-160. Pulls a pinned image tag from registry.towneygorm.cc. Use after Skill(build-and-push) completes."
---

# Skill: prod-deploy — {{SLUG}}

## Prerequisites
- A release tag has been pushed to `registry.towneygorm.cc/{{SLUG}}/app:<tag>` via `Skill(build-and-push)`
- The prod stack exists at `/srv/infra/stacks/{{SLUG}}/` on vm-160

## Procedure

### 1 — Update the version pin
```bash
# On vm-160
nano /srv/infra/stacks/{{SLUG}}/.env
# Set: APP_VERSION=v0.x.y
```

### 2 — Pull and restart
```bash
cd /srv/infra/stacks/{{SLUG}}
docker compose pull
docker compose up -d
```

### 3 — Verify
```bash
docker compose ps             # all Up
docker compose logs --tail=30 # check for startup errors
```

## Rollback
Set `APP_VERSION` back to the previous tag in `.env`, then:
```bash
docker compose pull && docker compose up -d
```

## Notes
- Prod stack uses registry-pinned images, not bind-mounts
- Named volumes persist across restarts; data is NOT lost on `up -d`
