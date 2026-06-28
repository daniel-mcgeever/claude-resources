# project-scaffold

Scaffolds a new development project on vm-160: Forgejo repo, `CLAUDE.md` + `.claude/`
from the bundled `catalogue/`, git init/push, and an optional prod compose stack.
Runs natively on vm-160.

## Install (vm-160, user scope)

```bash
claude plugin marketplace add https://forgejo.towneygorm.cc/daniel/claude-resources.git --scope user
claude plugin install project-scaffold@claude-resources --scope user
```

Restart Claude, then invoke `/new-project` (or just "create a new project") from
any session on vm-160.

## Secrets — one-time `.env` setup

The scaffolder reads `~/projects/claude-resources/.env` (mode 600, gitignored) for:

- `FORGEJO_API_TOKEN` — Forgejo API token with scopes `write:repository` **and** `write:user`
- `REGISTRY_PASSWORD` — registry machine password (used to set the per-repo CI secret)

Stage it from the vm-153 vault (run **on vm-153**), piping the values into the file
over SSH stdin so they never print to a transcript:

```bash
export BW_SESSION=$(cat /dev/shm/bw-session-$USER)
TOKEN=$(bw get password "homelab/forgejo-api-token")
REGPW=$(bw get item "homelab/registry" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); print([f["value"] for f in d.get("fields",[]) if f["name"]=="machine_password"][0])')
unset BW_SESSION
printf '%s\n' "FORGEJO_API_USER=homelab-agent" "FORGEJO_API_TOKEN=${TOKEN}" "REGISTRY_PASSWORD=${REGPW}" \
  | ssh -i ~/.ssh/id_ed25519_homelab_agent_vm-160 daniel@192.168.86.160 \
    "umask 077; mkdir -p ~/projects/claude-resources; cat > ~/projects/claude-resources/.env; chmod 600 ~/projects/claude-resources/.env"
unset TOKEN REGPW
```

Never commit `.env`; never print the values.

## Sharing skills across projects

`Skill(promote-skill)` copies a skill you authored in any project's `.claude/skills/`
into the central `skills/` library at the claude-resources repo root (indexed in
`skills/INDEX.md`), so other projects can find and reuse it. Logic:
`skills/promote-skill/SKILL.md`.

## Source

Lives in the claude-resources repo at `plugins/project-scaffold/`. Project templates
are in `catalogue/`; the scaffolder logic is `skills/new-project/SKILL.md`. The central
shared-skill library is at the repo root in `skills/`.
