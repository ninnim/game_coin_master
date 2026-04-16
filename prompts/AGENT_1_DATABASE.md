# AGENT 1 — DATABASE AGENT
## Mission: Create all database schemas for Spin Empire (Coin Master Clone)

You are the **Database Agent** for "Spin Empire" — a Coin Master clone game.
Your ONLY job is to create ALL database files in `d:/coin_master_clone/database/`.
Do NOT touch any other folder.

---

## Your Deliverables

### File 1: `d:/coin_master_clone/database/schema.sql`
Full PostgreSQL schema with ALL 22 tables below. Include:
- `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`
- All tables with UUID primary keys using `DEFAULT uuid_generate_v4()`
- All foreign keys with proper ON DELETE behavior
- Indexes on all FK columns + frequently queried columns
- CHECK constraints where specified
- DEFAULT values

### File 2: `d:/coin_master_clone/database/seed.sql`
Seed data including:
- 10 themed villages (Medieval, Viking, Egypt, Space, Ocean, Jungle, Ice, Desert, Fantasy, Future)
- 9 buildings per village (90 total buildings with positions)
- 3 pets (Foxy, Tiger, Rhino) with stats
- 108 cards organized in 9 sets (12 cards each) with 4 rarities
- 3 chest types (Wooden, Golden, Magical)
- 50 achievements with rewards
- 4 event types configured
- Admin/test user account

### File 3: `d:/coin_master_clone/database/railway_migration.sql`
Same as schema.sql but with Railway-specific settings:
- Connection pool settings optimized for Railway
- `SET statement_timeout = '30s';`
- All tables prefixed with comments showing which feature they support
- Include rollback-safe IF NOT EXISTS on all creates

### File 4: `d:/coin_master_clone/database/migrations/001_initial.sql`
Migration wrapper around schema.sql with:
- migration_log table to track applied migrations
- Up/down migration sections

### File 5: `d:/coin_master_clone/database/README.md`
Document:
- How to run locally (psql command)
- How to run on Railway (copy-paste instructions)
- Connection string format for both environments
- All table descriptions in one paragraph each

---

## Complete Table Definitions

### 1. users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  avatar_url VARCHAR(500),
  coins BIGINT NOT NULL DEFAULT 500,
  spins INT NOT NULL DEFAULT 50,
  gems INT NOT NULL DEFAULT 10,
  village_level INT NOT NULL DEFAULT 1,
  pig_bank_coins BIGINT NOT NULL DEFAULT 0,
  shield_count INT NOT NULL DEFAULT 0 CHECK (shield_count >= 0 AND shield_count <= 3),
  total_stars INT NOT NULL DEFAULT 0,
  spin_refill_at TIMESTAMP NOT NULL DEFAULT NOW(),
  bet_multiplier INT NOT NULL DEFAULT 1 CHECK (bet_multiplier IN (1,2,3,5,10)),
  active_pet_id UUID,
  last_login_at TIMESTAMP,
  login_streak INT NOT NULL DEFAULT 0,
  weekly_spins_used INT NOT NULL DEFAULT 0,
  total_attacks INT NOT NULL DEFAULT 0,
  total_raids INT NOT NULL DEFAULT 0,
  total_cards INT NOT NULL DEFAULT 0,
  is_banned BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 2. villages
```sql
CREATE TABLE villages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(150) NOT NULL,
  theme VARCHAR(50) NOT NULL, -- 'medieval','viking','egypt','space','ocean','jungle','ice','desert','fantasy','future'
  order_num INT UNIQUE NOT NULL,
  is_boom BOOLEAN NOT NULL DEFAULT FALSE, -- boom villages cost 2x but reward 2x
  background_image VARCHAR(255),
  music_track VARCHAR(255),
  sky_color VARCHAR(20) NOT NULL DEFAULT '#1565C0',
  total_build_cost BIGINT NOT NULL DEFAULT 0, -- pre-calculated sum
  description TEXT
);
```

### 3. buildings
```sql
CREATE TABLE buildings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  village_id UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
  name VARCHAR(150) NOT NULL,
  image_base VARCHAR(255) NOT NULL, -- e.g. 'medieval_castle' -> medieval_castle_1.png ... _4.png
  position_x DECIMAL(5,2) NOT NULL, -- % from left 0-100
  position_y DECIMAL(5,2) NOT NULL, -- % from top 0-100
  upgrade_costs BIGINT[] NOT NULL, -- array of 4 costs [lvl1,lvl2,lvl3,lvl4]
  description VARCHAR(500),
  building_order INT NOT NULL DEFAULT 0
);
```

