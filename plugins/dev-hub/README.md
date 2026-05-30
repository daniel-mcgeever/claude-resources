# dev-hub Claude Code plugin

Connects a Claude Code session in any consumer repo on vm-160 to the
dev-hub dashboard. Bundles the dev-hub MCP tool surface + eight workflow
skills + six slash commands into one install.

## What you get

Once installed:

- **MCP server `dev-hub`** auto-registered (HTTP transport, no auth, LAN-only).
  Default endpoint: `http://192.168.86.160:8011/mcp` (prod stack).
- **Skills auto-loaded:** `using-dev-hub`, `dev-hub-workflow`,
  `dev-hub-brainstorm`, `dev-hub-promote`, `close-out-plan`,
  `dev-hub-init`, `dev-hub-doctor`, `project-lifecycle`.
- **Slash commands:** `/dev-hub-workflow`, `/dev-hub-brainstorm`,
  `/dev-hub-promote`, `/close-out-plan`, `/dev-hub-init`,
  `/dev-hub-doctor`.
- **Tool reference** discovered at runtime via the MCP `tools/list` handshake
  (no bundled static copy).

## Install (one-time, vm-160)

Claude Code only loads plugins that come from a **registered marketplace**
and are enabled in `enabledPlugins` — a loose directory or symlink under
`~/.claude/plugins/` is **not** discovered. Register the `claude-resources`
marketplace (git URL) and install at **user scope** so every consumer
project picks it up:

```bash
claude plugin marketplace add https://forgejo.towneygorm.cc/daniel/claude-resources.git --scope user
claude plugin install dev-hub@claude-resources --scope user
```

Restart Claude Code (or start a new session) for the skills, commands, and
MCP server to load — plugin changes apply on next session start, not live.
The MCP server and all skills are then available in **every** project on
vm-160 with no per-project setup.

## Configure

`DEV_HUB_MCP_URL` overrides the default `http://192.168.86.160:8011/mcp`:

```bash
export DEV_HUB_MCP_URL=http://192.168.86.160:8001/mcp
```

The dev-hub app repo sets this to the dev stack (`8001`). In all other
consumer repos the default prod URL (`8011`) is used. Restart sessions
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

The `project-lifecycle` skill covers the development/dev-vs-prod/release
lifecycle and cross-repo feature conventions; it is advisory and surfaced
by a SessionStart pointer.

## Update

The install **copies** the plugin into a versioned cache — it is *not*
a live view of the working tree, so a bare `git pull` does **not** update
it. To ship plugin changes:

1. Bump `version` in `.claude-plugin/plugin.json` inside the plugin directory.
2. Push the changes to the `claude-resources` Forgejo repo.
3. Refresh the marketplace catalogue and update the plugin:
   ```bash
   claude plugin marketplace update claude-resources
   claude plugin update dev-hub
   ```
4. Restart Claude Code to apply.

## Uninstall

```bash
claude plugin uninstall dev-hub@claude-resources
# optional: also drop the marketplace registration
claude plugin marketplace remove claude-resources
```

## Versioning

The plugin version (`.claude-plugin/plugin.json`) is pinned into the cache
at install time. To pin an older release, check out the desired tag in the
`claude-resources` repo, then run the **Update** steps above.

## Troubleshooting

- **"Tool not found" calling `list_projects`** → plugin not loaded. Run
  `claude plugin reload` or restart the session.
- **`/dev-hub-doctor` Check 2 fails** → dev-hub stack not running. On
  vm-160: `docker compose up -d` in the dev-hub repo.
- **`/dev-hub-doctor` Check 4 fails** → plugin loaded but tool surface
  missing. Verify the plugin is installed and enabled:
  `claude plugin list` (expect `dev-hub@claude-resources … enabled`).
- **Skills/commands don't appear at all** → the plugin isn't registered.
  A loose symlink under `~/.claude/plugins/` is ignored; run the
  marketplace install in the **Install** section, then restart the session.

## Source

Lives in the `claude-resources` repo at `plugins/dev-hub/`. Bugs and PRs
through the `claude-resources` Forgejo repo at
`https://forgejo.towneygorm.cc/daniel/claude-resources`.
