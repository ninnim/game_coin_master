-- =============================================================
-- Spin Empire — Migration 001: Initial Schema
-- =============================================================
-- UP:   Run this file to create the full database schema
-- DOWN: See the DROP statements at the bottom (commented out)
-- =============================================================

-- -------------------------------------------------------------
-- Migration log table (created first so migrations can self-log)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS migration_log (
  id          SERIAL      PRIMARY KEY,
  version     VARCHAR(50) UNIQUE NOT NULL,
  description TEXT        NOT NULL,
  applied_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
  checksum    VARCHAR(64)
);

-- Guard: skip if this migration was already applied
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM migration_log WHERE version = '001_initial'
  ) THEN
    RAISE NOTICE 'Migration 001_initial already applied — skipping.';
    -- Return early by raising an exception caught below
    RAISE EXCEPTION 'MIGRATION_ALREADY_APPLIED';
  END IF;
END
$$;

-- =============================================================
-- ↑↑↑  UP SECTION  ↑↑↑
-- =============================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------
-- TABLE 1: users
-- ------------------------------------------------------------------
CREATE TABLE users (
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

CREATE INDEX idx_users_email         ON users(email);
CREATE INDEX idx_users_village_level ON users(village_level);
CREATE INDEX idx_users_coins         ON users(coins DESC);

-- ------------------------------------------------------------------
-- TABLE 2: villages
-- ------------------------------------------------------------------
CREATE TABLE villages (
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

CREATE INDEX idx_villages_order_num ON villages(order_num);

-- ------------------------------------------------------------------
-- TABLE 3: buildings
-- ------------------------------------------------------------------
CREATE TABLE buildings (
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

CREATE INDEX idx_buildings_village_id ON buildings(village_id);

-- ------------------------------------------------------------------
-- TABLE 4: user_villages
-- ------------------------------------------------------------------
CREATE TABLE user_villages (
  id           UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  village_id   UUID      NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
  is_completed BOOLEAN   NOT NULL DEFAULT FALSE,
  is_active    BOOLEAN   NOT NULL DEFAULT TRUE,
  started_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMP,
  UNIQUE(user_id, village_id)
);

CREATE INDEX idx_user_villages_user_id    ON user_villages(user_id);
CREATE INDEX idx_user_villages_village_id ON user_villages(village_id);

-- ------------------------------------------------------------------
-- TABLE 5: user_buildings
-- ------------------------------------------------------------------
CREATE TABLE user_buildings (
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

CREATE INDEX idx_user_buildings_user_id     ON user_buildings(user_id);
CREATE INDEX idx_user_buildings_building_id ON user_buildings(building_id);

-- ------------------------------------------------------------------
-- TABLE 6: spin_results
-- ------------------------------------------------------------------
CREATE TABLE spin_results (
  id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  slot1             VARCHAR(20) NOT NULL,
  slot2             VARCHAR(20) NOT NULL,
  slot3             VARCHAR(20) NOT NULL,
  result_type       VARCHAR(30) NOT NULL,
  coins_earned      BIGINT      NOT NULL DEFAULT 0,
  spins_earned      INT         NOT NULL DEFAULT 0,
  bet_multiplier    INT         NOT NULL DEFAULT 1,
  pet_bonus_applied BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_spin_results_user_id    ON spin_results(user_id);
CREATE INDEX idx_spin_results_created_at ON spin_results(created_at DESC);

-- ------------------------------------------------------------------
-- TABLE 7: attacks
-- ------------------------------------------------------------------
CREATE TABLE attacks (
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

CREATE INDEX idx_attacks_attacker   ON attacks(attacker_id);
CREATE INDEX idx_attacks_defender   ON attacks(defender_id);
CREATE INDEX idx_attacks_created_at ON attacks(created_at DESC);
CREATE INDEX idx_attacks_building   ON attacks(building_id);

-- ------------------------------------------------------------------
-- TABLE 8: raids
-- ------------------------------------------------------------------
CREATE TABLE raids (
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

CREATE INDEX idx_raids_raider     ON raids(raider_id);
CREATE INDEX idx_raids_victim     ON raids(victim_id);
CREATE INDEX idx_raids_created_at ON raids(created_at DESC);

-- ------------------------------------------------------------------
-- TABLE 9: card_sets
-- ------------------------------------------------------------------
CREATE TABLE card_sets (
  id           UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         VARCHAR(100) NOT NULL,
  theme        VARCHAR(100) NOT NULL,
  image_url    VARCHAR(255),
  reward_coins BIGINT       NOT NULL DEFAULT 0,
  reward_spins INT          NOT NULL DEFAULT 0,
  reward_gems  INT          NOT NULL DEFAULT 0
);

-- ------------------------------------------------------------------
-- TABLE 10: cards
-- ------------------------------------------------------------------
CREATE TABLE cards (
  id          UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  set_id      UUID         NOT NULL REFERENCES card_sets(id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,
  description VARCHAR(500),
  rarity      VARCHAR(20)  NOT NULL CHECK (rarity IN ('common','rare','epic','legendary')),
  image_url   VARCHAR(255),
  card_order  INT          NOT NULL DEFAULT 0
);

CREATE INDEX idx_cards_set_id ON cards(set_id);
CREATE INDEX idx_cards_rarity ON cards(rarity);

-- ------------------------------------------------------------------
-- TABLE 11: user_cards
-- ------------------------------------------------------------------
CREATE TABLE user_cards (
  id                UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  card_id           UUID      NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  quantity          INT       NOT NULL DEFAULT 1 CHECK (quantity >= 0),
  first_obtained_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, card_id)
);

CREATE INDEX idx_user_cards_user_id ON user_cards(user_id);
CREATE INDEX idx_user_cards_card_id ON user_cards(card_id);

-- ------------------------------------------------------------------
-- TABLE 12: chest_types
-- ------------------------------------------------------------------
CREATE TABLE chest_types (
  id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name           VARCHAR(50)  NOT NULL,
  price_coins    BIGINT       NOT NULL,
  card_count_min INT          NOT NULL DEFAULT 1,
  card_count_max INT          NOT NULL DEFAULT 3,
  rarity_weights JSONB        NOT NULL,
  image_url      VARCHAR(255)
);

-- ------------------------------------------------------------------
-- TABLE 13: pets
-- ------------------------------------------------------------------
CREATE TABLE pets (
  id                  UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name                VARCHAR(50)  NOT NULL,
  ability_type        VARCHAR(50)  NOT NULL,
  ability_description VARCHAR(255) NOT NULL,
  image_url           VARCHAR(255),
  max_level           INT          NOT NULL DEFAULT 20,
  treats_per_level    INT          NOT NULL DEFAULT 10
);

-- ------------------------------------------------------------------
-- TABLE 14: user_pets
-- ------------------------------------------------------------------
CREATE TABLE user_pets (
  id         UUID    PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pet_id     UUID    NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  level      INT     NOT NULL DEFAULT 1,
  xp         INT     NOT NULL DEFAULT 0,
  is_active  BOOLEAN NOT NULL DEFAULT FALSE,
  treats_fed INT     NOT NULL DEFAULT 0,
  UNIQUE(user_id, pet_id)
);

CREATE INDEX idx_user_pets_user_id ON user_pets(user_id);
CREATE INDEX idx_user_pets_pet_id  ON user_pets(pet_id);

-- ------------------------------------------------------------------
-- TABLE 15: friendships
-- ------------------------------------------------------------------
CREATE TABLE friendships (
  id                    UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status                VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','blocked')),
  spins_gifted_today    INT         NOT NULL DEFAULT 0,
  spins_gifted_reset_at TIMESTAMP   NOT NULL DEFAULT NOW(),
  created_at            TIMESTAMP   NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

CREATE INDEX idx_friendships_user_id   ON friendships(user_id);
CREATE INDEX idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX idx_friendships_status    ON friendships(status);

-- ------------------------------------------------------------------
-- TABLE 16: clans
-- ------------------------------------------------------------------
CREATE TABLE clans (
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

CREATE INDEX idx_clans_leader_id    ON clans(leader_id);
CREATE INDEX idx_clans_total_points ON clans(total_points DESC);

-- ------------------------------------------------------------------
-- TABLE 17: clan_members
-- ------------------------------------------------------------------
CREATE TABLE clan_members (
  id                 UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  clan_id            UUID        NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
  user_id            UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role               VARCHAR(20) NOT NULL DEFAULT 'member' CHECK (role IN ('leader','elder','member')),
  points_contributed BIGINT      NOT NULL DEFAULT 0,
  weekly_spins       INT         NOT NULL DEFAULT 0,
  joined_at          TIMESTAMP   NOT NULL DEFAULT NOW(),
  UNIQUE(clan_id, user_id)
);

CREATE INDEX idx_clan_members_clan_id ON clan_members(clan_id);
CREATE INDEX idx_clan_members_user_id ON clan_members(user_id);

-- ------------------------------------------------------------------
-- TABLE 18: events
-- ------------------------------------------------------------------
CREATE TABLE events (
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

CREATE INDEX idx_events_is_active ON events(is_active, starts_at, ends_at);
CREATE INDEX idx_events_type      ON events(type);

-- ------------------------------------------------------------------
-- TABLE 19: user_event_progress
-- ------------------------------------------------------------------
CREATE TABLE user_event_progress (
  id         UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id   UUID      NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  progress   INT       NOT NULL DEFAULT 0,
  is_claimed BOOLEAN   NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);

CREATE INDEX idx_user_event_progress_user_id  ON user_event_progress(user_id);
CREATE INDEX idx_user_event_progress_event_id ON user_event_progress(event_id);

-- ------------------------------------------------------------------
-- TABLE 20: achievements
-- ------------------------------------------------------------------
CREATE TABLE achievements (
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

CREATE INDEX idx_achievements_key      ON achievements(key);
CREATE INDEX idx_achievements_category ON achievements(category);

-- ------------------------------------------------------------------
-- TABLE 21: user_achievements
-- ------------------------------------------------------------------
CREATE TABLE user_achievements (
  id             UUID      PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID      NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  current_value  INT       NOT NULL DEFAULT 0,
  is_unlocked    BOOLEAN   NOT NULL DEFAULT FALSE,
  is_claimed     BOOLEAN   NOT NULL DEFAULT FALSE,
  unlocked_at    TIMESTAMP,
  UNIQUE(user_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user_id        ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements(achievement_id);

-- ------------------------------------------------------------------
-- TABLE 22: notifications
-- ------------------------------------------------------------------
CREATE TABLE notifications (
  id         UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       VARCHAR(50)  NOT NULL,
  title      VARCHAR(150) NOT NULL,
  message    TEXT         NOT NULL,
  data_json  JSONB,
  is_read    BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(type);

-- ------------------------------------------------------------------
-- TABLE 23: trade_requests
-- ------------------------------------------------------------------
CREATE TABLE trade_requests (
  id                UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id         UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id       UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  offered_card_id   UUID         NOT NULL REFERENCES cards(id),
  requested_card_id UUID         NOT NULL REFERENCES cards(id),
  status            VARCHAR(20)  NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected','expired')),
  expires_at        TIMESTAMP    NOT NULL DEFAULT (NOW() + INTERVAL '48 hours'),
  created_at        TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trade_requests_sender         ON trade_requests(sender_id);
CREATE INDEX idx_trade_requests_receiver       ON trade_requests(receiver_id);
CREATE INDEX idx_trade_requests_status         ON trade_requests(status);
CREATE INDEX idx_trade_requests_offered_card   ON trade_requests(offered_card_id);
CREATE INDEX idx_trade_requests_requested_card ON trade_requests(requested_card_id);

-- ------------------------------------------------------------------
-- Self-referencing FK: users.active_pet_id -> pets.id
-- ------------------------------------------------------------------
ALTER TABLE users ADD CONSTRAINT fk_users_active_pet
  FOREIGN KEY (active_pet_id) REFERENCES pets(id) ON DELETE SET NULL;

-- ------------------------------------------------------------------
-- Log this migration as applied
-- ------------------------------------------------------------------
INSERT INTO migration_log (version, description, checksum)
VALUES (
  '001_initial',
  'Full initial schema — 23 tables, all indexes, all constraints',
  md5('001_initial_spin_empire_schema')
);

COMMIT;

-- =============================================================
-- ↓↓↓  DOWN SECTION (commented out — run manually to rollback)  ↓↓↓
-- =============================================================
/*
BEGIN;

ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_active_pet;

DROP TABLE IF EXISTS trade_requests        CASCADE;
DROP TABLE IF EXISTS notifications         CASCADE;
DROP TABLE IF EXISTS user_achievements     CASCADE;
DROP TABLE IF EXISTS achievements          CASCADE;
DROP TABLE IF EXISTS user_event_progress   CASCADE;
DROP TABLE IF EXISTS events                CASCADE;
DROP TABLE IF EXISTS clan_members          CASCADE;
DROP TABLE IF EXISTS clans                 CASCADE;
DROP TABLE IF EXISTS friendships           CASCADE;
DROP TABLE IF EXISTS user_pets             CASCADE;
DROP TABLE IF EXISTS pets                  CASCADE;
DROP TABLE IF EXISTS chest_types           CASCADE;
DROP TABLE IF EXISTS user_cards            CASCADE;
DROP TABLE IF EXISTS cards                 CASCADE;
DROP TABLE IF EXISTS card_sets             CASCADE;
DROP TABLE IF EXISTS raids                 CASCADE;
DROP TABLE IF EXISTS attacks               CASCADE;
DROP TABLE IF EXISTS spin_results          CASCADE;
DROP TABLE IF EXISTS user_buildings        CASCADE;
DROP TABLE IF EXISTS user_villages         CASCADE;
DROP TABLE IF EXISTS buildings             CASCADE;
DROP TABLE IF EXISTS villages              CASCADE;
DROP TABLE IF EXISTS users                 CASCADE;
DROP TABLE IF EXISTS migration_log         CASCADE;

COMMIT;
*/
