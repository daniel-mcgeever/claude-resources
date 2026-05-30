---
name: dev-hub-promote
description: "Walk a cluster of ripe brainstorm thoughts through atomic promotion to a plan, list of todos, or milestone. Use when the user says 'promote these', 'turn this into a plan', agent recognises a ripe cluster (from /dev-hub-brainstorm), or /dev-hub-promote is invoked."
---

# Skill: dev-hub-promote

Atomic, irreversible. Confirm with the user before every write.

## Prerequisites

1. dev-hub MCP connected — attempt `list_thoughts`. If fails, stop and
   point at `/dev-hub-doctor`.
2. The project is registered. If not, point at `/dev-hub-init`.

## The four steps

### 1. Get the thought ids

Either:
- Passed in (from `/dev-hub-brainstorm`'s ripe-cluster handoff), or
- Entered by user as a list, or
- You re-run `list_thoughts(project_slug=<slug>, status='open')` and ask
  the user which to include.

Reject any thought already `status='promoted'` — the service will refuse
it anyway; better to surface the conflict before the call.

Reject thoughts from a different project (the service refuses cross-
project promotion).

### 2. Pick target kind

Ask the user: plan / todos / milestone.

Default suggestion based on cluster shape:

- Cluster with one `kind=decision` + several `kind=idea` → suggest **plan**.
- Cluster of concrete actionables (mostly `kind=idea` framed as actions) → suggest **todos**.
- Cluster of timeline/scope-shaped thoughts → suggest **milestone**.

Don't auto-pick — always confirm.

### 3. Draft the target content

**If plan:**
- Compose the body from the thought texts: one bullet per thought,
  grouped by `kind`. Add a `## Source thoughts` footer that lists
  thought ids so the lineage is visible on disk.
- Ask user for title.
- Suggest slug via lowercasing the title and replacing non-`[a-z0-9-]`
  with `-` (or let the server derive it via `_slugify`).
- Confirm body + title + slug before writing.

**If todos:**
- Parse each thought into one todo line. Group decision-shaped ones
  ("we'll use Redis") into context for adjacent action-shaped ones.
- Let user reorder / edit / merge / drop in conversation before submit.

**If milestone:**
- Title from user.
- Description: concatenation of thought texts.
- target_date: optional, ask user; ISO date.

### 4. Confirm + write

Show the drafted target ONCE before submitting:

> "About to create plan 'Auth redesign' (slug `auth-redesign`) with body:
> <preview>. This promotes thoughts <id1>, <id2>, <id3>. OK?"

On confirm, call the matching tool:

```
promote_thoughts_to_plan(project_slug, thought_ids, title, body_md, slug=None)
# or
promote_thoughts_to_todos(project_slug, thought_ids, todos=[{text, context?}, ...])
# or
promote_thoughts_to_milestone(project_slug, thought_ids, title, description=None, target_date=None)
```

Report back:

> "Created <plan|todos|milestone> <id> from N thoughts. Now visible at
> http://192.168.86.160:5173/projects/<slug>."

## Do not

- Promote a single thought to a plan unless explicitly requested. One
  thought usually means it's not yet ripe.
- Edit thought text mid-promotion. The thoughts are the input; if the
  user wants different wording, exit, run `/dev-hub-brainstorm` to
  capture revised thoughts, then re-promote.
- Promote thoughts from multiple projects in one call (the service
  refuses it).
