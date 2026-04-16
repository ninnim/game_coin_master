# Spin Empire — Coin Master Clone

## Overview
A full Coin Master clone game with enhanced UI, sound, effects, and characters.

## Tech Stack
- **Database:** PostgreSQL 16 (local: spin_empire_db / Railway cloud)
- **Backend:** C# ASP.NET Core 8 Web API + EF Core + SignalR + Npgsql
- **Frontend:** Flutter + Flame game engine + Riverpod + go_router
- **Auth:** JWT Bearer tokens + BCrypt

## Folder Ownership
| Folder | Contents |
|--------|----------|
| `database/` | PostgreSQL schema, seed data, migrations |
| `backend/` | C# ASP.NET Core 8 API |
| `frontend/` | Flutter + Flame game |
| `prompts/` | Agent team prompts (reference only) |

## Test Accounts
| Email | Password | Role |
|-------|----------|------|
| admin@spinempire.com | Admin123! | Admin (999M coins, 9.9M spins, 100K gems) |
| master@spinempire.com | Master123! | Master Tester (999M coins, 9.9M spins, 100K gems) |

## Database Credentials (Local)
- Host: localhost:5432
- Database: spin_empire_db
- User: postgres
- Password: TimeCapsule2026!

## Quick Start
```bash
# 1. Database
psql -U postgres -c "CREATE DATABASE spin_empire_db;"
psql -U postgres -d spin_empire_db -f database/schema.sql
psql -U postgres -d spin_empire_db -f database/seed.sql

# 2. Backend
cd backend/CoinMaster.API && dotnet run

# 3. Frontend
cd frontend/coin_master_flutter && flutter pub get && flutter run
```
