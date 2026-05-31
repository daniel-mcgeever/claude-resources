---
name: decide-architecture
description: Use when a new project's idea is understood but its architecture and tech stack are not yet chosen, and you need to make and record those decisions before scaffolding — especially for cutting-edge AI work where models, SDKs, and frameworks change fast and training knowledge is stale. NOT for architecture changes inside an existing codebase, and NOT when the stack is already obvious (go straight to new-project).
---

# Decide Architecture

> Verified 2026-05-31 via RED baseline + GREEN subagent tests. See `references/testing.md`.

## Overview

Turn an understood concept into concrete, **recorded** architecture and stack decisions — each researched against the *current* landscape, each with alternatives and rationale, captured as lightweight ADRs. The output pre-fills `new-project`'s tech-stack input.

**Core principle:** Decide what must be decided now, research it against today's reality, and write down *why* — including the alternatives you rejected and the trigger that would reopen the call. Don't decide what you don't have to yet.

## When to use

- A concept brief (or clear shared understanding) exists; it's time to choose the stack/shape.
- The project uses fast-moving AI tooling where "what I remember" is likely out of date.
- Coming from `explore-project-idea` (reads its `concept-brief.md`).

**When NOT to use:**
- Stack is genuinely obvious → `project-scaffold:new-project`.
- Architecture decision inside an existing codebase → different context; use the repo's own conventions.
- The idea itself is still fuzzy → back up to `explore-project-idea`.

## The flow

1. **Load context.** Read `~/projects/scaffold-drafts/<slug>/concept-brief.md` first (the Forgejo-backed staging repo; clone it if `~/projects/scaffold-drafts` is missing — see "The artifact"). Build on it; don't re-litigate the idea. If the brief is **missing**, stop and send the user back to `explore-project-idea` rather than inventing the concept from memory — the brief is the source of truth, not the chat prompt. If it appears mid-session, re-read it.
2. **List the decisions that actually need making** for *this* project. Classify each:
   - **One-way door** (hard/expensive to reverse: core model strategy, primary datastore, runtime/deployment shape) → research deeply, decide now.
   - **Two-way door** (cheap to change later: a helper lib, a UI detail) → keep light, or defer explicitly.
3. **Research each open decision against the current landscape** before recommending. See "Web research" — mandatory for AI tooling.
4. **Confirm with the user, one decision at a time.** Recommend, show the alternatives, let them choose. Don't decide unilaterally.
5. **Write one ADR per accepted decision** using the template. Record all deferred two-way-door decisions *together* in a single "deferred decisions" ADR (each with a starting default + a revisit trigger) — don't file one ADR per deferral.
6. **Hand off** with a recommended one-line description + a tech-stack summary derived from the ADRs.

## Web research (mandatory for AI tooling)

Models, SDKs, and frameworks move faster than your training cutoff. For every candidate option:
- Search current status: latest version, active maintenance, deprecation, known successor.
- Prefer options you can confirm are current **as of today's date**; record that date and a link in the ADR.
- If you can't verify currency, mark the option "unverified — confirm before building," don't assert it.

## The artifact

ADRs live in the same **Forgejo-backed staging repo** as the concept brief
(`daniel/scaffold-drafts`, cloned at `~/projects/scaffold-drafts`). One file per
decision:

```
~/projects/scaffold-drafts/<slug>/decisions/adr-NNN-<short-slug>.md
```

`NNN` is zero-padded sequence (001, 002, …). Use `references/adr-template.md`.

**Pull before writing**, then commit + push so they're readable in the webapp:
```bash
git -C ~/projects/scaffold-drafts pull --rebase          # other sessions may have pushed
cd ~/projects/scaffold-drafts && git add <slug>/ \
  && git commit -m "idea(<slug>): architecture decisions" && git push
```
Then give the user the webapp link to the decisions:
`https://forgejo.towneygorm.cc/daniel/scaffold-drafts/src/branch/main/<slug>/decisions`.

On scaffold, `new-project` ports these ADRs into a **dev-hub plan** linked to the
new project (and the brief into dev-hub thoughts), then removes the `<slug>`
folder from this repo — so a folder here always means *an idea not yet built*.

## Handoff

When ADRs are written, summarize for `new-project`:
- **Description:** one line (from the brief).
- **Tech stack:** the accepted choices, one line.
- **Deferred:** decisions intentionally left open (so they're not silently forgotten).
- Then: "Ready to scaffold? → `project-scaffold:new-project` (it'll pick these up)."

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Stating a pick with no alternatives | Every ADR records options considered + why-not. |
| Recommending from memory | Web-verify currency; record the date + link. |
| Deciding everything up front | Defer two-way-door calls; mark them deferred, not decided. |
| No "revisit if" trigger | Each ADR names what would reopen it — loose scope means decisions will move. |
| Reasoning lives only in chat | Always write the ADR files AND push them to scaffold-drafts. |
| Re-debating the idea | The brief settled *what*; you decide *how*. |
| Gold-plating the ADRs | Keep each to ~1 page; past ~6–8 ADRs you're likely over-deciding — defer more. |

## Red flags

- An ADR with a "Decision" but empty "Options considered."
- A version number or model name asserted without a dated source.
- You're locking a decision the project won't feel for months → defer it instead.
