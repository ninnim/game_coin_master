# COIN MASTER CLONE — COMPLETE GAME PLAN

## Project: "Spin Empire" (Coin Master Clone — Enhanced Edition)
**Folder:** `d:/coin_master_clone/`
**Date:** 2026-04-16

---

## Technology Stack Decision

| Layer | Technology | Reason |
|-------|-----------|--------|
| **Game Engine** | Flutter + Flame 1.x | Best 2D mobile game engine for Flutter, smooth 60fps, sprite support |
| **State Management** | Riverpod | Reactive, testable, production-grade |
| **Animations** | Flutter Animate + Flame particles | Both UI tween animations + game particle effects |
| **Audio** | Flame Audio (flame_audio) | Game-aware audio with positional sound, loops, SFX |
| **Backend** | C# ASP.NET Core 8 + SignalR | Real-time attacks/raids, same ecosystem as TimeCapsule |
| **Database Local** | PostgreSQL 16 (localhost:5432) | Existing infrastructure |
| **Database Cloud** | Railway PostgreSQL | Cloud deployment |
| **Real-time** | SignalR WebSocket Hub | Live attacks, raids, chat |
| **Cache** | In-memory cache (IMemoryCache) | Leaderboard, session data |
| **Auth** | JWT Bearer + BCrypt | Same as TimeCapsule |

---

## All Coin Master Features (Enhanced)

### Core Mechanics
1. **Slot Machine** — 5 symbols: Coin, Attack, Raid, Shield, Energy (jackpot: 3 matching)
2. **Spin System** — 50 max spins, refill 5/hour; buy spins with real currency (IAP mock)
3. **Bet Multiplier** — 1x / 2x / 3x / 5x / 10x (multiplies all coin/reward gains)
4. **Village Building** — 9 buildings per village, 350+ themed villages, upgrade 4 levels each
5. **Attack System** — Spend Attack spin → pick enemy village → destroy 1 building → steal coins
6. **Raid System** — Spend Raid spin → dig up to 3 holes in enemy pig bank → steal coins
7. **Shield System** — Block 1 attack; max 3 shields at once
8. **Pig Bank** — Passive coins accumulate here (attackable by others)
9. **Pet System** — 3 pets: Foxy (extra raid holes), Tiger (coin bonus on attack), Rhino (shield chance)
10. **Pet XP & Levels** — Feed pets with treats to level up; higher level = stronger bonus
11. **Card Collection** — 9 card sets × ~12 cards each = ~108 cards total; collect all for star rewards
12. **Chest System** — Wooden, Golden, Magical chests; buy with coins; random cards inside
13. **Card Trading** — Trade duplicate cards with friends
14. **Village Map** — World map showing village progression with themed environments
15. **Leaderboard** — Weekly top players by coins, by village level, by cards collected
16. **Friends System** — Add friends, gift spins (1/day), attack friends, send cards
17. **Daily Bonus** — Login streak: Day 1=25 spins, Day 3=50 spins, Day 7=rare card
18. **Events** — 4 rotating event types: Viking Quest, Gold Rush, Attack Madness, Raid Madness
19. **Boom Villages** — Special "Boom" villages with 2× building cost + 2× rewards
20. **Clan/Team System** — Create/join clans, clan leaderboard, clan chest contributions
21. **Tournament** — Weekly spin tournament; top 100 win prizes
22. **Chat** — Global chat + clan chat
23. **Profile** — Avatar, village level badge, card stars, achievement medals
24. **Notifications** — "You were attacked!", "Trade request", "Friend joined"
25. **Revenge System** — Counter-attack someone who attacked you (24h window)

### Enhanced Features (Better Than Coin Master)
- **3D-style characters** with animated idle/attack/celebrate states
- **Dynamic weather** in villages (rain, fog, sunrise effects)
- **Combo multiplier** — land 2 raids in a row = combo bonus
- **Seasonal themes** — village skins change per real-world season
- **Achievement system** — 50+ achievements with rewards
- **Spin history** — last 20 spin results shown
- **Battle Pass** — Free tier + Premium tier with weekly missions
- **Clan Wars** — 2 clans compete for 7 days; most spins + villages wins

---

## Database Schema (17 Tables)

