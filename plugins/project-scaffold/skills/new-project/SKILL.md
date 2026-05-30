---
name: new-project
description: "Scaffold a new development project on vm-160 — runs natively on the host. Creates the Forgejo repo, the project dir + CLAUDE.md + .claude/ from the bundled catalogue, git init/push, optional prod compose stack, and registers the project in prod dev-hub. Triggers: 'create a new project', 'scaffold a project', 'set up a new dev project', 'new-project'."
---

# Skill: new-project — Project Scaffolding

## When to use this skill

Use when Daniel wants to create a new development project, app, or service on vm-160.
Run this from any session on vm-160. Result: a ready-to-build project, registered in dev-hub.

---

## Prerequisites

- You are running on **vm-160** (the dev host) in any Claude session with this plugin installed.
- The tooling secrets file exists: `~/projects/claude-resources/.env` (mode 600, gitignored) with `FORGEJO_API_TOKEN` and `REGISTRY_PASSWORD`. If missing, halt and tell Daniel to stage it (see the project-scaffold README).
- The dev-hub plugin is installed (Step 0.5 verifies this).

### One-time secret setup (if `~/projects/claude-resources/.env` is missing)

The Forgejo API token needs scopes **`write:repository` AND `write:user`**
(`write:user` is required for `POST /api/v1/user/repos`; `write:repository` alone
gets 403).

Stage the file by running the bootstrap script on vm-153 (see the project-scaffold
README for the exact commands). The script reads values from the vm-153 vault and
pipes them directly to vm-160 over SSH stdin — values are never printed. The
resulting file at `~/projects/claude-resources/.env` should look like:

```
FORGEJO_API_USER=homelab-agent
FORGEJO_API_TOKEN=<token>
REGISTRY_PASSWORD=<password>
```

Set file permissions to `chmod 600 ~/projects/claude-resources/.env` and confirm
it is gitignored before proceeding.

---

## Step 0.5 — Verify the dev-hub plugin is installed on vm-160

Before any scaffolding, confirm the dev-hub plugin is installed on the
target host. New projects depend on it being there. The plugin is installed
from the **claude-resources** marketplace (not a symlink — that mechanism is
retired).

```bash
claude plugin list 2>/dev/null | grep -q 'dev-hub@claude-resources' && echo INSTALLED || echo MISSING
```

Expected: prints `INSTALLED`.

If `MISSING`, halt with:

> "dev-hub plugin not installed. One-time setup needed:
> `claude plugin marketplace add https://forgejo.towneygorm.cc/daniel/claude-resources.git --scope user && claude plugin install dev-hub@claude-resources --scope user`.
> Re-run new-project after installing."

Do NOT proceed past this step until the plugin reports `INSTALLED`.

---

## Step 1 — Gather inputs

Ask Daniel for:

| Input | Format | Example |
|---|---|---|
| `SLUG` | kebab-case | `receipt-tracker` |
| `DESCRIPTION` | 1–2 sentences | `FastAPI service that OCRs receipts and stores line items` |
| `TECH_STACK` | see options below | `python-fastapi` |
| Components | checklist below | `db-agent, build-and-push, dev-deploy, run-tests, postgres` |
| Deployable service? | yes/no | yes → creates `/srv/infra/stacks/<slug>/` |

**Tech stack options:** `python-fastapi` | `node-express` | `node-nextjs` | `go-http` | `static-site` | `none`

**Component checklist** — present this to Daniel and record selections:

| Category | Component | Default |
|---|---|---|
| Agent | `project-dev-agent` | ✅ always included |
| Agent | `db-agent` | opt-in |
| Agent | `test-agent` | opt-in |
| Agent | `frontend-agent` | opt-in |
| Skill | `build-and-push` | opt-in |
| Skill | `dev-deploy` | opt-in |
| Skill | `prod-deploy` | opt-in (only if build-and-push selected) |
| Skill | `run-tests` | opt-in |
| Skill | `db-migrate` | opt-in |
| Rule | `docker-conventions` | ✅ auto-included if Dockerfile present |
| Rule | `git-flow` | ✅ always included |
| Rule | `testing-conventions` | opt-in |
| Rule | `api-conventions` | opt-in |
| Compose sidecar | `postgres` | opt-in |
| Compose sidecar | `redis` | opt-in |

