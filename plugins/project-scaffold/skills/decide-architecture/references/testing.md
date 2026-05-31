# Testing — decide-architecture (GREEN PASSED 2026-05-31)

**Result:** GREEN subagent test passed all five criteria (classified one-way/two-way
doors and deferred reversible calls, dated currency checks with links, full ADR
sections incl. revisit-if, wrote ADRs to the staging path only, produced a handoff
summary). Refactor fixes applied from test feedback: explicit `Door` field in the
template, single "deferred decisions" ADR pattern, missing-brief stop rule, ~1-page /
~6–8 ADR soft cap.


The scenarios below are the regression record. Re-run them after any future edit
to this skill — the writing-skills Iron Law: no skill change without a test first.

## RED — baseline (run WITHOUT this skill)

> "An AI agent that triages my backlog of articles and academic papers —
> ingests, summarizes, ranks by relevance to what I'm working on, resurfaces the
> right ones. I want current, cutting-edge AI tooling. Help me decide the
> architecture and stack." Do NOT write code. Then report: DECISIONS,
> WEB RESEARCH (did you verify currency?), ALTERNATIVES (recorded or just picks?),
> RATIONALE CAPTURE (would a later reader understand why?), ARTIFACT (durable
> record / ADRs, or only chat?).

Expected baseline failures this skill must close:
- States picks with no recorded alternatives or rationale.
- Recommends models/SDKs from stale training memory without verifying currency.
- Decides everything at once, including reversible calls.
- Leaves no ADRs — rationale dies in chat.
- No "revisit if" triggers for a loose-scope project.

## GREEN — with the skill present

Success criteria:
- Classifies one-way vs two-way door; defers reversible calls explicitly.
- Web-verifies each option's currency, with dates + links in the ADR.
- One ADR per decision with options + rationale + consequences + revisit-if.
- Confirms each decision with the user before recording.
- Hands off a description + stack summary for new-project.

## REFACTOR

Add explicit counters for any new rationalizations observed (e.g. "the brief
already implies the stack, so I'll skip the ADR").
