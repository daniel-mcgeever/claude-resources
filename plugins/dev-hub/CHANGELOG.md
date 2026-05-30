# Changelog

All notable changes to the dev-hub Claude Code plugin.

## [1.0.1] - 2026-05-29

Prod-ready `mcp` + `frontend` images; no plugin behaviour change. The mcp
image now bakes in `backend/src/db` + `backend/src/services` (built from the
repo root) and the frontend ships as a multi-stage vite→nginx build serving
the SPA with a same-origin `/api` reverse-proxy. Plugin skills/commands/MCP
config are unchanged from 1.0.0.

## [1.0.0] - 2026-05-28

First stable release. Cut alongside the repo-wide `v1.0.0` tag (backend,
mcp, frontend, and plugin all move to 1.0.0 together). No functional
change from 0.1.0 — promotes the consumer-tested plugin to a stable
version line.

## [0.1.0] - 2026-05-28

First consumer-tested release.

- MCP server config (`.mcp.json`) — HTTP transport, `${DEV_HUB_MCP_URL}` env var
- Manifest (`.claude-plugin/plugin.json`)
- 7 skills: using-dev-hub, dev-hub-workflow, dev-hub-brainstorm,
  dev-hub-promote, close-out-plan, dev-hub-init, dev-hub-doctor
- 6 slash commands paired with the workflow skills
- Generated tool reference (`plugin/skills/using-dev-hub/_tool-reference.md`)
- Full README with install / verify / use / troubleshoot
- One-time install: symlink `/home/daniel/projects/dev-hub/plugin` →
  `~/.claude/plugins/dev-hub`
- vm-153 orchestrator integration (Step 0.5 verify, Step 6.5 refresh,
  registry `dev_hub_id` field, CLAUDE.md template `## dev-hub` section)

## [0.0.1] - 2026-05-28
- Initial scaffold: manifest, MCP server config, README/CHANGELOG stubs.
