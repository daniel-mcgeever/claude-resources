# {{SLUG}}

{{DESCRIPTION}}

## Quick start

```bash
cp .env.example .env
docker compose up
```

Service available at the port shown in `compose.yaml` → `ports:`.

## Development

This project was scaffolded with the homelab `new-project` skill.
See `CLAUDE.md` for Claude Code context, available agents, skills, and conventions.

Launch Claude Code:
```bash
ssh daniel@192.168.86.160
cd ~/projects/{{SLUG}}
claude
```

## Repository

`https://forgejo.towneygorm.cc/daniel/{{SLUG}}`

## CI

Forgejo Actions runs tests on every push and builds + pushes the image to
`registry.towneygorm.cc/{{SLUG}}/app:<tag>` on merges to `main`.
View runs: `https://forgejo.towneygorm.cc/daniel/{{SLUG}}/actions`
