---
name: api-conventions
description: "REST API design conventions for {{SLUG}}."
paths: []
---

# API conventions — {{SLUG}}

## HTTP semantics
| Method | Semantics |
|---|---|
| GET | Read — idempotent, no body |
| POST | Create — returns 201 + Location header |
| PUT | Full replace |
| PATCH | Partial update |
| DELETE | Delete — returns 204 No Content |

## Response format
All responses are JSON. Always set `Content-Type: application/json`.

**Success:**
```json
{ "data": { ... } }
```

**Error:**
```json
{
  "error": {
    "code": "SNAKE_CASE_CODE",
    "message": "Human-readable description"
  }
}
```

**Validation error (422):**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "fields": { "email": "Invalid email format" }
  }
}
```

## Status codes
| Code | When |
|---|---|
| 200 | OK |
| 201 | Created |
| 204 | No Content (DELETE, empty PATCH) |
| 400 | Bad request (malformed JSON) |
| 401 | Not authenticated |
| 403 | Authenticated but not authorised |
| 404 | Resource not found |
| 422 | Validation failed |
| 500 | Unhandled server error |

## Auth
Bearer token in `Authorization` header: `Authorization: Bearer <token>`

## Versioning
`/api/v1/` prefix. Never change v1 in a breaking way — add v2 instead.

## Required endpoints
- `GET /health` — always returns `{"status": "ok"}` (used by CI and Kuma)
- No auth required on `/health`

## Documentation
Document all endpoints in `README.md` or an `openapi.yaml` at the project root.
