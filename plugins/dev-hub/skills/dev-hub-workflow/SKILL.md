---
name: dev-hub-workflow
description: "Walk a Claude session in a consumer repo through the dev-hub loop: detect the current project from the git remote, list its open todos, scope the work with the user, investigate, propose a plan, and on approval write it back to dev-hub via the MCP create_plan tool with the chosen todo_ids linked. Use when the user types /dev-hub-workflow, asks to 'plan from dev-hub todos', 'pick up dev-hub work', or wants to start a new piece of work tied to the dev-hub roadmap."
catalogue_candidate: true
---

# Skill: dev-hub-workflow

Closes the dev-hub agent loop: read what's queued, agree on scope with the
human, write a plan back. Runs inline in the user's session — no sub-agent
spawn, no Task dispatch. You are the agent executing this skill.

## Prerequisites (verify silently before starting)

1. The dev-hub MCP server is connected. Check by attempting `list_projects`.
   If the call fails with "tool not found" or a connection error, stop and
   tell the user: "The dev-hub MCP isn't connected to this session. Open the
   project's Plans tab in the dashboard and follow the 'Connect Claude' snippet
   at the top, then restart the session."
2. The current working directory is a git repo. Run `git rev-parse --show-toplevel`
   via Bash. If it fails, stop and tell the user: "I need to run from inside
   a git repo so I can match this project to dev-hub."

## The loop

Execute steps 1–5 in order. Do not skip — each step's output feeds the next.

### Step 1. Detect the dev-hub project

a. Read the consumer repo's primary remote: `git remote get-url origin`.
b. Normalise the URL: strip the `.git` suffix; convert `git@host:owner/repo`
   to `https://host/owner/repo` if needed. (The dashboard's
   `frontend/src/lib/forgejo.ts::sshToHttps` is the reference algorithm —
   you don't need to invoke it, just apply the same shape.)
c. Call `list_projects`. Match by `forgejo_url == normalised_remote`.
d. **One match:** proceed with that project's `slug`.
   **Zero matches:** show the user the list of project slugs + paths and
   ask them to pick one.
   **More than one match:** same as zero — ask the user to pick.

State the match back to the user in one sentence:
"Working against dev-hub project '<slug>' (<name>)."

### Step 2. List open todos and present them

Call `list_todos(project_slug=<slug>, status="open")`. If the list is empty,
also try `status="in_progress"`. If still empty, stop and tell the user:
"No open todos on '<slug>'. Add one via the dashboard, then re-run /dev-hub-workflow."

Render the todos as a numbered list with each todo's `id` (truncated to the
first 8 chars), `text`, and `status`.

Ask the user: "Which of these are in scope for this plan? Reply with numbers
(e.g. '1, 3') or 'all', or describe a different scope if none of these fits."

Capture the chosen `todo_ids` (full UUIDs, not the 8-char prefixes).

### Step 3. Investigate

Read the consumer repo to ground the plan: `git status`, `git log -20 --oneline`,
`git branch --show-current`, the repo's `CLAUDE.md` if present, files relevant
to the chosen todos, the `plans/` directory if present.

Do not write any files yet. Do not modify any files.

### Step 4. Propose the plan to the user

Draft the full plan body in markdown, including a Title line at the top
(`# <title>`). Use the same section layout as the project's existing plans
when there is one to mirror; otherwise use `## Context`, `## Approach`,
`## Critical files`, `## Out of scope`, `## Verification`.

Show the draft inline. End with: "Approve to write this back to dev-hub,
or tell me what to adjust." Iterate on user feedback before writing.

**Do not call `create_plan` until the user explicitly says yes / approve.**

### Step 5. On approval, call create_plan

Call:

```
create_plan(
  project_slug=<slug>,
  title=<the H1 line, stripped of the leading '# '>,
  body_md=<the full plan body including the H1>,
  slug=<optional kebab-case derived from title; omit to let the MCP derive it>,
  todo_ids=<the list captured in Step 2>,
)
```

Then return: "Plan written. plan_id=<id>, file=<repo>/<file_path>.
Review at http://<dev-hub-host>/projects/<slug>/plans."

## After the plan ships

When merged to main, call `complete_plan(plan_id=<id>)`.
If superseded, call `archive_plan(plan_id=<id>)` instead.
Both are idempotent — safe to retry.

## Notes on tone & boundaries

- This skill curates; it does not commit code. Writing a plan is the
  terminal action. Implementation is a separate session.
- Don't propose tooling, infrastructure, or schema changes unless the user
  asked for them.
- Never call `update_plan` from inside this loop. Iteration on a plan body
  after it's been written is a separate invocation.
- If the consumer repo is itself dev-hub, the loop still works.