### Core Tables
1. **users** — id, email, password_hash, display_name, avatar_url, coins, spins, gems, village_level, pig_bank_coins, shield_count, total_stars, created_at
2. **villages** — id, name, theme, order_num, is_boom, background_image, music_track
3. **buildings** — id, village_id, name, image_url, position_x, position_y, upgrade_cost[], description
4. **user_villages** — id, user_id, village_id, is_completed, started_at, completed_at
5. **user_buildings** — id, user_id, building_id, upgrade_level (0-4), is_destroyed, coins_spent
6. **spin_results** — id, user_id, result_type, result_count, bet_multiplier, coins_earned, created_at
7. **attacks** — id, attacker_id, defender_id, building_id, coins_stolen, was_blocked_by_shield, created_at
8. **raids** — id, raider_id, victim_id, holes_dug, coins_stolen, pet_bonus, created_at
9. **cards** — id, set_name, card_name, rarity (common/rare/epic/legendary), image_url
10. **user_cards** — id, user_id, card_id, quantity, obtained_at
11. **chest_types** — id, name, price_coins, card_count_min, card_count_max, rarity_weights_json
12. **pets** — id, name, ability_description, image_url, max_level
13. **user_pets** — id, user_id, pet_id, level, xp, is_active, treats_fed
14. **friendships** — id, user_id, friend_id, status, spins_gifted_today, created_at
15. **clans** — id, name, leader_id, description, is_public, total_points, created_at
16. **clan_members** — id, clan_id, user_id, role, points_contributed, joined_at
17. **events** — id, type, title, starts_at, ends_at, reward_json, is_active
18. **achievements** — id, key, title, description, reward_coins, reward_spins, icon_url
19. **user_achievements** — id, user_id, achievement_id, unlocked_at
20. **notifications** — id, user_id, type, message, is_read, data_json, created_at
21. **trade_requests** — id, sender_id, receiver_id, offered_card_id, requested_card_id, status, created_at
22. **battle_pass** — id, user_id, season, tier, is_premium, missions_completed_json, created_at

---

## API Endpoints (Backend)

### Auth
- `POST /api/auth/register` → `{ email, password, displayName }`
- `POST /api/auth/login` → `{ email, password }`
- `GET /api/auth/me`

### Game Core
- `POST /api/spin` → `{ betMultiplier }` → `{ results[], coinsEarned, spinsLeft, specialAction? }`
- `GET /api/player/state` → Full player state (coins, spins, village, shields, pets)
- `POST /api/attack` → `{ targetUserId, betMultiplier }` → attack result
- `POST /api/raid` → `{ targetUserId, holePositions[] }` → raid result
- `POST /api/build` → `{ buildingId }` → build/upgrade result

### Villages & Buildings
- `GET /api/villages` → All villages with user progress
- `GET /api/villages/{id}/buildings` → Buildings for village with user state
- `POST /api/buildings/{id}/upgrade` → Upgrade building

### Cards & Chests
- `GET /api/cards` → User's card collection
- `POST /api/chests/open` → `{ chestTypeId, quantity }` → cards received
- `POST /api/trades` → `{ receiverId, offeredCardId, requestedCardId }`
- `PUT /api/trades/{id}/respond` → `{ accept: bool }`

### Pets
- `GET /api/pets` → User's pets + stats
- `POST /api/pets/{id}/activate` → Set active pet
- `POST /api/pets/{id}/feed` → `{ treats }` → pet level up?

### Social
- `GET /api/friends` → Friend list with online status
- `POST /api/friends/{id}/gift-spin` → Gift 1 spin
- `GET /api/leaderboard?type=coins|village|cards&period=weekly`
- `POST /api/revenge/{attackId}` → Counter-attack

### Clans
- `GET /api/clans` → Public clans list
- `POST /api/clans` → Create clan
- `POST /api/clans/{id}/join`
- `GET /api/clans/{id}` → Clan with members + war status

### Events & Achievements
- `GET /api/events/active` → Current active events
- `GET /api/achievements` → All + user progress

### SignalR Hub: `/hubs/game`
- `OnAttacked(attackData)` — Real-time attack notification
- `OnRaided(raidData)` — Real-time raid notification
- `OnSpinGifted(fromUser)` — Spin gift notification
- `OnTradeRequest(tradeData)` — Trade request notification
- `OnFriendOnline(userId)` — Friend online status

---

## Frontend Flutter Structure

