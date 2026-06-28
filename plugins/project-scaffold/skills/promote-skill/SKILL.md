---
name: promote-skill
description: "Promote a project-authored skill into the central skills/ library in the claude-resources repo, so other projects can find and reuse it. Copies the skill, indexes it, records provenance, and commits on a branch for review. Triggers: 'promote this skill', 'share this skill', 'add this skill to claude-resources', 'promote-skill <name>'."
---

# Skill: promote-skill — share a local skill into the central library

## When to use this skill

You authored a skill in a project's `.claude/skills/` and it's useful beyond this
project. This copies it into the **central `skills/` library** in the `claude-resources`
repo (`~/projects/claude-resources/skills/`) and indexes it, so any other project can
find it there and copy it in. It does **not** auto-install the skill anywhere — the
library is a findable home, reuse is a deliberate copy per project.

For **agents or rules** (not skills) worth sharing, don't use this — add
`catalogue_candidate: true` to their YAML frontmatter instead.

## Prerequisites

- `claude-resources` is cloned at `~/projects/claude-resources` (it is, on vm-160).
- You are in the source project's repo (the one that holds the skill).

## Step 1 — Identify the skill and the source project

Take the skill name from the invocation (e.g. `promote-skill grill-me`). Locate it in
the current project — directory-form is canonical, flat-file is the fallback:

```bash
NAME=<skill-name>
SRC_PROJECT=$(basename "$(git rev-parse --show-toplevel)")
if   [ -f ".claude/skills/${NAME}/SKILL.md" ]; then SRC=".claude/skills/${NAME}"; MODE=dir
elif [ -f ".claude/skills/${NAME}.md" ];       then SRC=".claude/skills/${NAME}.md"; MODE=file
else echo "ERROR: no skill '${NAME}' under .claude/skills/"; exit 1; fi
echo "Promoting '${NAME}' (${MODE}) from project '${SRC_PROJECT}'"
```

Read the skill's `SKILL.md` frontmatter `description:` — you'll use a one-line version
of it for the index row. If the skill has a `catalogue_candidate: true` marker, that's
expected; leave it.

## Step 2 — Sync claude-resources and branch

Never work on `main`. Pull first so the branch is current, then cut a topic branch:

```bash
cd ~/projects/claude-resources
git checkout main && git pull --rebase
git checkout -b "feat/skill-${NAME}"
```

## Step 3 — Copy the skill into the library (directory form)

The library stores every skill as a directory (`skills/<name>/SKILL.md`), even if the
source was a flat file — normalize on the way in:

```bash
mkdir -p ~/projects/claude-resources/skills/${NAME}
if [ "$MODE" = dir ]; then
  cp -r <source-project-path>/.claude/skills/${NAME}/. ~/projects/claude-resources/skills/${NAME}/
else
  cp <source-project-path>/.claude/skills/${NAME}.md  ~/projects/claude-resources/skills/${NAME}/SKILL.md
fi
```

If `skills/${NAME}/` already exists, this is an **update** to an existing library skill:
show the diff (`git diff`) and confirm with Daniel before overwriting — don't silently
clobber a skill another project promoted.

## Step 4 — Record provenance

Write `skills/${NAME}/.source.json` so the library remembers where each skill came from
(mirrors the `skills-lock.json` shape used for vendored skills):

```json
{
  "name": "<name>",
  "source": "<source-project-slug>",
  "sourcePath": ".claude/skills/<name>",
  "promotedOn": "<today's date, YYYY-MM-DD>"
}
```

## Step 5 — Update the index

Append one row to `~/projects/claude-resources/skills/INDEX.md` (keep it alphabetical):

```
| `<name>` | <one-line description from the skill's frontmatter> | <source-project> | <YYYY-MM-DD> |
```

## Step 6 — Commit on the branch (do not push)

```bash
cd ~/projects/claude-resources
git add skills/${NAME} skills/INDEX.md
git commit -m "feat(skills): promote ${NAME} from ${SRC_PROJECT}"
```

Leave the push and merge to Daniel — this is a shared cross-project change and gets its
own review (see the `project-lifecycle` skill).

## Step 7 — Report

Tell Daniel:

```
✅ Promoted '<name>' → claude-resources/skills/<name>/
   Branch:  feat/skill-<name>  (committed, not pushed)
   Index:   skills/INDEX.md updated
   Reuse elsewhere: copy skills/<name>/ into that project's .claude/skills/<name>/
   Review & push:   cd ~/projects/claude-resources && git push -u origin feat/skill-<name>
```