### 4. user_villages
```sql
CREATE TABLE user_villages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  village_id UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  started_at TIMESTAMP NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMP,
  UNIQUE(user_id, village_id)
);
```

### 5. user_buildings
```sql
CREATE TABLE user_buildings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  upgrade_level INT NOT NULL DEFAULT 0 CHECK (upgrade_level >= 0 AND upgrade_level <= 4),
  is_destroyed BOOLEAN NOT NULL DEFAULT FALSE,
  destroyed_by UUID REFERENCES users(id),
  destroyed_at TIMESTAMP,
  coins_spent BIGINT NOT NULL DEFAULT 0,
  UNIQUE(user_id, building_id)
);
```

### 6. spin_results
```sql
CREATE TABLE spin_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  slot1 VARCHAR(20) NOT NULL, -- 'coin','attack','raid','shield','energy','jackpot'
  slot2 VARCHAR(20) NOT NULL,
  slot3 VARCHAR(20) NOT NULL,
  result_type VARCHAR(30) NOT NULL, -- 'coin_small','coin_medium','coin_large','attack','raid','shield','energy','jackpot'
  coins_earned BIGINT NOT NULL DEFAULT 0,
  spins_earned INT NOT NULL DEFAULT 0,
  bet_multiplier INT NOT NULL DEFAULT 1,
  pet_bonus_applied BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_spin_results_user_id ON spin_results(user_id);
CREATE INDEX idx_spin_results_created_at ON spin_results(created_at DESC);
```

### 7. attacks
```sql
CREATE TABLE attacks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attacker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  defender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  building_id UUID REFERENCES buildings(id),
  coins_stolen BIGINT NOT NULL DEFAULT 0,
  was_blocked_by_shield BOOLEAN NOT NULL DEFAULT FALSE,
  was_revenged BOOLEAN NOT NULL DEFAULT FALSE,
  revenge_deadline TIMESTAMP,
  bet_multiplier INT NOT NULL DEFAULT 1,
  pet_bonus DECIMAL(5,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_attacks_attacker ON attacks(attacker_id);
CREATE INDEX idx_attacks_defender ON attacks(defender_id);
CREATE INDEX idx_attacks_created_at ON attacks(created_at DESC);
```

### 8. raids
```sql
CREATE TABLE raids (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  raider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  victim_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  holes_dug INT NOT NULL DEFAULT 3 CHECK (holes_dug BETWEEN 1 AND 4),
  holes_positions INT[] NOT NULL, -- array of position indexes [0-8]
  coins_stolen BIGINT NOT NULL DEFAULT 0,
  bet_multiplier INT NOT NULL DEFAULT 1,
  pet_bonus_extra_hole BOOLEAN NOT NULL DEFAULT FALSE, -- Foxy pet
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_raids_raider ON raids(raider_id);
CREATE INDEX idx_raids_victim ON raids(victim_id);
```

### 9. card_sets
```sql
CREATE TABLE card_sets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  theme VARCHAR(100) NOT NULL,
  image_url VARCHAR(255),
  reward_coins BIGINT NOT NULL DEFAULT 0,
  reward_spins INT NOT NULL DEFAULT 0,
  reward_gems INT NOT NULL DEFAULT 0
);
```

### 10. cards
```sql
CREATE TABLE cards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  set_id UUID NOT NULL REFERENCES card_sets(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(500),
  rarity VARCHAR(20) NOT NULL CHECK (rarity IN ('common','rare','epic','legendary')),
  image_url VARCHAR(255),
  card_order INT NOT NULL DEFAULT 0
);
CREATE INDEX idx_cards_set_id ON cards(set_id);
CREATE INDEX idx_cards_rarity ON cards(rarity);
```

### 11. user_cards
```sql
CREATE TABLE user_cards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity >= 0),
  first_obtained_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, card_id)
);
CREATE INDEX idx_user_cards_user_id ON user_cards(user_id);
```

