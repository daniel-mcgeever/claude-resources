# dev-hub Claude Code plugin

Connects a Claude Code session in any consumer repo on vm-160 to the
dev-hub dashboard. Bundles 32 MCP tools + seven workflow skills + six
slash commands into one install.

## What you get

Once installed:

- **MCP server `dev-hub`** auto-registered (HTTP transport, no auth, LAN-only).
- **Skills auto-loaded:** `using-dev-hub`, `dev-hub-workflow`,
  `dev-hub-brainstorm`, `dev-hub-promote`, `close-out-plan`,
  `dev-hub-init`, `dev-hub-doctor`.
- **Slash commands:** `/dev-hub-workflow`, `/dev-hub-brainstorm`,
  `/dev-hub-promote`, `/close-out-plan`, `/dev-hub-init`,
  `/dev-hub-doctor`.
- **Generated tool reference** at
  `plugin/skills/using-dev-hub/_tool-reference.md`.

## Install (one-time, vm-160)

Claude Code only loads plugins that come from a **registered marketplace**
and are enabled in `enabledPlugins` — a loose directory or symlink under
`~/.claude/plugins/` is **not** discovered. This repo ships a local
marketplace manifest at `.claude-plugin/marketplace.json` (repo root) that
exposes the `plugin/` directory as the `dev-hub` plugin. Register it and
install at **user scope** so every consumer project picks it up:

```bash
claude plugin marketplace add /home/daniel/projects/dev-hub --scope user
claude plugin install dev-hub@dev-hub-local --scope user
```

(Equivalently, inside a Claude session: `/plugin marketplace add
/home/daniel/projects/dev-hub` then `/plugin install dev-hub@dev-hub-local`.)

Restart Claude Code (or start a new session) for the skills, commands, and
MCP server to load — plugin changes apply on next session start, not live.
The MCP server and all skills are then available in **every** project on
vm-160 with no per-project setup.

## Configure

`DEV_HUB_MCP_URL` overrides the default `http://localhost:8001/mcp`:

```bash
export DEV_HUB_MCP_URL=http://192.168.86.160:8001/mcp
```

Not needed on vm-160 (localhost is the dev-hub host). Restart sessions
after changing.

## Verify

In a Claude session in any consumer project on vm-160:

```
/dev-hub-doctor
```

Expected: four ✓ (env var, /health, tools/list, list_projects).

## Use

- `/dev-hub-workflow` — start of work; reads queued todos, agrees scope, writes a plan back.
- `/dev-hub-brainstorm` — capture user-voiced ideas as atomic thoughts.
- `/dev-hub-promote` — promote a cluster of ripe thoughts to plan/todos/milestone.
- `/close-out-plan` — end of work; marks plan accepted, retires linked todos.
- `/dev-hub-init` — register a project (or recover partial state) + optional starter todos.
- `/dev-hub-doctor` — diagnose connection issues.

The orientation skill (`using-dev-hub`) loads automatically when you
mention dev-hub in conversation; it explains the rest of the surface.

## Update

The install **copies** the plugin into a versioned cache
(`~/.claude/plugins/cache/dev-hub-local/dev-hub/<version>/`) — it is *not*
a live view of the working tree, so a bare `git pull` does **not** update
it. To ship plugin changes:

1. Bump `version` in `plugin/.claude-plugin/plugin.json` (this happens in
   lockstep with the repo's semver tag — see the repo's git-flow rule).
2. Commit / `git pull` so the new version is on disk.
3. Refresh the marketplace catalogue and update the plugin:
   ```bash
   claude plugin marketplace update dev-hub-local
   claude plugin update dev-hub
   ```
4. Restart Claude Code to apply.

## Uninstall

```bash
claude plugin uninstall dev-hub@dev-hub-local
# optional: also drop the marketplace registration
claude plugin marketplace remove dev-hub-local
```

## Versioning

The plugin version (`.claude-plugin/plugin.json`) ships in lockstep with
the dev-hub repo's semver tag, and the marketplace install pins that
version into the cache. To pin an older release, `git checkout <tag>` in
the dev-hub repo, then run the **Update** steps above.

## Troubleshooting

- **"Tool not found" calling `list_projects`** → plugin not loaded. Run
  `claude plugin reload` or restart the session.
- **`/dev-hub-doctor` Check 2 fails** → dev-hub stack not running. On
  vm-160: `docker compose up -d`.
- **`/dev-hub-doctor` Check 4 fails** → plugin loaded but tool surface
  missing. Verify the plugin is installed and enabled:
  `claude plugin list` (expect `dev-hub@dev-hub-local … enabled`).
- **Skills/commands don't appear at all** → the plugin isn't registered.
  A loose symlink under `~/.claude/plugins/` is ignored; run the
  marketplace install in the **Install** section, then restart the session.

## Source

Lives in the dev-hub monorepo at `plugin/`. Bugs and PRs through the
same Forgejo repo as the rest of the project.
