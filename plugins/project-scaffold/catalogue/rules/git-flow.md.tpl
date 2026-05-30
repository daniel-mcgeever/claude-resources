---
name: git-flow
description: "Git commit, branch, and tag conventions for {{SLUG}}."
paths: []
---

# Git conventions — {{SLUG}}

## Commit messages
Conventional Commits format: `<type>(<scope>): <short description>`

| Type | Use for |
|---|---|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `chore` | Maintenance, deps, tooling |
| `docs` | Documentation only |
| `refactor` | Code change with no behaviour change |
| `test` | Adding or fixing tests |
| `ci` | CI/CD workflow changes |

Examples:
```
feat(api): add /health endpoint
fix(db): handle null values in user lookup
chore(deps): bump fastapi to 0.115.6
```

## Branches
- `main` — always deployable; protected in Forgejo (no direct pushes)
- `feat/<short-name>` — new features
- `fix/<short-name>` — bug fixes
- `chore/<short-name>` — maintenance

## Merge strategy
Squash and merge PRs into `main` to keep history clean.
Delete the source branch after merge.

## Tags (releases)
Semver: `v<major>.<minor>.<patch>`
Tag `main` after merge, before running `Skill(build-and-push)`:
```bash
git tag v0.2.0
git push origin v0.2.0
```

## Push rules
- Never force-push `main`
- Use `--force-with-lease` on feature branches if rebase needed
- Do not commit `.env` — it's in `.gitignore`