### 12. chest_types
```sql
CREATE TABLE chest_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL, -- 'wooden','golden','magical'
  price_coins BIGINT NOT NULL,
  card_count_min INT NOT NULL DEFAULT 1,
  card_count_max INT NOT NULL DEFAULT 3,
  rarity_weights JSONB NOT NULL, -- {"common":60,"rare":30,"epic":8,"legendary":2}
  image_url VARCHAR(255)
);
```

### 13. pets
```sql
CREATE TABLE pets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL, -- 'Foxy','Tiger','Rhino'
  ability_type VARCHAR(50) NOT NULL, -- 'extra_raid_hole','attack_coin_bonus','shield_chance'
  ability_description VARCHAR(255) NOT NULL,
  image_url VARCHAR(255),
  max_level INT NOT NULL DEFAULT 20,
  treats_per_level INT NOT NULL DEFAULT 10
);
```

### 14. user_pets
```sql
CREATE TABLE user_pets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  level INT NOT NULL DEFAULT 1,
  xp INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  treats_fed INT NOT NULL DEFAULT 0,
  UNIQUE(user_id, pet_id)
);
```

### 15. friendships
```sql
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','blocked')),
  spins_gifted_today INT NOT NULL DEFAULT 0,
  spins_gifted_reset_at TIMESTAMP NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);
```

### 16. clans
```sql
CREATE TABLE clans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) UNIQUE NOT NULL,
  leader_id UUID NOT NULL REFERENCES users(id),
  description TEXT,
  badge_image VARCHAR(255),
  is_public BOOLEAN NOT NULL DEFAULT TRUE,
  total_points BIGINT NOT NULL DEFAULT 0,
  member_count INT NOT NULL DEFAULT 1,
  min_village_level INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### 17. clan_members
```sql
CREATE TABLE clan_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  clan_id UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'member' CHECK (role IN ('leader','elder','member')),
  points_contributed BIGINT NOT NULL DEFAULT 0,
  weekly_spins INT NOT NULL DEFAULT 0,
  joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(clan_id, user_id)
);
```

### 18. events
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type VARCHAR(50) NOT NULL, -- 'viking_quest','gold_rush','attack_madness','raid_madness','card_boom'
  title VARCHAR(150) NOT NULL,
  description TEXT,
  banner_image VARCHAR(255),
  starts_at TIMESTAMP NOT NULL,
  ends_at TIMESTAMP NOT NULL,
  reward_json JSONB NOT NULL, -- {"type":"spins","amount":100}
  rules_json JSONB, -- event-specific rules
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);
```

### 19. user_event_progress
```sql
CREATE TABLE user_event_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  progress INT NOT NULL DEFAULT 0,
  is_claimed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);
```

### 20. achievements
```sql
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key VARCHAR(100) UNIQUE NOT NULL,
  title VARCHAR(150) NOT NULL,
  description VARCHAR(500) NOT NULL,
  icon_url VARCHAR(255),
  category VARCHAR(50) NOT NULL, -- 'spinning','attacking','raiding','building','social','collection'
  target_value INT NOT NULL DEFAULT 1,
  reward_coins BIGINT NOT NULL DEFAULT 0,
  reward_spins INT NOT NULL DEFAULT 0,
  reward_gems INT NOT NULL DEFAULT 0,
  display_order INT NOT NULL DEFAULT 0
);
```

### 21. user_achievements
```sql
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  current_value INT NOT NULL DEFAULT 0,
  is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
  is_claimed BOOLEAN NOT NULL DEFAULT FALSE,
  unlocked_at TIMESTAMP,
  UNIQUE(user_id, achievement_id)
);
```

### 22. notifications
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- 'attacked','raided','spin_gifted','trade_request','friend_request','event_start','achievement'
  title VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  data_json JSONB, -- attacker info, trade details, etc.
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);
```

### 23. trade_requests
```sql
CREATE TABLE trade_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  offered_card_id UUID NOT NULL REFERENCES cards(id),
  requested_card_id UUID NOT NULL REFERENCES cards(id),
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected','expired')),
  expires_at TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '48 hours'),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

---

## Seed Data Requirements