---

## Step 2 — Load the Forgejo API token

Read the token from the staged secrets file into a shell var — **never echo it**:

```bash
ENVF=~/projects/claude-resources/.env
[ -f "$ENVF" ] || { echo "ERROR: $ENVF missing — stage secrets first (see Prerequisites)."; exit 1; }
FORGEJO_TOKEN=$(grep -E '^FORGEJO_API_TOKEN=' "$ENVF" | cut -d= -f2-)
[ -n "$FORGEJO_TOKEN" ] || { echo "ERROR: FORGEJO_API_TOKEN not set in $ENVF"; exit 1; }
```

Keep `$FORGEJO_TOKEN` in the environment for Steps 3 and 8 of the same Bash flow,
or re-read it as above. Do not print it.

---

## Step 3 — Create Forgejo repository

```bash
curl -s -X POST http://192.168.86.160:3000/api/v1/user/repos \
  -H "Authorization: token ${FORGEJO_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${SLUG}\",\"description\":\"${DESCRIPTION}\",\"private\":true,\"auto_init\":false}"
```

- **200/201** → success. Capture `clone_url` from response.
- **409** → repo already exists. Stop and inform Daniel — choose a different slug or delete the existing repo.
- **401** → token invalid. Re-read from `~/projects/claude-resources/.env`.

---

## Step 4 — Create project directory structure on vm-160

```bash
mkdir -p ~/projects/${SLUG}/.claude/agents \
         ~/projects/${SLUG}/.claude/skills \
         ~/projects/${SLUG}/.claude/rules \
         ~/projects/${SLUG}/.forgejo/workflows \
         ~/projects/${SLUG}/src
```

---

## Step 5 — Generate and write files from catalogue

All catalogue templates live at:
`${CLAUDE_PLUGIN_ROOT}/catalogue/`

**Token substitution** — when writing each file, replace these literal tokens:
| Token | Replace with |
|---|---|
| `{{SLUG}}` | The project slug |
| `{{DESCRIPTION}}` | The project description |
| `{{TECH_STACK}}` | The selected tech stack identifier |
| `{{DATE}}` | Today's date (YYYY-MM-DD) |

**Write method**: Read each template from `${CLAUDE_PLUGIN_ROOT}/catalogue/<tpl>`,
substitute the tokens, and write the result to `~/projects/${SLUG}/<dest>` locally
(no SSH/scp — you are on vm-160). Use the Write/Edit tools or a bash heredoc.

**Skill destinations are directories:** Claude Code only discovers a skill when it is laid out as `.claude/skills/<name>/SKILL.md` (a directory containing SKILL.md) — a flat `.claude/skills/<name>.md` file is NOT discovered. `mkdir -p ~/projects/${SLUG}/.claude/skills/<name>` before writing each skill. (Agents are the opposite: a single `.claude/agents/<name>.md` file is correct.)

### Always-included files

| Template (in catalogue/) | Destination on vm-160 |
|---|---|
| `CLAUDE.md.tpl` | `~/projects/${SLUG}/CLAUDE.md` |
| `README.md.tpl` | `~/projects/${SLUG}/README.md` |
| `gitignore.tpl` | `~/projects/${SLUG}/.gitignore` |
| `env.example.tpl` | `~/projects/${SLUG}/.env.example` |
| `settings.json.tpl` | `~/projects/${SLUG}/.claude/settings.json` |
| `agents/project-dev-agent.md.tpl` | `~/projects/${SLUG}/.claude/agents/project-dev-agent.md` |
| `rules/git-flow.md.tpl` | `~/projects/${SLUG}/.claude/rules/git-flow.md` |
| `ci/forgejo-ci.yaml.tpl` | `~/projects/${SLUG}/.forgejo/workflows/ci.yaml` |

If TECH_STACK != `none`, also include the matching scaffold:
`scaffolds/${TECH_STACK}/` → copy all files preserving structure to `~/projects/${SLUG}/`

If TECH_STACK has a Dockerfile, also include:
`rules/docker-conventions.md.tpl` → `~/projects/${SLUG}/.claude/rules/docker-conventions.md`

### Conditionally-included files (per Daniel's selections)

