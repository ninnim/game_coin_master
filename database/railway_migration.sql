-- =============================================================
-- Spin Empire — Railway Migration (Idempotent)
-- Safe to run multiple times. Uses CREATE TABLE IF NOT EXISTS.
-- =============================================================

SET statement_timeout = '30s';

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================
-- Feature: Authentication & User Profiles
-- TABLE: users
-- =============================================================
CREATE TABLE IF NOT EXISTS users (
  id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  email             VARCHAR(255) UNIQUE NOT NULL,
  password_hash     VARCHAR(255) NOT NULL,
  display_name      VARCHAR(100) NOT NULL,
  avatar_url        VARCHAR(500),
  coins             BIGINT      NOT NULL DEFAULT 500,
  spins             INT         NOT NULL DEFAULT 50,
  gems              INT         NOT NULL DEFAULT 10,
  village_level     INT         NOT NULL DEFAULT 1,
  pig_bank_coins    BIGINT      NOT NULL DEFAULT 0,
  shield_count      INT         NOT NULL DEFAULT 0 CHECK (shield_count >= 0 AND shield_count <= 3),
  total_stars       INT         NOT NULL DEFAULT 0,
  spin_refill_at    TIMESTAMP   NOT NULL DEFAULT NOW(),
  bet_multiplier    INT         NOT NULL DEFAULT 1 CHECK (bet_multiplier IN (1,2,3,5,10)),
  active_pet_id     UUID,
  last_login_at     TIMESTAMP,
  login_streak      INT         NOT NULL DEFAULT 0,
  weekly_spins_used INT         NOT NULL DEFAULT 0,
  total_attacks     INT         NOT NULL DEFAULT 0,
  total_raids       INT         NOT NULL DEFAULT 0,
  total_cards       INT         NOT NULL DEFAULT 0,
  is_banned         BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email         ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_village_level ON users(village_level);
CREATE INDEX IF NOT EXISTS idx_users_coins         ON users(coins DESC);

-- =============================================================
-- Feature: Village Progression System
-- TABLE: villages
-- =============================================================
CREATE TABLE IF NOT EXISTS villages (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name             VARCHAR(150) NOT NULL,
  theme            VARCHAR(50)  NOT NULL,
  order_num        INT          UNIQUE NOT NULL,
  is_boom          BOOLEAN      NOT NULL DEFAULT FALSE,
  background_image VARCHAR(255),
  music_track      VARCHAR(255),
  sky_color        VARCHAR(20)  NOT NULL DEFAULT '#1565C0',
  total_build_cost BIGINT       NOT NULL DEFAULT 0,
  description      TEXT
);

CREATE INDEX IF NOT EXISTS idx_villages_order_num ON villages(order_num);

-- =============================================================
-- Feature: Village Progression System
-- TABLE: buildings
-- =============================================================
CREATE TABLE IF NOT EXISTS buildings (
  id             UUID           PRIMARY KEY DEFAULT uuid_generate_v4(),
  village_id     UUID           NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
  name           VARCHAR(150)   NOT NULL,
  image_base     VARCHAR(255)   NOT NULL,
  position_x     DECIMAL(5,2)   NOT NULL,
  position_y     DECIMAL(5,2)   NOT NULL,
  upgrade_costs  BIGINT[]       NOT NULL,
  description    VARCHAR(500),
  building_order INT            NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_buildings_village_id ON buildings(village_id);

-- =============================================================
-- Feature: Village Progression System
-- TABLE: user_villages
-- =============================================================
CREATE TABLE IF NOT EXISTS user_villages (
  id           UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  village_id   UUID      NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
  is_completed BOOLEAN   NOT NULL DEFAULT FALSE,
  is_active    BOOLEAN   NOT NULL DEFAULT TRUE,
  started_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMP,
  UNIQUE(user_id, village_id)
);

CREATE INDEX IF NOT EXISTS idx_user_villages_user_id    ON user_villages(user_id);
CREATE INDEX IF NOT EXISTS idx_user_villages_village_id ON user_villages(village_id);

-- =============================================================
-- Feature: Building Upgrades & Attack Damage
-- TABLE: user_buildings
-- =============================================================
CREATE TABLE IF NOT EXISTS user_buildings (
  id            UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  building_id   UUID      NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
  upgrade_level INT       NOT NULL DEFAULT 0 CHECK (upgrade_level >= 0 AND upgrade_level <= 4),
  is_destroyed  BOOLEAN   NOT NULL DEFAULT FALSE,
  destroyed_by  UUID      REFERENCES users(id),
  destroyed_at  TIMESTAMP,
  coins_spent   BIGINT    NOT NULL DEFAULT 0,
  UNIQUE(user_id, building_id)
);

CREATE INDEX IF NOT EXISTS idx_user_buildings_user_id     ON user_buildings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_buildings_building_id ON user_buildings(building_id);

-- =============================================================
-- Feature: Slot Machine / Spin Engine
-- TABLE: spin_results
-- =============================================================
CREATE TABLE IF NOT EXISTS spin_results (
  id                UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  slot1             VARCHAR(20) NOT NULL,
  slot2             VARCHAR(20) NOT NULL,
  slot3             VARCHAR(20) NOT NULL,
  result_type       VARCHAR(30) NOT NULL,
  coins_earned      BIGINT    NOT NULL DEFAULT 0,
  spins_earned      INT       NOT NULL DEFAULT 0,
  bet_multiplier    INT       NOT NULL DEFAULT 1,
  pet_bonus_applied BOOLEAN   NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spin_results_user_id    ON spin_results(user_id);
CREATE INDEX IF NOT EXISTS idx_spin_results_created_at ON spin_results(created_at DESC);

-- =============================================================
-- Feature: Attack System (PvP)
-- TABLE: attacks
-- =============================================================
CREATE TABLE IF NOT EXISTS attacks (
  id                    UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  attacker_id           UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  defender_id           UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  building_id           UUID          REFERENCES buildings(id),
  coins_stolen          BIGINT        NOT NULL DEFAULT 0,
  was_blocked_by_shield BOOLEAN       NOT NULL DEFAULT FALSE,
  was_revenged          BOOLEAN       NOT NULL DEFAULT FALSE,
  revenge_deadline      TIMESTAMP,
  bet_multiplier        INT           NOT NULL DEFAULT 1,
  pet_bonus             DECIMAL(5,2)  NOT NULL DEFAULT 0,
  created_at            TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attacks_attacker   ON attacks(attacker_id);
CREATE INDEX IF NOT EXISTS idx_attacks_defender   ON attacks(defender_id);
CREATE INDEX IF NOT EXISTS idx_attacks_created_at ON attacks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_attacks_building   ON attacks(building_id);

-- =============================================================
-- Feature: Raid System (PvP Pig Bank)
-- TABLE: raids
-- =============================================================
CREATE TABLE IF NOT EXISTS raids (
  id                   UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  raider_id            UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  victim_id            UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  holes_dug            INT       NOT NULL DEFAULT 3 CHECK (holes_dug BETWEEN 1 AND 4),
  holes_positions      INT[]     NOT NULL,
  coins_stolen         BIGINT    NOT NULL DEFAULT 0,
  bet_multiplier       INT       NOT NULL DEFAULT 1,
  pet_bonus_extra_hole BOOLEAN   NOT NULL DEFAULT FALSE,
  created_at           TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_raids_raider     ON raids(raider_id);
CREATE INDEX IF NOT EXISTS idx_raids_victim     ON raids(victim_id);
CREATE INDEX IF NOT EXISTS idx_raids_created_at ON raids(created_at DESC);

-- =============================================================
-- Feature: Card Collection System
-- TABLE: card_sets
-- =============================================================
CREATE TABLE IF NOT EXISTS card_sets (
  id           UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         VARCHAR(100) NOT NULL,
  theme        VARCHAR(100) NOT NULL,
  image_url    VARCHAR(255),
  reward_coins BIGINT       NOT NULL DEFAULT 0,
  reward_spins INT          NOT NULL DEFAULT 0,
  reward_gems  INT          NOT NULL DEFAULT 0
);

-- =============================================================
-- Feature: Card Collection System
-- TABLE: cards
-- =============================================================
CREATE TABLE IF NOT EXISTS cards (
  id          UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  set_id      UUID         NOT NULL REFERENCES card_sets(id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,
  description VARCHAR(500),
  rarity      VARCHAR(20)  NOT NULL CHECK (rarity IN ('common','rare','epic','legendary')),
  image_url   VARCHAR(255),
  card_order  INT          NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_cards_set_id ON cards(set_id);
CREATE INDEX IF NOT EXISTS idx_cards_rarity ON cards(rarity);

-- =============================================================
-- Feature: Card Collection System
-- TABLE: user_cards
-- =============================================================
CREATE TABLE IF NOT EXISTS user_cards (
  id                UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  card_id           UUID      NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  quantity          INT       NOT NULL DEFAULT 1 CHECK (quantity >= 0),
  first_obtained_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, card_id)
);

CREATE INDEX IF NOT EXISTS idx_user_cards_user_id ON user_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_cards_card_id ON user_cards(card_id);

-- =============================================================
-- Feature: Chest / Loot Box System
-- TABLE: chest_types
-- =============================================================
CREATE TABLE IF NOT EXISTS chest_types (
  id              UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            VARCHAR(50)  NOT NULL,
  price_coins     BIGINT       NOT NULL,
  card_count_min  INT          NOT NULL DEFAULT 1,
  card_count_max  INT          NOT NULL DEFAULT 3,
  rarity_weights  JSONB        NOT NULL,
  image_url       VARCHAR(255)
);

-- =============================================================
-- Feature: Pet System
-- TABLE: pets
-- =============================================================
CREATE TABLE IF NOT EXISTS pets (
  id                  UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name                VARCHAR(50)  NOT NULL,
  ability_type        VARCHAR(50)  NOT NULL,
  ability_description VARCHAR(255) NOT NULL,
  image_url           VARCHAR(255),
  max_level           INT          NOT NULL DEFAULT 20,
  treats_per_level    INT          NOT NULL DEFAULT 10
);

-- =============================================================
-- Feature: Pet System
-- TABLE: user_pets
-- =============================================================
CREATE TABLE IF NOT EXISTS user_pets (
  id         UUID    PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pet_id     UUID    NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  level      INT     NOT NULL DEFAULT 1,
  xp         INT     NOT NULL DEFAULT 0,
  is_active  BOOLEAN NOT NULL DEFAULT FALSE,
  treats_fed INT     NOT NULL DEFAULT 0,
  UNIQUE(user_id, pet_id)
);

CREATE INDEX IF NOT EXISTS idx_user_pets_user_id ON user_pets(user_id);
CREATE INDEX IF NOT EXISTS idx_user_pets_pet_id  ON user_pets(pet_id);

-- =============================================================
-- Feature: Social / Friends System
-- TABLE: friendships
-- =============================================================
CREATE TABLE IF NOT EXISTS friendships (
  id                    UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id             UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status                VARCHAR(20)  NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','blocked')),
  spins_gifted_today    INT          NOT NULL DEFAULT 0,
  spins_gifted_reset_at TIMESTAMP    NOT NULL DEFAULT NOW(),
  created_at            TIMESTAMP    NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

CREATE INDEX IF NOT EXISTS idx_friendships_user_id   ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status    ON friendships(status);

-- =============================================================
-- Feature: Clan System
-- TABLE: clans
-- =============================================================
CREATE TABLE IF NOT EXISTS clans (
  id                UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name              VARCHAR(100) UNIQUE NOT NULL,
  leader_id         UUID         NOT NULL REFERENCES users(id),
  description       TEXT,
  badge_image       VARCHAR(255),
  is_public         BOOLEAN      NOT NULL DEFAULT TRUE,
  total_points      BIGINT       NOT NULL DEFAULT 0,
  member_count      INT          NOT NULL DEFAULT 1,
  min_village_level INT          NOT NULL DEFAULT 1,
  created_at        TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clans_leader_id    ON clans(leader_id);
CREATE INDEX IF NOT EXISTS idx_clans_total_points ON clans(total_points DESC);

-- =============================================================
-- Feature: Clan System
-- TABLE: clan_members
-- =============================================================
CREATE TABLE IF NOT EXISTS clan_members (
  id                 UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  clan_id            UUID        NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
  user_id            UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role               VARCHAR(20) NOT NULL DEFAULT 'member' CHECK (role IN ('leader','elder','member')),
  points_contributed BIGINT      NOT NULL DEFAULT 0,
  weekly_spins       INT         NOT NULL DEFAULT 0,
  joined_at          TIMESTAMP   NOT NULL DEFAULT NOW(),
  UNIQUE(clan_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_clan_members_clan_id ON clan_members(clan_id);
CREATE INDEX IF NOT EXISTS idx_clan_members_user_id ON clan_members(user_id);

-- =============================================================
-- Feature: Limited-Time Events
-- TABLE: events
-- =============================================================
CREATE TABLE IF NOT EXISTS events (
  id           UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  type         VARCHAR(50)  NOT NULL,
  title        VARCHAR(150) NOT NULL,
  description  TEXT,
  banner_image VARCHAR(255),
  starts_at    TIMESTAMP    NOT NULL,
  ends_at      TIMESTAMP    NOT NULL,
  reward_json  JSONB        NOT NULL,
  rules_json   JSONB,
  is_active    BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_events_is_active ON events(is_active, starts_at, ends_at);
CREATE INDEX IF NOT EXISTS idx_events_type      ON events(type);

-- =============================================================
-- Feature: Limited-Time Events
-- TABLE: user_event_progress
-- =============================================================
CREATE TABLE IF NOT EXISTS user_event_progress (
  id         UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id   UUID      NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  progress   INT       NOT NULL DEFAULT 0,
  is_claimed BOOLEAN   NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);

CREATE INDEX IF NOT EXISTS idx_user_event_progress_user_id  ON user_event_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_event_progress_event_id ON user_event_progress(event_id);

-- =============================================================
-- Feature: Achievement System
-- TABLE: achievements
-- =============================================================
CREATE TABLE IF NOT EXISTS achievements (
  id            UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  key           VARCHAR(100) UNIQUE NOT NULL,
  title         VARCHAR(150) NOT NULL,
  description   VARCHAR(500) NOT NULL,
  icon_url      VARCHAR(255),
  category      VARCHAR(50)  NOT NULL,
  target_value  INT          NOT NULL DEFAULT 1,
  reward_coins  BIGINT       NOT NULL DEFAULT 0,
  reward_spins  INT          NOT NULL DEFAULT 0,
  reward_gems   INT          NOT NULL DEFAULT 0,
  display_order INT          NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_achievements_key      ON achievements(key);
CREATE INDEX IF NOT EXISTS idx_achievements_category ON achievements(category);

-- =============================================================
-- Feature: Achievement System
-- TABLE: user_achievements
-- =============================================================
CREATE TABLE IF NOT EXISTS user_achievements (
  id             UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID      NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  current_value  INT       NOT NULL DEFAULT 0,
  is_unlocked    BOOLEAN   NOT NULL DEFAULT FALSE,
  is_claimed     BOOLEAN   NOT NULL DEFAULT FALSE,
  unlocked_at    TIMESTAMP,
  UNIQUE(user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id        ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements(achievement_id);

-- =============================================================
-- Feature: Push Notifications
-- TABLE: notifications
-- =============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id         UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       VARCHAR(50)  NOT NULL,
  title      VARCHAR(150) NOT NULL,
  message    TEXT         NOT NULL,
  data_json  JSONB,
  is_read    BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);

-- =============================================================
-- Feature: Card Trading System
-- TABLE: trade_requests
-- =============================================================
CREATE TABLE IF NOT EXISTS trade_requests (
  id                UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id         UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id       UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  offered_card_id   UUID         NOT NULL REFERENCES cards(id),
  requested_card_id UUID         NOT NULL REFERENCES cards(id),
  status            VARCHAR(20)  NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected','expired')),
  expires_at        TIMESTAMP    NOT NULL DEFAULT (NOW() + INTERVAL '48 hours'),
  created_at        TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trade_requests_sender         ON trade_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_trade_requests_receiver       ON trade_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_trade_requests_status         ON trade_requests(status);
CREATE INDEX IF NOT EXISTS idx_trade_requests_offered_card   ON trade_requests(offered_card_id);
CREATE INDEX IF NOT EXISTS idx_trade_requests_requested_card ON trade_requests(requested_card_id);

-- =============================================================
-- Add active_pet_id FK (users -> pets), idempotent via DO block
-- =============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_users_active_pet'
      AND table_name = 'users'
  ) THEN
    ALTER TABLE users ADD CONSTRAINT fk_users_active_pet
      FOREIGN KEY (active_pet_id) REFERENCES pets(id) ON DELETE SET NULL;
  END IF;
END
$$;
