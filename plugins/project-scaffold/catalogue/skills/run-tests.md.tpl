---
name: run-tests
description: "Run the {{SLUG}} test suite and return a pass/fail summary with failure details."
---

# Skill: run-tests — {{SLUG}}

## Run all tests
```bash
cd ~/projects/{{SLUG}}
docker compose run --rm app <test-command>
```

Replace `<test-command>` with the project-specific runner (update CLAUDE.md when you know it):
- Python: `pytest` or `python -m pytest -v`
- Node: `npm test`
- Go: `go test ./...`
- Generic: check `CLAUDE.md` or the Dockerfile CMD

## Run a single file/module
```bash
docker compose run --rm app pytest path/to/test_file.py    # Python
docker compose run --rm app npm test -- path/to/test       # Node
docker compose run --rm app go test ./pkg/...              # Go
```

## Interpreting failures

| Failure type | Likely cause | Fix |
|---|---|---|
| Import error / module not found | Missing dependency or misconfigured env | Check `.env`, `pyproject.toml`, `package.json` |
| Connection refused | DB/Redis container not running | `docker compose up -d db redis` first |
| Assertion error | Code regression or test needs updating | Fix the code or the test |
| Timeout | Slow DB query or network call | Check for missing mocks or test data |

## CI equivalent
The same tests run automatically in Forgejo Actions on every push.
Check recent runs at `https://forgejo.towneygorm.cc/daniel/{{SLUG}}/actions`.