| Component | Template | Destination |
|---|---|---|
| `db-agent` | `agents/db-agent.md.tpl` | `.claude/agents/db-agent.md` |
| `test-agent` | `agents/test-agent.md.tpl` | `.claude/agents/test-agent.md` |
| `frontend-agent` | `agents/frontend-agent.md.tpl` | `.claude/agents/frontend-agent.md` |
| `build-and-push` | `skills/build-and-push.md.tpl` | `.claude/skills/build-and-push/SKILL.md` |
| `dev-deploy` | `skills/dev-deploy.md.tpl` | `.claude/skills/dev-deploy/SKILL.md` |
| `prod-deploy` | `skills/prod-deploy.md.tpl` | `.claude/skills/prod-deploy/SKILL.md` |
| `run-tests` | `skills/run-tests.md.tpl` | `.claude/skills/run-tests/SKILL.md` |
| `db-migrate` | `skills/db-migrate.md.tpl` | `.claude/skills/db-migrate/SKILL.md` |
| `testing-conventions` | `rules/testing-conventions.md.tpl` | `.claude/rules/testing-conventions.md` |
| `api-conventions` | `rules/api-conventions.md.tpl` | `.claude/rules/api-conventions.md` |
| `postgres` sidecar | `scaffolds/sidecars/postgres.yaml.tpl` | merge into `compose.yaml` services block |
| `redis` sidecar | `scaffolds/sidecars/redis.yaml.tpl` | merge into `compose.yaml` services block |

---

## Step 6 — Git initialise and push

Run locally on vm-160. The repo was created empty in Step 3, so push to the SSH
remote using the host's deploy key — no token in the URL.

```bash
cd ~/projects/${SLUG}
git init -b main
git config user.name 'Daniel McGeevers'
git config user.email 'dmcg2448@gmail.com'
git add .
git commit -m 'chore: initial scaffold via new-project'
git remote add origin ssh://git@forgejo.towneygorm.cc:222/daniel/${SLUG}.git
git push -u origin main
```

---

## Step 6.5 — Kick dev-hub project discovery

After the new project directory exists on vm-160 (post Step 4) and git
init has run (post Step 6), nudge dev-hub to scan for it so it appears
in the dashboard immediately instead of waiting for the next periodic
scan.

```bash
curl -sS -X POST http://localhost:8010/api/v1/projects/refresh || true
```

Non-fatal (`|| true`) — if dev-hub is down at create time, the project
will appear on the next periodic scan anyway.

After the call, look up the new project's id by querying the dev-hub REST API:

```bash
DEV_HUB_ID=$(curl -sS http://localhost:8010/api/v1/projects \
  | python3 -c "import json,sys; d=json.load(sys.stdin)['data']; items=d.get('items') or d; ids=[p['id'] for p in items if p['slug']=='${SLUG}']; print(ids[0] if ids else '')")
```

`DEV_HUB_ID` may be empty (dev-hub was down, or the project's path is
outside the REPOS mount). Step 9 writes whatever you got, including
empty.

---

## Step 6.6 — (Conditional) dev-backend override

**Most projects need nothing here.** With no override, the dev-hub plugin's MCP
points at the **prod** dev-hub (`http://192.168.86.160:8011/mcp`) — correct,
since the project's tracking lives in prod. Leave it alone for normal projects.

**Only** scaffold an override when the project is itself a dev/prod-split service
that gets *developed against its own dev backend* (the way dev-hub is). For that
case, the in-repo session should target the dev instance via a per-repo env var
read at session launch — set up with `direnv`:

1. Write a tracked `.envrc` at the repo root exporting the dev coordinate, e.g.
   `export DEV_HUB_MCP_URL=http://192.168.86.160:8001/mcp` (dev dev-hub) — or the
   project's own `*_MCP_URL` if it ships its own MCP.
2. Ensure direnv is set up on vm-160 (one-time, already done as of 2026-05-30):
   static binary in `~/.local/bin`, `eval "$(direnv hook bash)"` in `~/.bashrc`.
3. `ssh … daniel@192.168.86.160 "cd ~/projects/${SLUG} && ~/.local/bin/direnv allow ."`

The env var is read by Claude at launch, so `claude` must be started from a shell
that has entered the repo (direnv prints `loading …/.envrc`). Do **not** leave a
duplicate project-local `.claude.json` MCP server — the plugin + this override is
the single connection.

