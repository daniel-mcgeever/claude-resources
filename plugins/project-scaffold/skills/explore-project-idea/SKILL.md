---
name: explore-project-idea
description: Use when starting a brand-new project whose scope is still loose or fuzzy — you have a rough idea but no settled design, and locking an architecture or tech stack now would be premature. Especially for cutting-edge AI projects where current capabilities matter. NOT for features inside an existing codebase (use superpowers:brainstorming) and NOT when the design is already clear (go straight to new-project).
---

# Explore Project Idea

> Verified 2026-05-31 via RED baseline + GREEN subagent tests. See `references/testing.md`.

## Overview

The pre-scaffold ideation step. Turn a fuzzy idea into a shared, written **concept brief** through conversation — *staying in the problem space* and deliberately **not** committing to an architecture yet. That commitment is the next skill's job (`decide-architecture`).

**Core principle:** Loose scope is a feature, not a bug. Premature architecture is the failure mode this skill exists to prevent. Explore *what* and *why* before *how*.

**REQUIRED BACKGROUND:** Use the one-question-at-a-time conversational technique from **superpowers:brainstorming**. This skill owns the project-ideation flow and the web-research + artifact requirements on top of it.

## When to use

- A new project where you "kind of know" what you want but not the shape.
- Cutting-edge AI ideas where what's *possible* shifts month to month.
- You feel `new-project` would force stack/architecture decisions too early.

**When NOT to use:**
- Design already clear → go straight to `project-scaffold:new-project`.
- A feature/change inside an existing repo → `superpowers:brainstorming`.
- You already know it's time to pick the stack → `decide-architecture`.

## The flow

1. **Open in the problem space.** What's the pain? Who's it for (even if just you)? What does a good day look like once this exists? One question at a time.
2. **Research what's now possible — early and often.** For AI work especially, your training knowledge is stale. Web-search the current capability landscape and prior art *before* converging. See "Web research" below.
3. **Keep 2–3 framings alive.** Resist collapsing to one idea. Name distinct directions and what each optimizes for.
4. **Probe constraints & success signals**, not implementation. What must be true? What's explicitly out of scope for now?
5. **Converge just enough.** Stop when you can name the core capability and at least one viable direction — not when every detail is settled.
6. **Write the concept brief** (template below) and **hand off**.

## Web research (do not skip for AI projects)

Today's tooling postdates your training. Before recommending or anchoring on any capability:
- Search for the current state: "what can X do in {current year}", prior art, recent approaches.
- **Record findings with the date you found them and a link.** Capability-level only ("retrieval over PDFs is now cheap/standard"), NOT final library picks — picks belong in `decide-architecture`.
- Naming incumbent products as prior art ("tool X already does this") is fine and useful. Naming what *you* will build with is a pick — defer it.
- If you can't verify something is current, say so in the brief rather than asserting it.

## The artifact

Write to the staging area (the project dir doesn't exist yet):

```
/home/daniel/projects/.scaffold-drafts/<slug>/concept-brief.md
```

`<slug>` is the kebab-case form of a working name — if the idea has no name yet, coin one with the user first, then derive the slug. Create the directory before writing: `mkdir -p /home/daniel/projects/.scaffold-drafts/<slug>`. Use the template in `references/concept-brief-template.md`. `new-project` reads this later to pre-fill the project description; `decide-architecture` reads it as its starting context.

## Handoff

When the brief is written, offer the next step:
- "Ready to make the architecture/stack calls? → `decide-architecture`."
- Or, if the stack is genuinely obvious already, "→ `new-project` (it'll pick up this brief)."

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Suggesting a framework/stack during ideation | Stop. Note it as an open question; that's `decide-architecture`'s job. |
| Relying on training knowledge for "what's possible" | Web-search current AI capabilities; cite with dates. |
| Collapsing to one idea immediately | Hold 2–3 framings until the user actively chooses. |
| Ending in chat with nothing written | Always produce `concept-brief.md`. A future agent inherits only what's on disk. |
| Asking a wall of questions at once | One question at a time (superpowers:brainstorming). |

## Red flags — you are drifting into architecture too early

- You're naming databases, frameworks, or model SDKs.
- You're sketching components or a folder layout.
- You've picked one idea before the user has.

**All of these mean: pull back to the problem space.** Capability-level web findings are fine; concrete picks are not — defer them to `decide-architecture`.
