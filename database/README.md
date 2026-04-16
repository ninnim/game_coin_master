# Spin Empire — Database Setup

## Overview

PostgreSQL 16 database for Spin Empire (Coin Master clone).
All 23 tables, indexes, constraints, seed data and migrations live in this folder.

---

## Files

| File | Purpose |
|------|---------|
| `schema.sql` | Full schema — run once on a fresh database |
| `seed.sql` | All reference/seed data — run after schema.sql |
| `railway_migration.sql` | Idempotent schema for Railway (safe to re-run) |
| `migrations/001_initial.sql` | Migration wrapper with up/down sections |

---

## Local Setup (PostgreSQL 16, localhost)

### Prerequisites
- PostgreSQL 16 installed and running on port 5432
- `psql` CLI available in PATH

### Step 1 — Create the database

```bash
psql -U postgres -c "CREATE DATABASE spin_empire_db;"
```

### Step 2 — Run the schema

```bash
psql -U postgres -d spin_empire_db -f database/schema.sql
```

### Step 3 — Load seed data

```bash
psql -U postgres -d spin_empire_db -f database/seed.sql
```

### Step 4 — Verify

```bash
psql -U postgres -d spin_empire_db -c "\dt"
psql -U postgres -d spin_empire_db -c "SELECT COUNT(*) FROM villages;"
psql -U postgres -d spin_empire_db -c "SELECT COUNT(*) FROM buildings;"
psql -U postgres -d spin_empire_db -c "SELECT COUNT(*) FROM cards;"
psql -U postgres -d spin_empire_db -c "SELECT COUNT(*) FROM achievements;"
```

Expected counts:
- villages: 10
- buildings: 90
- cards: 108
- achievements: 50

### Connection string (for backend .env)

```
Host=localhost;Port=5432;Database=spin_empire_db;Username=postgres;Password=TimeCapsule2026!
```

---

## Railway Setup (Cloud PostgreSQL)

### Prerequisites
- Railway account at https://railway.app
- Railway CLI installed: `npm install -g @railway/cli`
- A Railway project with a PostgreSQL plugin added

### Step 1 — Get Railway connection details

In the Railway dashboard, open your PostgreSQL service and copy the connection string. It looks like:

```
postgresql://postgres:<password>@<host>.railway.app:<port>/railway
```

Or use Railway CLI:

```bash
railway login
railway link        # link to your project
railway variables   # shows DATABASE_URL
```

### Step 2 — Run the idempotent migration

The `railway_migration.sql` file uses `CREATE TABLE IF NOT EXISTS` so it is safe to run multiple times.

```bash
# Using psql with Railway connection string directly:
psql "postgresql://postgres:<password>@<host>.railway.app:<port>/railway" \
  -f database/railway_migration.sql

# Or via Railway CLI (pipes to your linked project's DB):
railway run psql $DATABASE_URL -f database/railway_migration.sql
```

### Step 3 — Load seed data

```bash
psql "postgresql://postgres:<password>@<host>.railway.app:<port>/railway" \
  -f database/seed.sql
```

### Step 4 — Update your backend environment variable

In Railway, set the environment variable for your backend service:

```
DATABASE_URL=postgresql://postgres:<password>@<host>.railway.app:<port>/railway
```

Or in connection-string format for Npgsql (.NET):

```
Host=<host>.railway.app;Port=<port>;Database=railway;Username=postgres;Password=<password>;SSL Mode=Require;Trust Server Certificate=true
```

---

## Migration Workflow (migrations/ folder)

If you need to apply migrations in order:

```bash
# Apply first migration (schema creation)
psql -U postgres -d spin_empire_db -f database/migrations/001_initial.sql

# Check what migrations have been applied:
psql -U postgres -d spin_empire_db -c "SELECT version, description, applied_at FROM migration_log ORDER BY id;"
```

Future migrations should be named `002_*.sql`, `003_*.sql`, etc., and each should:
1. Check `migration_log` before running
2. Wrap DDL in a `BEGIN / COMMIT` block
3. Insert a row into `migration_log` on success

---

## Resetting the Database (local dev only)

To start completely fresh:

```bash
psql -U postgres -c "DROP DATABASE IF EXISTS spin_empire_db;"
psql -U postgres -c "CREATE DATABASE spin_empire_db;"
psql -U postgres -d spin_empire_db -f database/schema.sql
psql -U postgres -d spin_empire_db -f database/seed.sql
```

---

## Test / Admin Account

| Field | Value |
|-------|-------|
| Email | admin@spinempire.com |
| Password | Admin123! |
| Coins | 9,999,999 |
| Spins | 999 |
| Gems | 999 |
| Village Level | 5 |

---

## Schema Summary (23 Tables)

| # | Table | Purpose |
|---|-------|---------|
| 1 | users | Player accounts, wallet, stats |
| 2 | villages | 10 themed village definitions |
| 3 | buildings | 9 buildings per village (90 total) |
| 4 | user_villages | Which villages each player is building |
| 5 | user_buildings | Per-player building upgrade state |
| 6 | spin_results | Full history of every spin |
| 7 | attacks | Attack log (attacker, defender, coins stolen) |
| 8 | raids | Raid log (pig bank digs) |
| 9 | card_sets | 9 card collection sets |
| 10 | cards | 108 collectible cards (4 rarities) |
| 11 | user_cards | Player card inventory |
| 12 | chest_types | 3 chest types with rarity weights |
| 13 | pets | 3 pets (Foxy, Tiger, Rhino) |
| 14 | user_pets | Player pet levels and XP |
| 15 | friendships | Friend list with gift tracking |
| 16 | clans | Clan definitions |
| 17 | clan_members | Clan membership and roles |
| 18 | events | Limited-time events |
| 19 | user_event_progress | Per-player event progress |
| 20 | achievements | 50 achievements across 6 categories |
| 21 | user_achievements | Per-player achievement progress |
| 22 | notifications | In-app push notifications |
| 23 | trade_requests | Card trading between players |
