---
name: project-lifecycle
description: "How a project and its claude-resources plugin are developed, targeted at dev vs prod, versioned, and shipped — and the conventions that keep a feature spanning both repos from breaking. Use when starting feature work, before creating a branch, before merging or releasing, or whenever your change will touch a plugin or its skills/commands."
---

# Skill: project-lifecycle

This project's Claude tooling (the plugin: MCP connection + skills + commands)
lives in the **claude-resources** repo, separate from the app repo. The two are
developed in lockstep-by-convention. Read this before branching if your work
will touch the plugin.

## The model

"Dev vs prod" is **two deployments of one artifact**; the difference lives in
**config, not in a branch**. There is no standing `dev` branch. Branches are for
isolating work-in-progress (`feat/…`, `fix/…` off `main`, squash-merged when
ready); `main` is always the released state, releases are tags.

## Backend targeting (which dev-hub you hit)

The plugin's `.mcp.json` reads `${DEV_HUB_MCP_URL:-<prod LAN IP>}` at session
start. With nothing set you get **prod** — the safe default for every consumer.
Only the **app repo itself** overrides it (to the dev backend) so that working
*on* the app talks to its dev stack. Never hardcode a backend URL anywhere.

## A feature that touches both the app and the plugin

Use **matching topic-branch names** in both repos (e.g. `feat/x` in the app and
in claude-resources) and cross-reference the two PRs. Five rules keep it safe:

1. **Merge order: backend capability first, plugin second.** Two merges are
   never atomic. A plugin expecting a backend tool/behaviour that prod lacks
   breaks consumers on `plugin update`. Ship + deploy the backend to prod first;
   merge the plugin after. The reverse lag is harmless (plugins are pulled
   deliberately).
2. **"Merge to main" ≠ "published."** Merging is integration. Going live is a
   separate step per repo: the app needs build → tag → prod-deploy; the plugin
   needs consumers to run `claude plugin update`.
3. **Keep the plugin backend-version-agnostic.** Don't assume a backend version:
   discover tools at runtime (`tools/list`, no bundled snapshot) and rely on the
   backend never breaking `/api/v1`.
4. **Matching branch names + cross-linked PRs**, so neither half is forgotten.
5. **One session, both trees.** Have both repos checked out side-by-side and the
   session granted access to the claude-resources checkout (`--add-dir`), so you
   edit both without bouncing between sessions.

## Development & test loop

Register claude-resources as a **local-path** marketplace (`claude plugin
marketplace add ~/projects/claude-resources --scope local`) to test your working
tree privately (`--scope local` keeps it private to the current project; consumers use the permanent `--scope user` git-URL install) — skill edits live, `/reload-plugins` for the rest. Consumers,
pinned to the git-URL install of `main`, see nothing until you merge and they
update.

## Rollback note

App rollback is instant (redeploy the previous pinned tag). Plugin rollback is a
revert-commit + consumers re-updating — low risk, since plugin changes are mostly
additive skill text. Shared cross-project skill changes get their own PR,
independent of any single feature.

## Env / config authoring

A project's configuration is split dev vs prod, **externalized — never baked into the image**:

- **Dev**: a gitignored `.env` at the repo root (copied from `.env.example`), consumed by the dev compose stack (`env_file: .env`, bind-mounted source). Local DB creds, ports, dev backend URLs.
- **Prod**: `/srv/infra/stacks/<slug>/.env` on vm-160, holding `APP_VERSION` (the pinned image tag) + prod values, updated by `prod-deploy`. Never in the repo.

**Coordinate-as-config.** If the project talks to a backend with a dev/prod split (its own, or dev-hub), express the URL as an env var with a prod-safe default — e.g. `${DEV_HUB_MCP_URL:-http://192.168.86.160:8011/mcp}`, or the project's own `${FOO_API_URL:-<prod>}`. Prod is the default everyone gets; **dev is a deliberate per-repo override**: a tracked `.envrc` exporting the dev URL + `direnv` (the var is read at session launch, so start `claude` from inside the repo). dev-hub is the worked example — its `.envrc` points `DEV_HUB_MCP_URL` at the dev stack so working *on* dev-hub hits dev, while every consumer defaults to prod.

**Secrets discipline.** Secrets live in `.env` (gitignored, `chmod 600`), are sourced never printed, and never cross the agent transcript — assign to a shell var in one Bash call and use it. Never commit a `.env`; never pass a secret on argv.
