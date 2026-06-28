# {{SLUG}}

> {{DESCRIPTION}}

## Project identity

| Field | Value |
|---|---|
| **Stack** | {{TECH_STACK}} |
| **Forgejo** | https://forgejo.towneygorm.cc/daniel/{{SLUG}} |
| **Registry** | `registry.towneygorm.cc/{{SLUG}}/app` |
| **Dev VM** | vm-160 (192.168.86.160) |
| **Created** | {{DATE}} |

<!-- Add rows as the project gains an identity: **Prod VM** (if not the default),
     **Imported** (provenance + checksums if this came from a snapshot), etc. -->

## Repository layout

This is a fresh scaffold: app code in `src/`, Docker build context = repo root.

<!-- FILL IN the first time the layout diverges from that default. Describe where the
     deployable code lives and what the build context is — ESPECIALLY if it is not the
     repo root. Example to adapt:
       The deployable service lives in `service/` (the Docker build context). Repo-level
       tooling stays at the root: `.claude/`, `.forgejo/` (CI — Forgejo only reads
       workflows from the repo root), `docs/`, and this `CLAUDE.md`. -->

## Shared data plane (backing services)

This project uses the **shared homelab infrastructure**, sectioned off per app — do
**not** stand up a per-app database, bucket, or IdP unless an ADR in `docs/decisions/`
records a deliberate deviation.

- **Postgres** — shared cluster fronted by **PgBouncer** (transaction pooling),
  **database-per-app**: this app owns the `{{SLUG}}` database via a dedicated
  `{{SLUG}}_app` login role; `CONNECT` is revoked from `PUBLIC`, so no other app's role
  can reach this data. Cluster image is `pgvector/pgvector:pg17` (pgvector available
  per-database). Behind PgBouncer with `postgres.js`, set `prepare: false`.
- **Object storage** — **Garage** (S3-compatible), **bucket-per-app** with a scoped
  access key. Use presigned URLs; store the object key in the DB. No Object-Lock/WORM —
  put immutability at the backup layer if you need it.
- **Auth** — shared **Authentik** (OIDC), **one client per app**. Per-app roles via
  Application Entitlements on the `entitlements` scope (not the global `groups` claim).
  Identity = the OIDC `sub`.

The per-app "section" (DB+role, bucket+key, OIDC client) is provisioned by the
**vm-153 infra-manager**, which delivers creds into this app's `.env`. Standard names:
```
DATABASE_URL=postgresql://{{SLUG}}_app:<pw>@<pgbouncer-host>:<port>/{{SLUG}}
S3_ENDPOINT=  S3_REGION=  S3_BUCKET=  S3_ACCESS_KEY=  S3_SECRET_KEY=
OIDC_ISSUER=  OIDC_CLIENT_ID=  OIDC_CLIENT_SECRET=  OIDC_REDIRECT_URI=
```
The shared data plane runs **dev on vm-160, prod on vm-107** (Authentik is a shared
service, reused in both). Full reference: the project-scaffold plugin's
`references/shared-infrastructure.md`.

<!-- If this project needs none of these (pure CLI / library / static site), delete
     this whole section. -->

## Running locally (dev mode)

```bash
cp .env.example .env       # fill in any required values first
docker compose up          # start the dev stack (bind-mounts src/, hot reload)
docker compose logs -f     # tail logs in a second terminal
```

Service is available at the port defined in `compose.yaml` (check `ports:` block).

## Building a release

Use `Skill(build-and-push)` — builds the Docker image, tags it with semver + git SHA, and pushes both to `registry.towneygorm.cc/{{SLUG}}/app`.

## Deploying to production

Use `Skill(prod-deploy)` — updates the version pin in `/srv/infra/stacks/{{SLUG}}/.env` on vm-160 and restarts the prod compose stack.

## Running tests

Use `Skill(run-tests)` — or directly: `docker compose run --rm app <test-command>`

Update this section once you know the test command:
```bash
# e.g. docker compose run --rm app pytest
#      docker compose run --rm app npm test
#      docker compose run --rm app go test ./...
```

## Endpoints

