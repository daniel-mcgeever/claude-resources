---
name: testing-conventions
description: "Test file layout and coverage expectations for {{SLUG}}."
paths: []
---

# Testing conventions — {{SLUG}}

## File layout
| Language | Test directory | File naming |
|---|---|---|
| Python | `src/tests/` | `test_<module>.py` |
| Node/TS | `src/__tests__/` or `src/` | `<module>.test.ts` |
| Go | Same package | `<file>_test.go` |

## Test types
- **Unit tests** — pure logic, no I/O, no DB. Fast. Mock external deps.
- **Integration tests** — test API endpoints and DB layer together. Use the compose `db` sidecar; do NOT mock the DB.
- **No E2E in this layer** — E2E tests (if any) live separately and are not part of the CI gate.

## Coverage expectations
- Target 60%+ line coverage on new code (not enforced by CI gate, but tracked)
- Every new endpoint must have at least one happy-path and one error-path test
- Do not merge to `main` with a failing test

## Test data
- Use factories/fixtures for test data — no raw INSERT statements in test bodies
- Clean up test data in teardown (or use transaction rollback)
- Never share state between tests — each test must be independent

## Mocking
- Document any `time.now()` or `random` mocks with the seed/mock value in a comment
- Do not mock your own application code — only mock external services