> The broader question of which dev tooling should be project-local (copied from
> this catalogue) vs shared via the `claude-resources` marketplace is a separate,
> still-open design decision — see the claude-resources lifecycle spec.

---

## Step 7 — (Conditional) Create prod compose stack

**Ask Daniel** if this is a deployable service (i.e. should run continuously via compose, not just a library/CLI tool).

If yes:
```bash
mkdir -p /srv/infra/stacks/${SLUG}
```

Write `/srv/infra/stacks/${SLUG}/compose.yaml` pulling from `registry.towneygorm.cc/${SLUG}/app:${APP_VERSION}`.
Write `/srv/infra/stacks/${SLUG}/.env` with `APP_VERSION=latest` (update after first build-and-push).

---

## Step 8 — Set CI registry secret on the new repo

Fetch the registry credential from `~/projects/claude-resources/.env` and PUT it as
the repo-level `REGISTRY_PASSWORD` secret. This makes `push-on-main` work on the
very first merge to `main` — no manual UI step required.

**Why per-repo, not user-level only?** Forgejo 15.0.1 accepts PUT to
`/user/actions/secrets/{name}` (201) and the value is also set at user level
as a hedge, but the runner's visibility of user-level secrets to workflows is
not guaranteed in this Forgejo version (GET on `/user/actions/secrets` 404s
even after a successful PUT, suggesting incomplete plumbing). Setting it
per-repo is the only path we know works for sure.

Read the registry password and Forgejo API token from the staged secrets file
inside one Bash invocation so neither value crosses the agent transcript boundary:

```bash
ENVF=~/projects/claude-resources/.env
REG_PW=$(grep -E '^REGISTRY_PASSWORD=' "$ENVF" | cut -d= -f2-)
TOKEN=$(grep -E '^FORGEJO_API_TOKEN=' "$ENVF" | cut -d= -f2-)
PAYLOAD=$(python3 -c 'import json,sys; print(json.dumps({"data": sys.argv[1]}))' "$REG_PW")
unset REG_PW
curl -s -o /dev/null -w "HTTP=%{http_code}\n" -X PUT \
  -H "Authorization: token ${TOKEN}" -H "Content-Type: application/json" \
  --data-binary "$PAYLOAD" \
  http://192.168.86.160:3000/api/v1/repos/daniel/${SLUG}/actions/secrets/REGISTRY_PASSWORD
unset PAYLOAD TOKEN
```

- **HTTP 201** → secret created. Continue to Step 9.
- **HTTP 204** → secret updated (already existed — should not happen on a fresh repo).
- **HTTP 401** → token invalid; re-read from `~/projects/claude-resources/.env`.
- **HTTP 404** → repo not found; check Step 3 succeeded.

**Verify** (optional — repo-level GET works fine, unlike user-level):
```bash
T=$(grep -E '^FORGEJO_API_TOKEN=' ~/projects/claude-resources/.env | cut -d= -f2-)
curl -s -H "Authorization: token ${T}" \
  http://192.168.86.160:3000/api/v1/repos/daniel/${SLUG}/actions/secrets
unset T
# Expect: [{"name":"REGISTRY_PASSWORD","created_at":"..."}]
```

If REGISTRY_PASSWORD is ever rotated, re-run this step for every active repo.

---

## Step 9 — Report

Report to Daniel:

```
✅ Project {{SLUG}} scaffolded and ready
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Forgejo:  https://forgejo.towneygorm.cc/daniel/{{SLUG}}
Launch:   ssh daniel@192.168.86.160
          cd ~/projects/{{SLUG}} && claude
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reminder: Add REGISTRY_PASSWORD secret in Forgejo repo settings for CI image pushes
```

---

## Troubleshooting

| Issue | Resolution |
|---|---|
| Forgejo API 401 | Token expired — re-read from `~/projects/claude-resources/.env` (or re-stage if the file is missing) |
| Forgejo API 409 | Repo already exists — use different slug or delete existing |
| git push fails (auth) | Check the SSH deploy key on vm-160 (`ssh-add -l`); confirm remote is `ssh://git@forgejo.towneygorm.cc:222/...` |
| `.env` missing | Run the one-time secret setup from the Prerequisites section |
