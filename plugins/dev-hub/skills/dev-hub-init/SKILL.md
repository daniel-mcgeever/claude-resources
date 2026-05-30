---
name: dev-hub-init
description: "Confirm the current project is registered in dev-hub; trigger discovery refresh if not; optionally seed starter todos. Idempotent — safe to re-run. Use when /dev-hub-init is invoked, or when a dev-hub MCP call returned 'project not found' for the current repo."
---

# Skill: dev-hub-init

Idempotent. Safe to re-run.

## The five steps

### 1. Check registration

Derive the slug from the current git remote:

```bash
git remote get-url origin | sed 's|.*/||;s|\.git$||'
```

Call `list_projects()` via MCP and look for that slug.

- **Found** → print "Project already registered as `<id>`. Done." Skip to step 4.
- **Not found** → continue to step 2.

### 2. Trigger refresh

Call dev-hub's project-discovery endpoint over localhost:

```bash
curl -sS -X POST http://localhost:8000/api/v1/projects/refresh
```

Then poll `list_projects` every 2 seconds, up to 5 attempts, looking for
the slug to appear.

### 3. Handle non-discovery

If after 10 seconds the project still doesn't appear:

> "dev-hub didn't pick up project `<slug>`. Most likely the project's
> path isn't under the REPOS mount the dev-hub container watches. Check
> `docker compose logs dev-hub-dev-hub-1 | grep discovery` on vm-160."

Exit non-zero. Do NOT silently proceed.

### 4. Offer starter todos

Ask the user:

> "Project registered. Drop in starter todos for a <tech-stack> project?
> Suggested:
>   - Set up CI workflow
>   - Write initial README content
>   - Configure compose dev stack
> (yes / no / edit list)"

If yes, `create_todo` for each accepted item.

If the user says no, skip.

### 5. Report

Print:

> "✅ Project `<slug>` registered as id `<id>`. Seeded N todos."

Done.

## Do not

- Auto-seed starter todos without explicit user confirmation.
- Loop forever on the refresh poll — fail loudly after the timeout so
  the user can investigate the discovery mount.
- Call this from another skill silently; surface the invocation to the
  user.