### Villages (10 entries in order)
1. Medieval Kingdom — castle, blacksmith, tower, tavern, well, farm, mill, church, market
2. Viking Village — longhouse, shipyard, forge, mead hall, rune stone, dock, barn, temple, watchtower
3. Ancient Egypt — pyramid, sphinx, obelisk, bazaar, palace, temple, granary, chariot stable, tomb
4. Outer Space — launch pad, control center, satellite dish, rover garage, biodome, observatory, fuel depot, alien embassy, space bar
5. Deep Ocean — coral castle, treasure ship, lighthouse, submarine bay, pearl market, kelp farm, shark cage, mermaid grotto, abyssal lab
6. Jungle Temple — great temple, tribal hut, totem pole, shaman hut, bridge, watchtower, boat dock, trading post, fire pit
7. Frozen North — ice palace, igloo village, dog sled station, frozen forge, crystal cave, fishing hole, frost tower, winter market, aurora shrine
8. Desert Oasis — sultan palace, camel stable, bazaar, water tower, sand fortress, caravan post, oasis pool, mirage shrine, dune racer
9. Fantasy Realm — wizard tower, dragon lair, fairy garden, magic forge, enchanted forest, crystal ball shop, potion brewery, griffin stable, portal gate
10. Cyber Future — server tower, drone hub, neon arcade, hologram studio, robot factory, cyber café, energy grid, AI lab, quantum core

### Building costs per village (upgrade_costs array [lvl1, lvl2, lvl3, lvl4]):
- Village 1 (Medieval): [10000, 25000, 60000, 150000]
- Village 2 (Viking): [25000, 60000, 150000, 375000]
- Village 3 (Egypt): [60000, 150000, 375000, 900000]
- Each subsequent village: multiply by ~2.5
- Boom villages (village 5, 10): multiply entire cost by 2

### Card Sets (9 sets, 12 cards each)
- Set 1: "Ancient Warriors" (medieval theme)
- Set 2: "Norse Gods" (viking theme)
- Set 3: "Pharaohs" (egypt theme)
- Set 4: "Star Explorers" (space theme)
- Set 5: "Ocean Legends" (ocean theme)
- Set 6: "Jungle Kings" (jungle theme)
- Set 7: "Frost Giants" (ice theme)
- Set 8: "Desert Raiders" (desert theme)
- Set 9: "Dragon Masters" (fantasy theme)

Each set: 6 common, 3 rare, 2 epic, 1 legendary card

### Chest Types
- Wooden Chest: 1,500 coins, 1-2 cards, weights: common=80, rare=18, epic=2, legendary=0
- Golden Chest: 4,500 coins, 2-4 cards, weights: common=50, rare=35, epic=13, legendary=2
- Magical Chest: 15,000 coins, 4-6 cards, weights: common=20, rare=40, epic=30, legendary=10

### Pets
- Foxy: ability=extra_raid_hole, level bonuses add 0-10% per level (at lvl20: +4th dig hole)
- Tiger: ability=attack_coin_bonus, base +10% per level (at lvl20: +200% attack coins)
- Rhino: ability=shield_chance, base 5% per level (at lvl20: 100% shield on attack)

### Sample Achievements (50 total, include at least these)
Spinning: first_spin, spin_100, spin_1000, spin_10000, jackpot_first, jackpot_10
Attacking: first_attack, attack_10, attack_100, attack_1000
Raiding: first_raid, raid_10, raid_100, perfect_raid (3 full holes)
Building: first_build, first_village_complete, village_5_complete, village_10_complete
Social: first_friend, friend_10, first_clan, first_gift
Collection: first_card, set_complete_1, all_sets_complete

---

## Local PostgreSQL Config
- Host: localhost
- Port: 5432
- Database: spin_empire_db
- Username: postgres
- Password: TimeCapsule2026! (same as TimeCapsule project)

## Railway Config
Create schema for Railway environment:
- Use environment variable DATABASE_URL for connection
- Railway PostgreSQL URL format: `postgresql://postgres:{pass}@{host}.railway.app:{port}/railway`
- The railway_migration.sql should be safe to run multiple times (idempotent with IF NOT EXISTS)

---

## IMPORTANT RULES
- Use BIGINT for all coin amounts (they get very large in Coin Master-like games)
- All timestamps in UTC
- Use UUID for all primary keys
- Every foreign key must have an index
- Include JSONB for flexible game data (event rules, rarity weights, notification data)
- Array types (BIGINT[], INT[]) are used for upgrade_costs and hole_positions
- Run: `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";` at the top

Start immediately. Create all 5 files. Be thorough and complete — do not skip any table or seed data.
