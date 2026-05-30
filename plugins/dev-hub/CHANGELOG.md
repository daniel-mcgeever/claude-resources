# Changelog

All notable changes to the dev-hub Claude Code plugin.

## [1.1.1] - 2026-05-30

### Fixed
- `dev-hub-doctor` skill referenced the old dev default (`localhost:8001`), the
  retired symlink install path, and a hardcoded tool count — updated to the prod
  LAN-IP default, the marketplace install check, and a count-agnostic description.

## [1.1.0] - 2026-05-30

### Changed
- Plugin now lives in the `claude-resources` marketplace hub (was bundled in the
  dev-hub repo).
- MCP coordinate defaults to the **prod** dev-hub over the LAN IP
  (`192.168.86.160:8011`), overridable via `DEV_HUB_MCP_URL`.
- `using-dev-hub` tool reference is now discovered at runtime; the static
  `_tool-reference.md` snapshot was removed.

### Added
- `project-lifecycle` skill — the development/dev-vs-prod/release lifecycle and
  the cross-repo feature conventions.
- SessionStart hook surfacing an advisory pointer to `project-lifecycle`.

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
