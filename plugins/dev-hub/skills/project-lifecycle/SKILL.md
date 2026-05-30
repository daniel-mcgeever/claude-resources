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
