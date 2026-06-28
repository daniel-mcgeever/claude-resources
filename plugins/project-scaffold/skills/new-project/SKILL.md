---
name: new-project
description: "Scaffold a new development project on vm-160 — runs natively on the host. Creates the Forgejo repo, the project dir + CLAUDE.md + .claude/ from the bundled catalogue, git init/push, and an optional prod compose stack. Triggers: 'create a new project', 'scaffold a project', 'set up a new dev project', 'new-project'."
---

# Skill: new-project — Project Scaffolding

## When to use this skill

Use when Daniel wants to create a new development project, app, or service on vm-160.
Run this from any session on vm-160. Result: a ready-to-build project pushed to Forgejo.

**Loose or fuzzy scope?** Don't force the design here. Run `project-scaffold:explore-project-idea` (shape the idea conversationally) and `project-scaffold:decide-architecture` (choose + record the stack as ADRs) first — they leave a draft this skill picks up automatically (Step 1).

**Needs a database, object storage, or auth?** It uses the **shared homelab infrastructure** by default
(Postgres database-per-app · Garage bucket-per-app · Authentik OIDC client-per-app). Read
**`plugins/project-scaffold/references/shared-infrastructure.md`** (relative: `../../references/shared-infrastructure.md`):
the per-app "section" (DB+role, bucket+key, OIDC client) is provisioned by the **vm-153 infra-manager**,
and the app's `.env` / `.env.example` use the standard `DATABASE_URL` / `S3_*` / `OIDC_*` vars from that
reference. Don't stand up a per-app database/bucket/IdP unless an ADR records a deliberate deviation.

---

## Prerequisites

- You are running on **vm-160** (the dev host) in any Claude session with this plugin installed.
- The tooling secrets file exists: `~/projects/claude-resources/.env` (mode 600, gitignored) with `FORGEJO_API_TOKEN` and `REGISTRY_PASSWORD`. If missing, halt and tell Daniel to stage it (see the project-scaffold README).

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

## Step 1 — Gather inputs

