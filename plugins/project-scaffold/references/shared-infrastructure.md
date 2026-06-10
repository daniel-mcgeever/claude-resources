# Shared homelab infrastructure — defaults for new projects

> Reference for the `project-scaffold` skills (esp. **decide-architecture** and **new-project**).
> When a new project needs a **relational database, object storage, or authentication**, it uses the
> SHARED homelab services described here — **sectioned off per app** — rather than standing up its own
> or re-deciding from scratch. **Record an ADR only when you DEVIATE** from these defaults.
>
> *Why:* a solo/family homelab runs many small apps; shared, reusable backing services keep ops low and
> isolation clean. Each app gets its **own database, own bucket, own OIDC client** — no instance-wide
> API/keys/auth coupling. Determined 2026-06 after evaluating (and rejecting) a shared-Supabase model;
> see the Cófra schema v0.4/v0.5 decision for the full rationale.

---

## The three shared services

### 1. PostgreSQL — shared cluster, **database-per-app**
- One Postgres cluster per environment, fronted by **PgBouncer** (transaction pooling, one wildcard entry).
- Each app gets its **own database** owned by a dedicated login role, with
  **`REVOKE CONNECT ON DATABASE <app> FROM PUBLIC`** + a grant to the app role — so no app's role can
  even *connect* to another app's data (CONNECT is checked before any schema/table privilege). This is
  database-per-app, **not** schema-per-app (schema-per-app has no DB-level enforcement).
- Recursive CTEs + JSONB are core Postgres — available to every app, no extension needed.
- **Cluster image:** `pgvector/pgvector:pg17` (Postgres 17 with the `pgvector` extension *available*) — so
  any app can later add vector/embedding search. Extensions are enabled **per-database** by the
  infra-manager (superuser-gated; a per-app role can't self-enable), so this does **not** affect app
  isolation. (`VectorChord` / `tensorchord/vchord-postgres` is the drop-in upgrade path if an app ever
  outgrows pgvector at scale.) Pin the tag (PG minor ≥ the running one — never a downgrade); keep dev and
  prod on the same image.
- **Connect through PgBouncer.** In transaction-pooling mode, server-side prepared statements need care:
  `node-postgres` is fine (off by default); with **`postgres.js` set `prepare: false`** (or run
  PgBouncer ≥ 1.21 with `max_prepared_statements > 0`).
- **Backups:** per-app `pg_dump` (clean selective restore) **plus** cluster-wide WAL archiving for DR —
  the shared WAL can't selectively restore one database, so run both layers.

### 2. Object storage — **Garage** (S3-compatible)
- One **Garage** cluster per environment (S3-compatible; single Rust binary, reliability-first). **MinIO
  is NOT used** — its open-source edition was archived/unmaintained in 2026.
- Each app gets its **own bucket(s)** + a **scoped access key** (read/write/owner per bucket) — that *is*
  the per-app isolation. Use **presigned URLs** for client up/download; the DB stores the object key.
- **Caveat:** Garage has **no S3 Object Lock / versioning**. Fine for app data. If an app needs WORM
  (immutable / ransomware-proof) storage — realistically only *backup targets* — provide immutability at
  the backup layer (append-only restic/Kopia, or a dedicated immutable target / SeaweedFS), not here.

### 3. Auth — **Authentik (OIDC)**
- The homelab's **existing Authentik** is the shared IdP. Each app = its **own OIDC client** (one
  Application + one OAuth2/OIDC Provider).
- Per-app roles via **Application Entitlements** (free/OSS, Authentik ≥ 2024.12) on the `entitlements`
  scope — **not** the global `groups` claim (which leaks every group name to every app and couples them).
- Manage clients as **Blueprints** (YAML config-as-code) so onboarding app N is repeatable.
- The app is a plain OIDC relying party; identity = the OIDC `sub`. Mirror it into a local `app_user`
  table if you need FK integrity / a role cache. Authorization (incl. owner/admin gating) is enforced in
  the app from the verified token.

---

## A new app's "section" (provisioned by the vm-153 infra-manager)
Adopting the shared infra means the infra-manager stamps out, per app:
1. **DB** — `CREATE DATABASE <app>; CREATE ROLE <app>_app LOGIN PASSWORD '…'; ALTER DATABASE <app> OWNER
   TO <app>_app; REVOKE CONNECT ON DATABASE <app> FROM PUBLIC; GRANT CONNECT ON DATABASE <app> TO
   <app>_app;` (+ optional `ALTER ROLE <app>_app CONNECTION LIMIT n`). The PgBouncer wildcard already
   covers the new database.
2. **Storage** — a Garage bucket (e.g. `<app>-media`) + an access key scoped to it.
3. **Auth** — an Authentik OIDC client (Application + Provider) + an entitlement set (e.g. `<app>-owner`).
4. **Creds delivered** to the app's env (below).

## Connection / env conventions
Each app reads its coordinates from env — **dev:** gitignored `.env` at the repo root; **prod:**
`/srv/infra/stacks/<slug>/.env`. Standard variable names:
```
DATABASE_URL=postgresql://<app>_app:<pw>@<pgbouncer-host>:<port>/<app>
S3_ENDPOINT=  S3_REGION=  S3_BUCKET=  S3_ACCESS_KEY=  S3_SECRET_KEY=
OIDC_ISSUER=  OIDC_CLIENT_ID=  OIDC_CLIENT_SECRET=  OIDC_REDIRECT_URI=
```
Coordinate-as-config: a prod-safe default + a deliberate per-repo dev override. Secrets live only in
`.env` (`chmod 600`), are sourced never printed, and never committed.

## Topology
| Service | Dev | Prod |
|---|---|---|
| PostgreSQL + PgBouncer | **vm-160** — `/srv/infra/stacks/shared-data/` | **vm-107** — `/srv/infra/stacks/shared-data/` |
| Garage (S3) | vm-160 (same stack) | vm-107 (same stack) |
| Authentik (existing) | shared instance (reused) | shared instance (reused) |

The shared **data plane** (Postgres + PgBouncer + Garage) is one compose stack per environment —
**dev on vm-160, prod on vm-107**. Authentik already runs as its own shared service and is reused, not
redeployed.

## When NOT to use the shared infra (record an ADR if you deviate)
- An app with hostile/heavy load, a hard isolation/compliance boundary, or an incompatible Postgres
  version/extension → give it its **own** Postgres instance/container.
- An app that needs native **WORM / Object-Lock** object storage → a dedicated immutable target /
  SeaweedFS, not Garage.
- Otherwise, **default to the shared services above** — don't stand up per-app databases, buckets, or
  IdPs, and don't reach for bundled platforms (e.g. Supabase) that couple the API surface, keys, and auth
  pool at the instance level.