```
coin_master_flutter/
├── lib/
│   ├── main.dart
│   ├── game/
│   │   ├── coin_master_game.dart        # Flame Game root
│   │   ├── components/
│   │   │   ├── slot_machine.dart        # Slot machine component
│   │   │   ├── slot_reel.dart           # Individual reel
│   │   │   ├── village_scene.dart       # Village world
│   │   │   ├── building_component.dart  # Clickable building
│   │   │   ├── pet_companion.dart       # Animated pet
│   │   │   ├── particle_effects.dart    # Confetti, coins flying
│   │   │   ├── attack_animation.dart    # Hammer/cannon attack
│   │   │   └── raid_animation.dart      # Dig holes animation
│   │   ├── overlays/
│   │   │   ├── hud_overlay.dart         # Coins, spins, shields HUD
│   │   │   ├── spin_result_overlay.dart
│   │   │   ├── attack_overlay.dart
│   │   │   └── raid_overlay.dart
│   │   └── audio/
│   │       ├── audio_manager.dart
│   │       └── sound_ids.dart
│   ├── features/
│   │   ├── auth/                        # Login/Register screens
│   │   ├── village/                     # Village map, building screens
│   │   ├── cards/                       # Card collection, trading
│   │   ├── pets/                        # Pet management
│   │   ├── social/                      # Friends, clans, leaderboard
│   │   ├── events/                      # Events calendar
│   │   ├── achievements/                # Achievement gallery
│   │   ├── shop/                        # Chests, gems, spins
│   │   └── profile/                     # User profile
│   ├── core/
│   │   ├── api/                         # HTTP + SignalR client
│   │   ├── providers/                   # Riverpod providers
│   │   ├── models/                      # Data models
│   │   └── theme/                       # Colors, fonts, sprites
│   └── shared/
│       ├── widgets/                     # GlassCard, GlassButton, etc.
│       └── animations/                  # Shared animation utilities
├── assets/
│   ├── images/                          # Sprites, backgrounds, UI
│   ├── audio/                           # SFX, music tracks
│   ├── fonts/                           # Custom game font
│   └── data/                            # Village JSON configs
└── pubspec.yaml
```

---

## Agent Team Assignments

### Agent 1: Database Agent
**Files:** `d:/coin_master_clone/database/`
- Create `schema.sql` with all 22 tables + indexes + triggers
- Create `railway_config.sql` with Railway-compatible setup
- Create seed data: 10 villages, 108 cards, 3 pets, 50 achievements
- Create `migrations/` folder

### Agent 2: Backend Agent  
**Files:** `d:/coin_master_clone/backend/`
- ASP.NET Core 8 Web API project "CoinMaster.API"
- All controllers, services, models, DTOs
- Spin logic engine (weighted random slots)
- Attack/Raid game mechanics
- SignalR GameHub
- Dual DB config (local + railway via env)

### Agent 3: Frontend Agent
**Files:** `d:/coin_master_clone/frontend/`
- Flutter + Flame project "coin_master_flutter"
- Slot machine with physics-based reel animation
- Village building system with tap interactions
- Attack/Raid animated sequences
- Full audio integration
- All screens listed above

---

## Design Theme: "Cosmic Viking Empire"

### Color Palette
```
background:    #0A0A1A  (deep cosmos black)
surface:       #1A1030  (dark purple surface)
gold:          #FFD700  (primary currency — coins, spin button)
goldLight:     #FFF176  (shine/highlight on gold)
purple:        #6A1B9A  (deep royal purple)
purpleLight:   #CE93D8  (light purple accents)
emerald:       #00C853  (success, shields, village complete)
crimson:       #D50000  (attacks, danger, health loss)
cyan:          #00E5FF  (special, magic effects)
woodBrown:     #8D6E63  (building materials, chests)
skyBlue:       #1565C0  (village sky background)
```

### Fonts
- **Headers:** "MedievalSharp" or "Cinzel Decorative" (Viking/medieval feel)
- **Numbers:** "Digital-7" or "Press Start 2P" (game-style number display)
- **Body:** System font / Roboto

### Sound Design
- **Slot spin start:** mechanical reel whir (ascending pitch)
- **Slot each stop:** satisfying "clunk" with icon flash
- **Jackpot:** fanfare + coin shower sound
- **Coins collected:** satisfying coin "ding ding ding"
- **Attack:** dramatic cannon boom + building crumble
- **Raid:** suspenseful dig music + gold discovery "ching"
- **Shield block:** metal clang + shield glow
- **Level up village:** triumphant medieval fanfare
- **Pet activate:** animal sound + magic shimmer
- **Card obtained:** mystical reveal chime
- **Background music:** 3 tracks — Village peace, Slot tension, Victory fanfare

---

## Railway Database Connection

Railway URL format:
```
postgresql://postgres:{PASSWORD}@{HOST}.railway.app:{PORT}/{DB_NAME}
```

The backend will use environment variable `DATABASE_URL` for Railway,
falling back to local PostgreSQL via `appsettings.Development.json`.

---

## Project Timeline (Agent Execution Order)

1. **Phase 1 — Database** (Agent 1): Create all schemas, seed data
2. **Phase 2 — Backend** (Agent 2): API + SignalR (depends on DB schema)
3. **Phase 3 — Frontend** (Agent 3): Flutter game (depends on API contract)
4. **Phase 4 — Integration**: Connect all three, test spin/attack/raid flows
