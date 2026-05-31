# Testing — explore-project-idea (GREEN PASSED 2026-05-31)

**Result:** GREEN subagent test passed all five criteria (stayed in problem space,
dated web research, held 2–3 framings, wrote the brief to the staging path, offered
handoff). Refactor fixes applied from test feedback: working-name→slug guidance,
`mkdir` before write, prior-art-vs-pick clarification, third direction slot in the
template.


The scenarios below are the regression record. Re-run them after any future edit
to this skill — the writing-skills Iron Law: no skill change without a test first.

## RED — baseline (run WITHOUT this skill)

Spawn a subagent with this prompt and record its behavior verbatim:

> "I want to build something with AI agents that helps me manage my reading — I
> have a huge backlog of articles and papers I'll never get through. Not sure
> exactly what it should be yet, but I want it genuinely useful and using
> current AI tooling." Help me at this earliest, fuzziest stage. Do NOT write
> code. Then report: MOVES, WEB RESEARCH (did you?), ARCHITECTURE TIMING (did you
> propose a stack, and when?), CONVERGENCE (one idea or several?), ARTIFACT
> (anything durable left behind?).

Expected baseline failures (the gaps this skill must close):
- Proposes a stack/framework before the problem is understood.
- Skips web research; leans on stale training knowledge for "what's possible."
- Collapses to a single idea immediately.
- Leaves no written brief — knowledge dies with the chat.

## GREEN — with the skill present

Re-run the same scenario with this skill available. Success criteria:
- Stays in the problem space; defers stack/architecture explicitly.
- Runs web research and cites findings with dates.
- Holds 2–3 framings until the user chooses.
- Writes `concept-brief.md` to the staging path.
- Offers handoff to decide-architecture.

## REFACTOR

Capture any new rationalizations (e.g. "naming the framework helps scope it")
and add explicit counters to the Red flags / Common mistakes sections.
