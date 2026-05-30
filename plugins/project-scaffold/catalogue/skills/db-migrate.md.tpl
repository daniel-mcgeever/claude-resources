---
name: db-migrate
description: "Apply database migrations for {{SLUG}}. Use after adding new migration files to the migrations directory."
---

# Skill: db-migrate — {{SLUG}}

## Prerequisites
- DB container is running: `docker compose ps db` shows `Up (healthy)`
- Migration files are in the expected directory (update this after choosing a migration tool)

## Run migrations
```bash
cd ~/projects/{{SLUG}}
docker compose run --rm app <migration-command>
```

Replace `<migration-command>` with the project-specific tool:
| Tool | Command |
|---|---|
| Alembic (Python) | `alembic upgrade head` |
| Drizzle (Node) | `npm run db:migrate` |
| Prisma (Node) | `npx prisma migrate deploy` |
| golang-migrate | `migrate -database $DATABASE_URL -path ./migrations up` |
| Raw SQL | `psql $DATABASE_URL -f migrations/NNNN_name.sql` |

## Before migrating in production
1. Take a snapshot:
   ```bash
   docker compose exec db pg_dump -U app {{SLUG}} > /tmp/pre-migration-$(date +%Y%m%d-%H%M).sql
   ```
2. Verify the migration has a rollback path

## Rollback
```bash
docker compose run --rm app <rollback-command>
# e.g. alembic downgrade -1 / migrate down 1 / npx prisma migrate revert
```
