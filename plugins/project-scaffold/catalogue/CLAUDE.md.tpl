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

## dev-hub integration

This project is tracked in
[dev-hub](http://192.168.86.160:8013/projects/{{SLUG}}) (the **prod**
dashboard). Use it as the source of truth for todos, plans, and brainstorming.

**Before starting work:** `/dev-hub-workflow` — lists open todos, walks
scope → plan → write-back. Or just say "pick something from dev-hub".

**Brainstorming:** `/dev-hub-brainstorm` walks the capture loop —
reformulate the user's idea into a single sharp thought, persist via
`create_thought`, suggest links to related open thoughts. Flag ripe
clusters for promotion.

**During work:** write plans to `<repo>/plans/<slug>.md` via `create_plan`,
never by hand. Capture spontaneous user thoughts via `create_thought`.

**Promoting thoughts:** `/dev-hub-promote` turns a cluster of ripe
thoughts into a plan / list of todos / milestone, atomically.

**After shipping:** `/close-out-plan` marks the plan accepted and retires
its linked todos.

**Diagnostics:** `/dev-hub-doctor` if something feels off. The MCP tool
surface is discovered at runtime (`tools/list`) — there is no bundled static
reference file.

## Conventions

Rules in `.claude/rules/` are always loaded. Key ones:
- `git-flow.md` — commit message format, branch strategy, tag conventions
- `docker-conventions.md` — Dockerfile and compose best practices
- `api-conventions.md` — REST response shapes and status codes (if applicable)

## Catalogue convention

If you add a custom agent, skill, or rule during development that might be useful across other projects, add `catalogue_candidate: true` to its YAML frontmatter. It will be surfaced by `Skill(catalogue-consolidation)` when run from the infra-manager orchestrator on vm-153.