**First, check for a staging draft from the ideation skills.** Drafts live in the Forgejo-backed repo `daniel/scaffold-drafts`, cloned at `~/projects/scaffold-drafts`. If `~/projects/scaffold-drafts/<slug>/` exists, read its `concept-brief.md` and/or `decisions/adr-*.md` and use them to pre-fill `DESCRIPTION` (from the brief) and `TECH_STACK` (from the accepted ADRs) — confirm with Daniel rather than asking from scratch, and honor any decision marked *deferred*. (If `~/projects/scaffold-drafts` isn't cloned but you expect a draft: `git clone ssh://git@forgejo.towneygorm.cc:222/daniel/scaffold-drafts.git ~/projects/scaffold-drafts` then `git -C ~/projects/scaffold-drafts pull`.) Remember the slug — **Step 6.5** ports the draft into the new repo's `docs/` and removes it from the drafts repo. If no draft exists, gather inputs as below.

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
BODY=$(python3 -c 'import json,sys; print(json.dumps({"name":sys.argv[1],"description":sys.argv[2],"private":True,"auto_init":False}))' "$SLUG" "$DESCRIPTION")
curl -s -X POST http://192.168.86.160:3000/api/v1/user/repos \
  -H "Authorization: token ${FORGEJO_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$BODY"
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
         ~/projects/${SLUG}/docs/superpowers/specs \
         ~/projects/${SLUG}/docs/superpowers/plans \
         ~/projects/${SLUG}/docs/decisions \
         ~/projects/${SLUG}/src
# keep the docs/ tree in git even before it has content
touch ~/projects/${SLUG}/docs/superpowers/specs/.gitkeep \
      ~/projects/${SLUG}/docs/superpowers/plans/.gitkeep \
      ~/projects/${SLUG}/docs/decisions/.gitkeep
```

The `docs/` tree is where design docs, plans, and ADRs live (the CLAUDE.md
"Design & plans" section documents the convention). If Step 1 found an ideation
draft, **Step 6.5** copies its concept brief + ADRs into this tree and then
removes the `<slug>` folder from the `scaffold-drafts` repo — so a folder there
always means *an idea not yet built*.

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
set -e
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

## Step 6.5 — Port ideation draft into the repo (only if a draft was used)

If Step 1 found a draft at `~/projects/scaffold-drafts/<slug>/`, copy the thinking into
the new repo's `docs/` tree now — **this is the canonical home for the rationale after
build** — then retire the draft.

The delete is gated on success — **never remove the draft until the copy is committed
and pushed**, or you'll lose the ideation with nowhere to read it.

1. **ADRs → `docs/decisions/`.** Copy each `decisions/adr-*.md` across verbatim:
   ```bash
   cp ~/projects/scaffold-drafts/${SLUG}/decisions/adr-*.md ~/projects/${SLUG}/docs/decisions/ 2>/dev/null || true
   ```
2. **Concept brief → `docs/`.** Copy the brief so it stays readable alongside the code:
   ```bash
   cp ~/projects/scaffold-drafts/${SLUG}/concept-brief.md ~/projects/${SLUG}/docs/ 2>/dev/null || true
   ```
3. **Pointer in CLAUDE.md.** Under the "Design & plans" section, note where the rationale
   now lives, e.g. append:
   `> Ideation: see \`docs/concept-brief.md\` and the ADRs in \`docs/decisions/\`.`
4. **Commit + push** the ported docs with the project's git:
   ```bash
   cd ~/projects/${SLUG}
   git add docs/ CLAUDE.md
   git commit -m "docs: port ideation (brief + ADRs) from scaffold-drafts"
   git push
   ```
5. **Only after 4 succeeds**, remove the draft from the drafts repo and push:
   ```bash
   cd ~/projects/scaffold-drafts
   git rm -r ${SLUG}/
   git commit -m "scaffold(${SLUG}): ported to repo docs/, project created"
   git push
   ```

If anything in 1–4 fails, **skip the delete** — leave the draft in `scaffold-drafts`
untouched and tell Daniel the port is pending so he can re-run it later. A draft folder
remaining means "not yet ported," which is the safe state.

---

## Step 6.6 — (Conditional) dev-backend override

**Most projects need nothing here.** Only set this up when the project is itself a
dev/prod-split service that gets *developed against its own dev backend*. The pattern is
**coordinate-as-config**: express the backend URL in code as an env var with a
**prod-safe default**, then override it to the dev coordinate per-repo via `direnv`:

1. Write a tracked `.envrc` at the repo root exporting the dev coordinate — the
   project's own `*_URL` pointing at its dev instance, e.g.
   `export ${SLUG}_API_URL=http://192.168.86.160:<dev-port>`.
2. Ensure direnv is set up on vm-160 (one-time, already done as of 2026-05-30):
   static binary in `~/.local/bin`, `eval "$(direnv hook bash)"` in `~/.bashrc`.
3. `ssh … daniel@192.168.86.160 "cd ~/projects/${SLUG} && ~/.local/bin/direnv allow ."`

The env var is read at session launch, so `claude` must be started from a shell that has
entered the repo (direnv prints `loading …/.envrc`). Prod is the default everyone gets;
dev is the deliberate per-repo override. See the `claude-resources` `project-lifecycle`
skill for the full rationale.

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
PAYLOAD=$(printf '%s' "$REG_PW" | python3 -c 'import json,sys; print(json.dumps({"data": sys.stdin.read()}))')
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
```

---

## Troubleshooting

| Issue | Resolution |
|---|---|
| Forgejo API 401 | Token expired — re-read from `~/projects/claude-resources/.env` (or re-stage if the file is missing) |
| Forgejo API 409 | Repo already exists — use different slug or delete existing |
| git push fails (auth) | Check the SSH deploy key on vm-160 (`ssh-add -l`); confirm remote is `ssh://git@forgejo.towneygorm.cc:222/...` |
| `.env` missing | Run the one-time secret setup from the Prerequisites section |
