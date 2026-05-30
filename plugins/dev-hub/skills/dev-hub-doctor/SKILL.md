---
name: dev-hub-doctor
description: "Diagnose dev-hub MCP connection problems with a four-check walk: env var, /health endpoint, MCP tools/list handshake, list_projects callable from this session. Reports each check with the next remediation step. Use when /dev-hub-doctor is invoked, when the user asks 'why isn't dev-hub working', or when you just hit a tool-not-found error trying to call a dev-hub tool."
---

# Skill: dev-hub-doctor

Run all four checks. Report each ✓ or ✗ with the fix inline.

## Check 1 — env var present

```bash
echo "DEV_HUB_MCP_URL=${DEV_HUB_MCP_URL:-<unset; defaults to http://192.168.86.160:8011/mcp (prod); DEV_HUB_MCP_URL overrides it>}"
```

Unset is fine for vm-160 (default works). Note the value either way.

## Check 2 — HTTP health endpoint reachable

`/health` lives on the backend (port 8000), not the MCP (port 8001).
Target the backend directly:

```bash
curl -sS "http://localhost:8000/health"
```

Expected: `{"status":"ok"}`.

If it errors:
- **connection refused** → dev-hub stack isn't running. On vm-160: `docker compose up -d`.
- **404** → dev-hub is up but the backend endpoint path changed. Check `mcp/README.md` for the current `/health` path.

## Check 3 — MCP tools/list handshake

```bash
curl -sS -X POST "${DEV_HUB_MCP_URL:-http://192.168.86.160:8011/mcp}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | head -c 4000
```

Expected: JSON or SSE response listing the dev-hub tools.

If it errors:
- **connection refused** → mcp container isn't serving (different from Check 2 failure if the backend is up but mcp isn't). On vm-160: `docker compose up -d mcp`.
- **HTML / 502** → reverse proxy in the way (shouldn't be on LAN-only, but check).

## Check 4 — Tool actually callable from this session

Attempt `list_projects` via the MCP tool surface. If you get
`tool not found`, the plugin isn't loaded in this Claude session.

Remediation:
- Verify the plugin is installed from the marketplace — `claude plugin list`
  (expect `dev-hub@claude-resources … enabled`). If missing, re-run:
  ```bash
  claude plugin marketplace add https://forgejo.towneygorm.cc/daniel/claude-resources.git --scope user
  claude plugin install dev-hub@claude-resources --scope user
  ```
- Restart the Claude session OR run `claude plugin reload` if it's
  installed but not yet loaded.

## Reporting

After all four:

- ✓ ✓ ✓ ✓ → "Everything looks good; dev-hub is reachable and the tools
  are loaded."
- ✗ on Check 2 or 3 → server-side. Show the curl output.
- ✗ on Check 4 only → plugin-loading. Run `claude plugin reload` or
  restart the session.
- ✗ on Check 1 → env var typo or shell didn't export. Re-source shell.

Do NOT silently retry — the user needs to know what failed so they can
act on the right layer.
