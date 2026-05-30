---
name: dev-hub-brainstorm
description: "Active capture loop for user-voiced ideas during brainstorming. Reformulate the input as a single sharp thought sentence, confirm with the user, persist via create_thought with kind + theme_tags, suggest links to related open thoughts, and flag ripe clusters for promotion. Use when the user says 'let's brainstorm', 'let me think out loud', or you detect an unstructured idea-dump session. Triggered by /dev-hub-brainstorm."
---

# Skill: dev-hub-brainstorm

Capture loop. Each invocation handles ONE thought (or one cluster flag).
Re-trigger per thought; don't try to batch silently.

## Prerequisites (check before starting)

1. dev-hub MCP is connected — attempt `list_thoughts` for the current project.
   If it errors, stop and tell the user: "dev-hub MCP not reachable; run /dev-hub-doctor."
2. The current project is registered. Derive the slug from
   `git remote get-url origin` (basename, strip `.git`). If `list_projects`
   doesn't return this slug, stop and tell the user: "this project isn't
   registered in dev-hub yet; run /dev-hub-init."

## The five steps

### 1. Recognise the input

The user said something idea-shaped. Don't drop it on the floor.
Reformulate into a single sharp sentence (one clause, present tense,
no hedging). Confirm with the user:

> "I'd capture this as: '<sentence>'. OK?"

If they push back, iterate until they're happy or they say skip.

### 2. Persist with kind + tags

Pick the `kind` from these:

- `question` — open-ended (e.g. "should we cache the response?")
- `idea` — proposal (e.g. "add a Redis cache in front of get_plan")
- `concern` — risk (e.g. "cache invalidation when plan body rewrites")
- `decision` — settled (e.g. "we'll use Redis, not in-memory LRU")
- `note` — observation, no action implied

Derive `theme_tags` from the conversational context: existing concepts
already in flight, project areas mentioned. Up to 3 tags is a good
default — more than that and tags become noise.

Set `author=user` if you're transcribing what the user said.
Set `author=ai` if it's your idea you're persisting at the user's
prompt (e.g., "yeah good idea, capture that").

Call:

```
create_thought(
  project_slug=<derived>,
  text=<sentence>,
  author=<user|ai>,
  kind=<picked>,
  theme_tags=[<derived>],
)
```

### 3. Suggest links

Run `list_thoughts(project_slug=<slug>, status='open')`. Score each open
thought by **tag overlap** (count of shared `theme_tags`). Take the top
3 by score. If no thought has ≥1 shared tag, fall back to
**case-insensitive substring match** against thought text — keep top 3.

Surface to the user:

> "These open thoughts share tags / text:
>   1. <text>  (tags: ...)
>   2. ...
>   Link the new thought to any? If yes, which and what kind
>   (relates_to | builds_on | contradicts | supersedes)?"

For each accepted link, call:

```
link_thoughts(
  project_slug=<slug>,
  from_thought_id=<new>,
  to_thought_id=<picked>,
  kind=<picked>,
)
```

If the user says "no links", move on.

### 4. Watch for ripe clusters

After every 5th capture in the session, call:

```
list_thoughts(project_slug=<slug>, status='open')
```

Bucket open thoughts by theme tag. A cluster is **ripe** if either:

- ≥3 thoughts share one theme tag AND at least one is `kind=decision`, OR
- ≥5 thoughts share one theme tag regardless of kind.

If you find a ripe cluster, surface it:

> "Cluster looks ripe under theme '<tag>': N thoughts including a
> decision. Want to promote? (/dev-hub-promote)"

Don't auto-promote — always ask.

### 5. Exit cleanly

Report what landed:

> "Captured: <preview of text> (<thought_id>). N links added."

Done. The user can re-trigger you for the next thought.

## Do not

- Capture every conversational utterance — only idea-shaped ones the
  user has actually voiced.
- Invent thoughts the user didn't say (no "I think you also meant…").
- Add more than 3 theme_tags by default; tag bloat kills cluster detection.
- Auto-link to thoughts you discovered yourself without confirming with
  the user.