<!-- FILL IN if this project exposes an HTTP surface; otherwise delete this section.
     Keep one row per route so the surface stays reviewable at a glance; note the auth
     on each. The /health row below is the one endpoint every service must have. -->

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness — `{"status":"ok"}` (no auth; used by CI and Kuma) |

## State

<!-- FILL IN once the project owns persistent state. List the tables / buckets / queues
     it owns and what each holds — one row each — and where the schema is owned
     (e.g. `src/migrations/`). Delete this section if the project is stateless. -->

## Upstream consumers (don't break these without coordination)

<!-- FILL IN as other systems start depending on this one. List each by name AND infra
     id so a breaking change is traceable: an n8n workflow, an NPM proxy host, a Kuma
     monitor, another service's API client, etc. Delete if nothing consumes this yet. -->

## Design & plans

Design docs and implementation plans live in `docs/`:
- `docs/superpowers/specs/<YYYY-MM-DD>-<topic>-design.md` — the **what & why** (stable once approved).
- `docs/superpowers/plans/<YYYY-MM-DD>-<topic>-plan.md` — the **how**, task by task (cross-references its design doc).
- `docs/decisions/adr-NNN-<slug>.md` — architecture decision records (seeded from ideation, if any).

Cross-reference the relevant doc inline from the section it backs (e.g. "Design+plan: `docs/superpowers/specs/…`").

## Available agents

See `.claude/agents/` — spawn any with the `Agent` tool when you need specialist help:
- `project-dev-agent` — primary build/debug/refactor agent (always available)
- (others depend on what was selected at project creation)

## Available skills

See `.claude/skills/` — invoke with `Skill(<name>)`:
- `build-and-push` — cut a release and push image
- `dev-deploy` — manage the dev compose stack
- `prod-deploy` — deploy to production
- `run-tests` — run test suite
- `db-migrate` — apply DB migrations
(only skills selected at creation are present)

The `project-scaffold` plugin also provides `Skill(promote-skill)` — see "Sharing skills across projects" below.

## graphify

If you build a knowledge graph for this repo (`graphify update .`, canonical output at the repo-root `graphify-out/`), treat codebase questions as graph queries first:
- `graphify query "<question>"` — scoped subgraph for a question (usually far smaller than grep or the full report).
- `graphify path "<A>" "<B>"` — how two things relate; `graphify explain "<concept>"` — a focused concept.
- Read `graphify-out/GRAPH_REPORT.md` only for broad architecture review; `graphify-out/wiki/index.md` (if present) for navigation.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

`.claude/settings.json` ships PreToolUse hooks that nudge "query the graph before grep/Read" — but only once `graphify-out/graph.json` exists, so they stay silent until you actually build a graph.

## Conventions

Rules in `.claude/rules/` are always loaded. Key ones:
- `git-flow.md` — commit message format, branch strategy, tag conventions
- `docker-conventions.md` — Dockerfile and compose best practices
- `api-conventions.md` — REST response shapes and status codes (if applicable)

## Deviations from catalogue conventions

<!-- FILL IN when this project deliberately diverges from the scaffold defaults (e.g.
     package dir is `service/app/` not `src/`, deps in `requirements.txt` not
     `pyproject.toml`, prod on a non-default VM). State WHY and the migration cost of
     "fixing" it, so a future session doesn't undo a deliberate choice. Delete if none. -->

## Known drift to reconcile

<!-- FILL IN to track gaps you know about but haven't fixed yet (e.g. a version constant
     ahead of the released tag, a single-stage Dockerfile pending a rewrite). Keeps
     tech-debt visible instead of forgotten. Delete if clean. -->

## Sharing skills across projects

If you author a custom **skill** here that's useful elsewhere, run
`Skill(promote-skill)` (from the `project-scaffold` plugin) — it copies
`.claude/skills/<name>/` into the central `skills/` library in the `claude-resources`
repo and indexes it, so any other project can find and reuse it. For **agents or rules**
worth sharing, add `catalogue_candidate: true` to their YAML frontmatter so the
catalogue sweep can pick them up.
