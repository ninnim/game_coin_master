# MASTER ORCHESTRATOR PROMPT
## Project: Spin Empire — Coin Master Clone

Copy this prompt to Claude Code / Claude Agent SDK to kick off the full implementation.

---

## BRIEFING

You are leading the development of "Spin Empire" — a full Coin Master clone game
with BETTER UI, BETTER sound effects, BETTER particle effects, and BETTER characters.

The project lives at: `d:/coin_master_clone/`

You have 3 specialized agents to deploy. Run them in the correct order:

---

## STEP 1 — Deploy Database Agent

Read the full prompt from:
`d:/coin_master_clone/prompts/AGENT_1_DATABASE.md`

The Database Agent must create:
- `d:/coin_master_clone/database/schema.sql` — all 22 tables
- `d:/coin_master_clone/database/seed.sql` — villages, cards, pets, achievements
- `d:/coin_master_clone/database/railway_migration.sql` — Railway-safe version
- `d:/coin_master_clone/database/migrations/001_initial.sql`
- `d:/coin_master_clone/database/README.md`

**Verify before proceeding to Step 2:**
- All 22 tables present in schema.sql
- 10 villages in seed.sql
- 108 cards (9 sets × 12 cards) in seed.sql
- 3 pets seeded
- 50 achievements seeded

---

## STEP 2 — Deploy Backend Agent

Read the full prompt from:
`d:/coin_master_clone/prompts/AGENT_2_BACKEND.md`

The Backend Agent must create:
- `d:/coin_master_clone/backend/CoinMaster.API/` — full C# project
- All controllers, services, models, DTOs
- SignalR GameHub
- Dockerfile
- Both appsettings.json files (local + railway env var)

**Verify before proceeding to Step 3:**
- `dotnet build` succeeds
- SpinService, AttackService, RaidService, BuildingService all implemented
- GameHub SignalR implemented
- All controllers have CRUD routes matching API contract

---

## STEP 3 — Deploy Frontend Agent

Read the full prompt from:
`d:/coin_master_clone/prompts/AGENT_3_FRONTEND.md`

The Frontend Agent must create:
- `d:/coin_master_clone/frontend/coin_master_flutter/` — full Flutter project
- Flame game engine with slot machine reels
- Village scene with buildings
- All screens (auth, game, cards, pets, social, events, achievements, profile)
- Audio manager
- SignalR integration

**Verify before declaring complete:**
- `flutter pub get` succeeds
- No compile errors on `flutter analyze`
- MainGameScreen renders the Flame game widget
- SlotMachineComponent has working reel animation
- All API providers use the correct endpoint URLs

---

## INTEGRATION NOTES

### Local Development
1. Start PostgreSQL and run: `psql -U postgres -d spin_empire_db -f schema.sql && psql -U postgres -d spin_empire_db -f seed.sql`
2. Start backend: `cd backend/CoinMaster.API && dotnet run`
3. Start frontend: `cd frontend/coin_master_flutter && flutter run`

### Railway Deployment
1. Push backend Dockerfile to Railway
2. Add Railway PostgreSQL plugin
3. Run `railway_migration.sql` in Railway's pgAdmin
4. Set env vars: `DATABASE_URL`, `JWT_SECRET`

### API Base URL
- Android emulator: `http://10.0.2.2:5001`
- iOS simulator: `http://localhost:5001`
- Real device (same WiFi): `http://[HOST_COMPUTER_IP]:5001`
- Production Railway: `https://[your-app].railway.app`

---

## QUALITY CHECKLIST

### Game Feel (Priority 1)
- [ ] Slot machine reels have smooth deceleration physics
- [ ] Reel stop sounds are satisfying and staggered
- [ ] Jackpot creates a "wow" moment (full screen effects + audio)
- [ ] Coin counter animates up (number ticker) when coins are earned
- [ ] Building tap gives immediate visual feedback
- [ ] Attack animation is dramatic and punchy
- [ ] Raid digging feels interactive and fun

### UI Polish (Priority 2)
- [ ] All screens have the dark space theme (#0A0A1A background)
- [ ] Gold color used consistently for coins/rewards
- [ ] Purple used for premium/special elements
- [ ] Glass card effect on all popup overlays
- [ ] Bottom navigation has active state highlight
- [ ] Loading states use skeleton shimmers, not spinners
- [ ] Empty states have illustration + encouraging text + action button

### Functionality (Priority 3)
- [ ] JWT auth persists across app restarts
- [ ] Spin refill timer shows countdown when out of spins
- [ ] Shield count visible in HUD
- [ ] Active pet shown in game UI
- [ ] Notifications received in real-time via SignalR
- [ ] Leaderboard updates weekly (backend scheduled job)

---

## BEYOND COIN MASTER — UNIQUE ENHANCEMENTS

These features make Spin Empire BETTER than Coin Master:

1. **Spin History Log** — Swipe up from spin area to see last 20 results with timestamps
2. **Combo System** — 2 raids in a row = 1.5x coins bonus; 3 in a row = 2x
3. **Village Weather** — Each village has animated weather (rain, snow, sun rays, stars)
4. **Building Lore** — Tap any built structure to read its story/description
5. **Achievement Toasts** — When achievement unlocks, dramatic reveal animation from top
6. **Card Foil Effect** — Legendary cards have animated holographic foil shader
7. **Battle Pass UI** — Weekly mission progress bar in profile with milestone rewards
8. **Spin Prediction Mode** — After 10 spins, show probability stats (transparency feature)
9. **Sound Customizer** — Let players adjust SFX volume, music volume, and choose music style
10. **Accessibility** — High contrast mode, larger text option, colorblind mode for rarity indicators
