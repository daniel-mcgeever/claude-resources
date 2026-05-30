---
name: docker-conventions
description: "Docker and Docker Compose authoring standards for {{SLUG}}."
paths: []
---

# Docker conventions — {{SLUG}}

## Dockerfiles
- **Multi-stage builds** — always. Builder stage installs deps; final stage is minimal.
- **Base images** — pin to `major.minor` (e.g. `python:3.12-slim`, `node:22-alpine`). Never use `latest`.
- **Non-root user** — add and switch to a non-root user in the final stage.
  ```dockerfile
  RUN useradd -m -u 1000 appuser
  USER appuser
  ```
- **Layer order** — copy dependency manifests first, install, then copy source. Maximises cache hits.
- **No secrets in image** — never COPY `.env` or pass secrets as build ARGs. Use runtime env vars.
- **EXPOSE** — declare the port but don't publish it in the Dockerfile; do that in compose.yaml.

## compose.yaml — dev mode
- **Bind-mount `src/`** for hot-reload; never bind-mount the whole project root.
- **env_file: .env** for runtime configuration. `.env.example` documents all required vars.
- **Named volumes** for all persistent data. No anonymous volumes (`- /data`).
- **`restart: unless-stopped`** on all long-running services.
- **Health checks** on all stateful sidecars (db, redis) — gate app startup with `depends_on: condition: service_healthy`.

## Prod vs dev compose
- Dev (`compose.yaml`): bind-mounts, hot-reload cmd, no image tag pinning needed.
- Prod (`/srv/infra/stacks/{{SLUG}}/compose.yaml`): pulls `registry.towneygorm.cc/{{SLUG}}/app:${APP_VERSION}`, no bind-mounts.

## .dockerignore
Always maintain `.dockerignore` excluding: `.env`, `.git`, `node_modules/`, `__pycache__/`, test data, local build artefacts.
