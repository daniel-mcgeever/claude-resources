# claude-resources

Central Claude Code marketplace for the homelab. Holds the marketplace index
(`.claude-plugin/marketplace.json`), the per-project plugins under `plugins/`,
and (later) shared cross-project skills under `shared/`.

## Install (one-time, per VM, user scope)

```bash
claude plugin marketplace add https://forgejo.towneygorm.cc/daniel/claude-resources.git --scope user
claude plugin install dev-hub@claude-resources --scope user
```

Restart Claude Code (or start a new session) to load the plugin.

## Development loop

Edit a plugin in place, then test it privately without affecting consumers:

```bash
# one-time, on the dev machine, scoped to this repo
claude plugin marketplace add ~/projects/claude-resources --scope local
```

Skill edits are picked up live; for command/hook/MCP/plugin.json changes run
`/reload-plugins`. Consumers stay pinned to the git-URL install and see nothing
until you merge to `main` and they run `claude plugin update`.

See `docs/superpowers/specs/2026-05-30-claude-resources-lifecycle-design.md`
in the dev-hub repo for the full lifecycle.
