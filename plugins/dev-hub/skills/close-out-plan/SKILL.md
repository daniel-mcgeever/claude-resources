---
name: close-out-plan
description: "Walk a shipped plan to a clean close: read the plan + its linked todos, check each off as kept/moved/dropped with the user, create follow-up todos for anything still outstanding, then call complete_plan (or archive_plan if superseded) via the dev-hub MCP. Use when a plan's work has merged to main and you want to retire it cleanly without leaving stale plans and orphan todos behind. Triggered by /close-out-plan, 'close out plan X', 'wrap up plan X', or 'archive plan X with follow-ups'."
catalogue_candidate: true
---

# Skill: close-out-plan

Closes the human-curated half of the agent loop. `dev-hub-workflow`
opens a plan; this skill is what shuts it cleanly when the work has
shipped. Runs inline in the user's session — no sub-agent spawn, no
Task dispatch. You are the agent executing this skill.

## Prerequisites (verify silently before starting)

1. The dev-hub MCP server is connected. Check by attempting
   `list_projects`. If the call fails with "tool not found" or a
   connection error, stop and tell the user: "The dev-hub MCP isn't
   connected to this session. Open the project's Plans tab in the
   dashboard, follow the 'Connect Claude' snippet, then restart."
2. The current working directory is a git repo. Run
   `git rev-parse --show-toplevel`. If it fails, stop and tell the
   user the skill needs a git repo to match the project against
   dev-hub.

## When to invoke

This skill assumes the plan's work has already shipped — merged to
main, tagged, deployed. It is **not** for plans that are still in
progress or that drifted off-scope without finishing. For those:

- Still in progress → keep the plan in `draft`; do nothing.
- Drifted off-scope and not coming back → use this skill but pick
  `archive_plan`, not `complete_plan`, and create follow-ups for any
  todos the work didn't address.

## The loop

Execute steps 1–6 in order. Do not skip — each step's output feeds
the next.

### Step 1. Detect the project + plan

a. If the user named a plan explicitly (`/close-out-plan m4-observability`
   or "close out the m4 plan"), capture the slug or partial slug.
b. Read the consumer repo's primary remote: `git remote get-url origin`.
   Normalise (.git suffix stripped, scp → https) and call
   `list_projects`, matching by `forgejo_url`. One match → proceed
   with that project's slug. Otherwise ask the user to pick.
c. Call `list_plans(project_slug=<slug>, status="draft")` and
   `list_plans(project_slug=<slug>, status="accepted")`. Filter to
   the plan slug captured in (a). If multiple draft plans match
   ambiguously, present the candidates and ask the user to pick.
   If no match, ask the user for the plan slug.

State the target back in one sentence:
"Closing out plan '<plan_slug>' (status: <current_status>) on project
'<project_slug>'."

### Step 2. Pull the plan body + linked todos

Call `get_plan(plan_id=<id>)`. The response carries the plan body
and the linked todo ids.

Call `list_todos(project_slug=<slug>)` and intersect with the linked
todo ids from the plan, OR rely on the plan's `todo_ids` field
directly if the MCP read tool surfaces it.

Read the plan body. If it has a `## Out of scope` section, note it
— items there are NOT follow-up candidates; they were deliberate cuts.

### Step 3. Walk every linked todo with the user

For each linked todo, present:

```
☐ <todo.text>            [status: <current_status>]
```

Ask the user one of three things per todo:

- **Keep / done** — the work shipped; mark the todo complete via
  `update_todo(todo_id=<id>, status="done")`.
- **Move** — the work didn't ship in this plan but is still wanted.
  Ask for a one-line follow-up text (default: the original text
  with a "(follow-up from <plan_slug>)" suffix). Create via
  `create_todo(project_slug=<slug>, text=<follow_up_text>)`. Then
  decide: pin to a milestone (ask which) or leave unpinned for the
  Inbox to surface.
- **Drop** — the work is no longer wanted. Mark via
  `update_todo(todo_id=<id>, status="dropped")`.

Walk all linked todos. Do NOT bulk-accept — each todo gets a
deliberate yes/no from the user. If the user says "all done" or
"all kept" or "all dropped" at any point, you can short-circuit
the remaining todos with that uniform action.

### Step 4. Walk the plan body for outstanding items

Re-read the plan body. Look for:

1. Any `## Approach` step that mentions a todo or fix or feature
   that does NOT appear in the linked todos list above.
2. Anything in a "Follow-up" / "Future" / "Later" sub-section that
   isn't already a todo.

For each, ask the user: "This was in the plan but doesn't have a
todo: <one-line summary>. Create a follow-up todo, or drop?" Create
via `create_todo` if requested.

### Step 5. Decide the plan's terminal status

Ask:

- **complete** — the plan's work shipped. Call
  `complete_plan(plan_id=<id>)`. Plan transitions to `accepted`.
- **archive** — the plan is superseded or was drifted off-scope and
  isn't coming back. Call `archive_plan(plan_id=<id>)`. Plan
  transitions to `archived` and the dashboard hides it by default.

Both tools are idempotent — safe to call.

### Step 6. Optional: write a short ship-summary

If the user wants, append a `## Ship summary` section to the plan
body via `update_plan(plan_id=<id>, body_md=<new_body>)`. One short
paragraph max — what shipped vs. what slipped — written in past
tense. This is useful breadcrumb context for future plans that
reference this one.

Format suggestion:

```markdown
## Ship summary

Shipped: <one-line list of what landed>.
Slipped: <one-line list of follow-ups created — todo ids>.
Tagged: <git tag if any>.
Closed by: <user> on <YYYY-MM-DD>.
```

Skip this step entirely if the user declines.

## Return message

Once all steps are done, render a one-paragraph summary:

```
Closed plan '<plan_slug>' as <accepted|archived>.
  - <N> linked todos marked done
  - <N> linked todos dropped
  - <N> follow-up todos created: <comma-separated ids>
View on dashboard: http://<dev-hub-host>/projects/<slug>/plans
```

## Notes on tone & boundaries

- This skill curates retrospectively. It does not commit code or
  modify the consumer repo. The terminal action is an MCP call.
- Don't propose new work — only walk what's already on the plan.
- If the user says "skip" on any step, skip it. Especially Step 6
  (ship summary) which is optional by design.
- If the plan's body references commit shas or PR numbers, you can
  surface those in the ship summary for breadcrumbs, but don't
  fetch them — the user already knows what shipped.
- Never call `create_plan` from this skill. New plans are
  `/dev-hub-workflow`'s territory.
