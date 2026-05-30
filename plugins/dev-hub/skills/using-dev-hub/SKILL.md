---
name: using-dev-hub
description: "Orient yourself to the dev-hub tool surface in a consumer repo. Names the slash commands, explains when to reach for which workflow, and points at the generated tool reference. Use when the user mentions dev-hub for the first time in a session, asks 'what can dev-hub do here', or you've just connected to the MCP and need the lay of the land."
---

# Skill: using-dev-hub

A pointer skill. The dev-hub MCP gives you **a full set of tools** for reading and
writing the dashboard's state. There are six workflow skills (each with
a paired slash command) that wrap the most common loops.

## Slash commands

| Command | Use it for |
|---|---|
| `/dev-hub-workflow` | Start of work: read queued todos, agree scope, write a plan back. |
| `/dev-hub-brainstorm` | Capture user-voiced ideas as atomic thoughts; suggest links to related open thoughts. |
| `/dev-hub-promote` | Promote a cluster of ripe thoughts to a plan / todos / milestone, atomically. |
| `/close-out-plan` | A plan's work has shipped — mark accepted, retire its linked todos. |
| `/dev-hub-init` | Project not registered, or partial-state recovery. |
| `/dev-hub-doctor` | Something feels broken — diagnose the MCP connection. |

## When to reach for what

- "What's on the roadmap for this repo?" → `list_todos`, `list_plans`, `list_milestones`.
- "I'm about to start work" → `/dev-hub-workflow`.
- "User just had an idea / question / concern" → `/dev-hub-brainstorm`.
- "These N thoughts are clearly the same shape, let's commit" → `/dev-hub-promote`.
- "I shipped a plan, close it out" → `/close-out-plan`.
- "Connection feels off" → `/dev-hub-doctor`.

## Tool reference

The full tool surface is discovered at runtime — the MCP server is the source
of truth. Call the MCP `tools/list` (it surfaces automatically when the plugin
is connected) to see the current tools with live descriptions, or read the
canonical grouped table in the dev-hub repo's `CLAUDE.md`. There is no static
copy bundled in this skill, so it can never drift from the server.

## Tool-name prefix

When invoked via this plugin, MCP tool names surface as
`mcp__plugin_dev-hub_dev-hub__<tool>`. Claude resolves descriptions, so
referring to the unprefixed name (`list_projects`, `create_thought`) in
skill bodies and conversation works either way.

## Do not

- Bulk-create todos without confirming scope with the user — dev-hub
  treats every todo as a real commitment.
- Edit a thought once it's been promoted (`status='promoted'`). The
  promotion is the authoritative handoff; edit the resulting
  plan/todo/milestone instead.
- Use `delete_thought` for "I changed my mind" — soft-retire via
  `update_thought(status='closed')` keeps the history readable.
- Write a plan markdown file by hand — `create_plan` and `update_plan`
  own the atomic file+DB write.
