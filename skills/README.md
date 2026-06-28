# skills/ — central library of reusable, project-authored skills

This is the shared home for skills that started life in one project's
`.claude/skills/` and turned out to be useful elsewhere. It exists so a skill is
**findable in one place** instead of buried in whichever repo first needed it.

## How a skill gets here

From the source project, run the `project-scaffold` plugin's skill:

```
Skill(promote-skill)   # e.g. promote-skill grill-me
```

It copies `.claude/skills/<name>/` into `skills/<name>/` here, records provenance in
`skills/<name>/.source.json`, adds a row to `INDEX.md`, and commits on a branch for
review. See `plugins/project-scaffold/skills/promote-skill/SKILL.md`.

## How to reuse one in another project

This library does **not** auto-install anything — reuse is a deliberate copy:

```bash
cp -r ~/projects/claude-resources/skills/<name> ~/projects/<other-project>/.claude/skills/<name>
```

(A skill is discovered only as `.claude/skills/<name>/SKILL.md` — a directory, not a
flat file.) Browse `INDEX.md` to see what's available.

## Relationship to the scaffold catalogue

- `skills/` (here) = reuse a skill into an **existing** project, by hand, today.
- `plugins/project-scaffold/catalogue/skills/` = `.tpl` skills a **new** project can opt
  into at creation time.

A skill can live in both; they serve different moments.
