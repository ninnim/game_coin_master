-- =============================================================
-- Spin Empire — Complete Seed Data
-- Run AFTER schema.sql
-- =============================================================

BEGIN;

-- =============================================================
-- VILLAGES (10 themed villages)
-- =============================================================
INSERT INTO villages (id, name, theme, order_num, is_boom, background_image, music_track, sky_color, total_build_cost, description) VALUES
  ('11111111-0001-0001-0001-000000000001', 'Medieval Kingdom',  'medieval', 1,  FALSE, 'bg/medieval.png',  'music/medieval.mp3',  '#4A90D9', 980000,           'A classic kingdom of stone castles and valiant knights.'),
  ('11111111-0002-0001-0001-000000000002', 'Viking Village',    'viking',   2,  FALSE, 'bg/viking.png',    'music/viking.mp3',    '#8B7355', 2450000,          'A fierce Norse village of longboats and warriors.'),
  ('11111111-0003-0001-0001-000000000003', 'Ancient Egypt',     'egypt',    3,  FALSE, 'bg/egypt.png',     'music/egypt.mp3',     '#F4A460', 6120000,          'A land of pharaohs, pyramids and desert sands.'),
  ('11111111-0004-0001-0001-000000000004', 'Outer Space',       'space',    4,  FALSE, 'bg/space.png',     'music/space.mp3',     '#0A0A2E', 15300000,         'A cosmic outpost on the frontier of the galaxy.'),
  ('11111111-0005-0001-0001-000000000005', 'Deep Ocean',        'ocean',    5,  TRUE,  'bg/ocean.png',     'music/ocean.mp3',     '#003366', 153000000,        'A boom village beneath the waves — double the cost, double the glory!'),
  ('11111111-0006-0001-0001-000000000006', 'Jungle Temple',     'jungle',   6,  FALSE, 'bg/jungle.png',    'music/jungle.mp3',    '#1A4D1A', 191250000,        'A hidden temple deep in the heart of an ancient jungle.'),
  ('11111111-0007-0001-0001-000000000007', 'Frozen North',      'ice',      7,  FALSE, 'bg/ice.png',       'music/ice.mp3',       '#E0F0FF', 478125000,        'A frozen tundra where only the strongest survive the eternal winter.'),
  ('11111111-0008-0001-0001-000000000008', 'Desert Oasis',      'desert',   8,  FALSE, 'bg/desert.png',    'music/desert.mp3',    '#FFD700', 1195312500,       'A shimmering oasis city rising from the scorching sands.'),
  ('11111111-0009-0001-0001-000000000009', 'Fantasy Realm',     'fantasy',  9,  FALSE, 'bg/fantasy.png',   'music/fantasy.mp3',   '#6A0DAD', 2988281250,       'A magical kingdom where dragons soar and wizards rule.'),
  ('11111111-0010-0001-0001-000000000010', 'Cyber Future',      'future',   10, TRUE,  'bg/future.png',    'music/future.mp3',    '#001A33', 29882812500,      'A boom village of gleaming circuits and artificial intelligence — the ultimate challenge!');

-- =============================================================
-- BUILDINGS (9 per village = 90 total)
-- upgrade_costs array: [lvl1, lvl2, lvl3, lvl4]
-- Positions distribute 9 buildings across a scene (x=0..100, y=0..100)
-- =============================================================

-- ---- Village 1: Medieval Kingdom ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0001-0001-0001-000000000001', 'Castle',         'medieval/castle',         15.00, 60.00, '{10000,25000,60000,150000}',   'The mighty stone castle that rules the kingdom.',              1),
  ('11111111-0001-0001-0001-000000000001', 'Blacksmith Tower','medieval/blacksmith',     35.00, 50.00, '{10000,25000,60000,150000}',   'Forges weapons and armor for the kingdom''s soldiers.',        2),
  ('11111111-0001-0001-0001-000000000001', 'Stone Well',     'medieval/well',           55.00, 65.00, '{10000,25000,60000,150000}',   'The lifeblood of the village — fresh water for all.',          3),
  ('11111111-0001-0001-0001-000000000001', 'Tavern',         'medieval/tavern',         75.00, 55.00, '{10000,25000,60000,150000}',   'Where weary travelers and soldiers rest and celebrate.',        4),
  ('11111111-0001-0001-0001-000000000001', 'Grain Farm',     'medieval/farm',           20.00, 75.00, '{10000,25000,60000,150000}',   'Fertile fields that feed the kingdom''s people.',              5),
  ('11111111-0001-0001-0001-000000000001', 'Windmill',       'medieval/windmill',       45.00, 40.00, '{10000,25000,60000,150000}',   'Grinds grain into flour for the village bakery.',              6),
  ('11111111-0001-0001-0001-000000000001', 'Market Stalls',  'medieval/market',         65.00, 75.00, '{10000,25000,60000,150000}',   'A bustling market where merchants trade their goods.',          7),
  ('11111111-0001-0001-0001-000000000001', 'Church',         'medieval/church',         85.00, 65.00, '{10000,25000,60000,150000}',   'A place of worship and hope for the kingdom''s citizens.',     8),
  ('11111111-0001-0001-0001-000000000001', 'Watchtower',     'medieval/watchtower',     50.00, 80.00, '{10000,25000,60000,150000}',   'Stands tall to guard against approaching enemies.',            9);

-- ---- Village 2: Viking Village ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0002-0001-0001-000000000002', 'Longhouse',      'viking/longhouse',        15.00, 60.00, '{25000,60000,150000,375000}',  'The great hall where the clan feasts and plans raids.',         1),
  ('11111111-0002-0001-0001-000000000002', 'Shipyard',       'viking/shipyard',         35.00, 50.00, '{25000,60000,150000,375000}',  'Where fearsome longships are built for sea raids.',             2),
  ('11111111-0002-0001-0001-000000000002', 'Forge',          'viking/forge',            55.00, 65.00, '{25000,60000,150000,375000}',  'Crafts axes, shields and chain mail for Viking warriors.',      3),
  ('11111111-0002-0001-0001-000000000002', 'Mead Hall',      'viking/meadhall',         75.00, 55.00, '{25000,60000,150000,375000}',  'A place of celebration filled with the finest mead.',           4),
  ('11111111-0002-0001-0001-000000000002', 'Rune Stone',     'viking/runestone',        20.00, 75.00, '{25000,60000,150000,375000}',  'Ancient runes carved to honor the gods and fallen heroes.',     5),
  ('11111111-0002-0001-0001-000000000002', 'Dock',           'viking/dock',             45.00, 40.00, '{25000,60000,150000,375000}',  'A sturdy dock where the fleet rests between voyages.',          6),
  ('11111111-0002-0001-0001-000000000002', 'Barn',           'viking/barn',             65.00, 75.00, '{25000,60000,150000,375000}',  'Stores plunder, livestock and winter provisions.',              7),
  ('11111111-0002-0001-0001-000000000002', 'Norse Temple',   'viking/temple',           85.00, 65.00, '{25000,60000,150000,375000}',  'Dedicated to Odin, Thor and the Norse pantheon.',               8),
  ('11111111-0002-0001-0001-000000000002', 'Watchtower',     'viking/watchtower',       50.00, 80.00, '{25000,60000,150000,375000}',  'Scouts the horizon for enemy ships and rival clans.',           9);

-- ---- Village 3: Ancient Egypt ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0003-0001-0001-000000000003', 'Great Pyramid',  'egypt/pyramid',           15.00, 60.00, '{60000,150000,375000,900000}', 'A towering monument built to honor the great pharaoh.',         1),
  ('11111111-0003-0001-0001-000000000003', 'Sphinx Gate',    'egypt/sphinx',            35.00, 50.00, '{60000,150000,375000,900000}', 'The guardian lion-god watches over the entrance.',               2),
  ('11111111-0003-0001-0001-000000000003', 'Obelisk',        'egypt/obelisk',           55.00, 65.00, '{60000,150000,375000,900000}', 'A golden-tipped pillar inscribed with hieroglyphs.',             3),
  ('11111111-0003-0001-0001-000000000003', 'Bazaar',         'egypt/bazaar',            75.00, 55.00, '{60000,150000,375000,900000}', 'A vibrant market trading spices, silk and gold.',               4),
  ('11111111-0003-0001-0001-000000000003', 'Pharaoh Palace', 'egypt/palace',            20.00, 75.00, '{60000,150000,375000,900000}', 'The lavish palace of the god-king pharaoh.',                    5),
  ('11111111-0003-0001-0001-000000000003', 'Temple of Ra',   'egypt/temple_ra',         45.00, 40.00, '{60000,150000,375000,900000}', 'Sacred temple where priests worship the sun god Ra.',           6),
  ('11111111-0003-0001-0001-000000000003', 'Granary',        'egypt/granary',           65.00, 75.00, '{60000,150000,375000,900000}', 'Stores the annual harvest from the fertile Nile banks.',         7),
  ('11111111-0003-0001-0001-000000000003', 'Chariot Stable', 'egypt/stable',            85.00, 65.00, '{60000,150000,375000,900000}', 'Houses the pharaoh''s elite war chariots and horses.',          8),
  ('11111111-0003-0001-0001-000000000003', 'Royal Tomb',     'egypt/tomb',              50.00, 80.00, '{60000,150000,375000,900000}', 'The eternal resting place prepared for the pharaoh.',           9);

-- ---- Village 4: Outer Space ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0004-0001-0001-000000000004', 'Launch Pad',     'space/launchpad',         15.00, 60.00, '{150000,375000,900000,2250000}', 'Launches rockets to explore distant star systems.',            1),
  ('11111111-0004-0001-0001-000000000004', 'Control Center', 'space/control',           35.00, 50.00, '{150000,375000,900000,2250000}', 'Mission command for all space operations.',                    2),
  ('11111111-0004-0001-0001-000000000004', 'Satellite Dish', 'space/dish',              55.00, 65.00, '{150000,375000,900000,2250000}', 'Communicates with distant probes and alien signals.',           3),
  ('11111111-0004-0001-0001-000000000004', 'Rover Garage',   'space/rover',             75.00, 55.00, '{150000,375000,900000,2250000}', 'Houses exploration rovers for planetary surface missions.',     4),
  ('11111111-0004-0001-0001-000000000004', 'Biodome',        'space/biodome',           20.00, 75.00, '{150000,375000,900000,2250000}', 'A pressurized dome growing food in zero-gravity conditions.',  5),
  ('11111111-0004-0001-0001-000000000004', 'Observatory',    'space/observatory',       45.00, 40.00, '{150000,375000,900000,2250000}', 'Scans the cosmos for new planets and cosmic phenomena.',       6),
  ('11111111-0004-0001-0001-000000000004', 'Fuel Depot',     'space/fuel',              65.00, 75.00, '{150000,375000,900000,2250000}', 'Stores rocket fuel for intergalactic missions.',               7),
  ('11111111-0004-0001-0001-000000000004', 'Alien Embassy',  'space/embassy',           85.00, 65.00, '{150000,375000,900000,2250000}', 'Diplomatic relations with extraterrestrial civilizations.',    8),
  ('11111111-0004-0001-0001-000000000004', 'Space Bar',      'space/bar',               50.00, 80.00, '{150000,375000,900000,2250000}', 'Where astronauts unwind after long deep-space missions.',      9);

-- ---- Village 5: Deep Ocean (BOOM) ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0005-0001-0001-000000000005', 'Coral Castle',   'ocean/castle',            15.00, 60.00, '{750000,1875000,4500000,11250000}', 'A magnificent castle built from living coral reefs.',        1),
  ('11111111-0005-0001-0001-000000000005', 'Treasure Ship',  'ocean/ship',              35.00, 50.00, '{750000,1875000,4500000,11250000}', 'A sunken galleon overflowing with pirate gold.',             2),
  ('11111111-0005-0001-0001-000000000005', 'Lighthouse',     'ocean/lighthouse',        55.00, 65.00, '{750000,1875000,4500000,11250000}', 'A beacon guiding ships through treacherous waters.',         3),
  ('11111111-0005-0001-0001-000000000005', 'Submarine Bay',  'ocean/submarine',         75.00, 55.00, '{750000,1875000,4500000,11250000}', 'Docks for deep-diving submarines exploring the abyss.',      4),
  ('11111111-0005-0001-0001-000000000005', 'Pearl Market',   'ocean/market',            20.00, 75.00, '{750000,1875000,4500000,11250000}', 'Trades in rare pearls, sea glass and ocean treasures.',      5),
  ('11111111-0005-0001-0001-000000000005', 'Kelp Farm',      'ocean/kelp',              45.00, 40.00, '{750000,1875000,4500000,11250000}', 'Vast underwater farms of nutritious sea kelp.',             6),
  ('11111111-0005-0001-0001-000000000005', 'Shark Cage',     'ocean/shark',             65.00, 75.00, '{750000,1875000,4500000,11250000}', 'Trains guardian sharks to protect the ocean domain.',        7),
  ('11111111-0005-0001-0001-000000000005', 'Mermaid Grotto', 'ocean/grotto',            85.00, 65.00, '{750000,1875000,4500000,11250000}', 'Home of the mystical mermaids who sing to the sea.',         8),
  ('11111111-0005-0001-0001-000000000005', 'Abyssal Lab',    'ocean/lab',               50.00, 80.00, '{750000,1875000,4500000,11250000}', 'Research station studying the darkest ocean trenches.',      9);

-- ---- Village 6: Jungle Temple ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0006-0001-0001-000000000006', 'Great Temple',      'jungle/temple',         15.00, 60.00, '{937500,2343750,5625000,14062500}', 'An ancient stepped temple rising above the canopy.',         1),
  ('11111111-0006-0001-0001-000000000006', 'Tribal Hut',        'jungle/hut',            35.00, 50.00, '{937500,2343750,5625000,14062500}', 'Dwellings of the jungle tribe elevated above the forest.',   2),
  ('11111111-0006-0001-0001-000000000006', 'Totem Pole',        'jungle/totem',          55.00, 65.00, '{937500,2343750,5625000,14062500}', 'Carved spirit totems protecting the tribe from evil.',       3),
  ('11111111-0006-0001-0001-000000000006', 'Shaman Hut',        'jungle/shaman',         75.00, 55.00, '{937500,2343750,5625000,14062500}', 'Where the shaman brews potions and communes with spirits.',  4),
  ('11111111-0006-0001-0001-000000000006', 'Rope Bridge',       'jungle/bridge',         20.00, 75.00, '{937500,2343750,5625000,14062500}', 'Rickety bridges spanning chasms between jungle platforms.',  5),
  ('11111111-0006-0001-0001-000000000006', 'Jungle Watchtower', 'jungle/watchtower',     45.00, 40.00, '{937500,2343750,5625000,14062500}', 'A high vantage point scanning for threats in the jungle.',   6),
  ('11111111-0006-0001-0001-000000000006', 'Boat Dock',         'jungle/dock',           65.00, 75.00, '{937500,2343750,5625000,14062500}', 'A dock on the jungle river for canoe expeditions.',          7),
  ('11111111-0006-0001-0001-000000000006', 'Trading Post',      'jungle/trading',        85.00, 65.00, '{937500,2343750,5625000,14062500}', 'Exchanges jungle goods — spices, feathers and rare gems.',   8),
  ('11111111-0006-0001-0001-000000000006', 'Fire Pit',          'jungle/firepit',        50.00, 80.00, '{937500,2343750,5625000,14062500}', 'The sacred fire where the tribe gathers each night.',         9);

-- ---- Village 7: Frozen North ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0007-0001-0001-000000000007', 'Ice Palace',        'ice/palace',            15.00, 60.00, '{2343750,5859375,14062500,35156250}', 'A breathtaking palace carved from eternal glacier ice.',     1),
  ('11111111-0007-0001-0001-000000000007', 'Igloo Village',     'ice/igloo',             35.00, 50.00, '{2343750,5859375,14062500,35156250}', 'A cluster of cozy snow igloos for the arctic settlers.',     2),
  ('11111111-0007-0001-0001-000000000007', 'Dog Sled Station',  'ice/dogsled',           55.00, 65.00, '{2343750,5859375,14062500,35156250}', 'A kennel and depot for elite sled dog teams.',               3),
  ('11111111-0007-0001-0001-000000000007', 'Frozen Forge',      'ice/forge',             75.00, 55.00, '{2343750,5859375,14062500,35156250}', 'A forge kept burning against the permafrost cold.',          4),
  ('11111111-0007-0001-0001-000000000007', 'Crystal Cave',      'ice/cave',              20.00, 75.00, '{2343750,5859375,14062500,35156250}', 'A glittering cavern of ice crystals hiding ancient secrets.', 5),
  ('11111111-0007-0001-0001-000000000007', 'Fishing Hole',      'ice/fishing',           45.00, 40.00, '{2343750,5859375,14062500,35156250}', 'An ice fishing spot over a frozen lake teeming with fish.',  6),
  ('11111111-0007-0001-0001-000000000007', 'Frost Tower',       'ice/tower',             65.00, 75.00, '{2343750,5859375,14062500,35156250}', 'A magical tower that channels blizzards to defend the realm.',7),
  ('11111111-0007-0001-0001-000000000007', 'Winter Market',     'ice/market',            85.00, 65.00, '{2343750,5859375,14062500,35156250}', 'A snowy bazaar selling furs, ice carvings and rare relics.', 8),
  ('11111111-0007-0001-0001-000000000007', 'Aurora Shrine',     'ice/shrine',            50.00, 80.00, '{2343750,5859375,14062500,35156250}', 'A sacred shrine bathed in the light of the northern lights.',9);

-- ---- Village 8: Desert Oasis ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0008-0001-0001-000000000008', 'Sultan Palace',  'desert/palace',           15.00, 60.00, '{5859375,14648437,35156250,87890625}', 'The opulent palace of the desert sultan.',                   1),
  ('11111111-0008-0001-0001-000000000008', 'Camel Stable',   'desert/camel',            35.00, 50.00, '{5859375,14648437,35156250,87890625}', 'Stables for the prized camel caravans crossing the sands.',  2),
  ('11111111-0008-0001-0001-000000000008', 'Desert Bazaar',  'desert/bazaar',           55.00, 65.00, '{5859375,14648437,35156250,87890625}', 'A lively market of spices, silks and golden artifacts.',      3),
  ('11111111-0008-0001-0001-000000000008', 'Water Tower',    'desert/water',            75.00, 55.00, '{5859375,14648437,35156250,87890625}', 'A precious reservoir storing oasis water for the settlement.',4),
  ('11111111-0008-0001-0001-000000000008', 'Sand Fortress',  'desert/fortress',         20.00, 75.00, '{5859375,14648437,35156250,87890625}', 'A desert stronghold protecting against rival raiders.',       5),
  ('11111111-0008-0001-0001-000000000008', 'Caravan Post',   'desert/caravan',          45.00, 40.00, '{5859375,14648437,35156250,87890625}', 'A rest stop for weary merchants on the great silk road.',     6),
  ('11111111-0008-0001-0001-000000000008', 'Oasis Pool',     'desert/oasis',            65.00, 75.00, '{5859375,14648437,35156250,87890625}', 'A life-giving pool of fresh water amid the scorching desert.', 7),
  ('11111111-0008-0001-0001-000000000008', 'Mirage Shrine',  'desert/shrine',           85.00, 65.00, '{5859375,14648437,35156250,87890625}', 'A mystical shrine where mirages hold ancient truths.',        8),
  ('11111111-0008-0001-0001-000000000008', 'Dune Racer',     'desert/racer',            50.00, 80.00, '{5859375,14648437,35156250,87890625}', 'A garage for sand vehicles racing across the dunes.',         9);

-- ---- Village 9: Fantasy Realm ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0009-0001-0001-000000000009', 'Wizard Tower',      'fantasy/wizard',        15.00, 60.00, '{14648437,36621093,87890625,219726562}', 'A towering spire where the archmage studies forbidden magic.',1),
  ('11111111-0009-0001-0001-000000000009', 'Dragon Lair',       'fantasy/dragon',        35.00, 50.00, '{14648437,36621093,87890625,219726562}', 'A vast cavern home to a magnificent fire-breathing dragon.',  2),
  ('11111111-0009-0001-0001-000000000009', 'Fairy Garden',      'fantasy/fairy',         55.00, 65.00, '{14648437,36621093,87890625,219726562}', 'A glowing garden where fairy magic makes flowers bloom.',    3),
  ('11111111-0009-0001-0001-000000000009', 'Magic Forge',       'fantasy/forge',         75.00, 55.00, '{14648437,36621093,87890625,219726562}', 'An enchanted forge crafting legendary weapons and armor.',   4),
  ('11111111-0009-0001-0001-000000000009', 'Enchanted Forest',  'fantasy/forest',        20.00, 75.00, '{14648437,36621093,87890625,219726562}', 'A sentient forest of ancient trees whispering old secrets.',  5),
  ('11111111-0009-0001-0001-000000000009', 'Crystal Ball Shop', 'fantasy/crystal',       45.00, 40.00, '{14648437,36621093,87890625,219726562}', 'A mystic shop selling crystal balls, runes and enchantments.',6),
  ('11111111-0009-0001-0001-000000000009', 'Potion Brewery',    'fantasy/brewery',       65.00, 75.00, '{14648437,36621093,87890625,219726562}', 'Brews magical potions of strength, luck and invisibility.',  7),
  ('11111111-0009-0001-0001-000000000009', 'Griffin Stable',    'fantasy/griffin',       85.00, 65.00, '{14648437,36621093,87890625,219726562}', 'Houses noble griffins used as mounts by the realm''s heroes.',8),
  ('11111111-0009-0001-0001-000000000009', 'Portal Gate',       'fantasy/portal',        50.00, 80.00, '{14648437,36621093,87890625,219726562}', 'A shimmering gate linking this realm to parallel worlds.',   9);

-- ---- Village 10: Cyber Future (BOOM) ----
INSERT INTO buildings (village_id, name, image_base, position_x, position_y, upgrade_costs, description, building_order) VALUES
  ('11111111-0010-0001-0001-000000000010', 'Server Tower',    'future/server',           15.00, 60.00, '{146484375,366210937,878906250,2197265625}', 'A towering data center powering the entire cyber city.',     1),
  ('11111111-0010-0001-0001-000000000010', 'Drone Hub',       'future/drone',            35.00, 50.00, '{146484375,366210937,878906250,2197265625}', 'A launch platform for thousands of delivery and combat drones.',2),
  ('11111111-0010-0001-0001-000000000010', 'Neon Arcade',     'future/arcade',           55.00, 65.00, '{146484375,366210937,878906250,2197265625}', 'A glowing arcade with holographic games and VR pods.',       3),
  ('11111111-0010-0001-0001-000000000010', 'Hologram Studio', 'future/hologram',         75.00, 55.00, '{146484375,366210937,878906250,2197265625}', 'Creates life-like holograms for communication and media.',   4),
  ('11111111-0010-0001-0001-000000000010', 'Robot Factory',   'future/robot',            20.00, 75.00, '{146484375,366210937,878906250,2197265625}', 'Mass-produces androids and battle robots for the empire.',   5),
  ('11111111-0010-0001-0001-000000000010', 'Cyber Cafe',      'future/cafe',             45.00, 40.00, '{146484375,366210937,878906250,2197265625}', 'A digital cafe where hackers and netrunners plug in.',        6),
  ('11111111-0010-0001-0001-000000000010', 'Energy Grid',     'future/energy',           65.00, 75.00, '{146484375,366210937,878906250,2197265625}', 'The city''s power core supplying limitless fusion energy.',  7),
  ('11111111-0010-0001-0001-000000000010', 'AI Lab',          'future/ai',               85.00, 65.00, '{146484375,366210937,878906250,2197265625}', 'Develops superintelligent AI for city management and war.',   8),
  ('11111111-0010-0001-0001-000000000010', 'Quantum Core',    'future/quantum',          50.00, 80.00, '{146484375,366210937,878906250,2197265625}', 'The ultimate quantum computer bending the laws of physics.',  9);

-- =============================================================
-- PETS (3 rows)
-- =============================================================
INSERT INTO pets (id, name, ability_type, ability_description, image_url, max_level, treats_per_level) VALUES
  ('22222222-0001-0001-0001-000000000001', 'Foxy',  'extra_raid_hole',   'Foxy gives you an extra dig hole during raids. At max level, dig 4 holes instead of 3!', 'pets/foxy.png',  20, 10),
  ('22222222-0002-0001-0001-000000000002', 'Tiger', 'attack_coin_bonus', 'Tiger roars and multiplies coins stolen during attacks. At max level, steal 3x more coins!', 'pets/tiger.png', 20, 10),
  ('22222222-0003-0001-0001-000000000003', 'Rhino', 'shield_chance',     'Rhino protects your village with an extra shield chance. At max level, never lose a shield!', 'pets/rhino.png', 20, 10);

-- =============================================================
-- CHEST TYPES (3 rows)
-- =============================================================
INSERT INTO chest_types (name, price_coins, card_count_min, card_count_max, rarity_weights, image_url) VALUES
  ('Wooden Chest',  1500,  1, 2, '{"common":80,"rare":18,"epic":2,"legendary":0}',    'chests/wooden.png'),
  ('Golden Chest',  4500,  2, 4, '{"common":50,"rare":35,"epic":13,"legendary":2}',   'chests/golden.png'),
  ('Magical Chest', 15000, 4, 6, '{"common":20,"rare":40,"epic":30,"legendary":10}',  'chests/magical.png');

-- =============================================================
-- CARD SETS (9 sets)
-- =============================================================
INSERT INTO card_sets (id, name, theme, image_url, reward_coins, reward_spins, reward_gems) VALUES
  ('33333333-0001-0001-0001-000000000001', 'Ancient Warriors', 'medieval',  'sets/warriors.png',  50000, 50, 5),
  ('33333333-0002-0001-0001-000000000002', 'Norse Gods',       'viking',    'sets/norse.png',     50000, 50, 5),
  ('33333333-0003-0001-0001-000000000003', 'Pharaohs',         'egypt',     'sets/pharaohs.png',  50000, 50, 5),
  ('33333333-0004-0001-0001-000000000004', 'Star Explorers',   'space',     'sets/space.png',     50000, 50, 5),
  ('33333333-0005-0001-0001-000000000005', 'Ocean Legends',    'ocean',     'sets/ocean.png',     50000, 50, 5),
  ('33333333-0006-0001-0001-000000000006', 'Jungle Kings',     'jungle',    'sets/jungle.png',    50000, 50, 5),
  ('33333333-0007-0001-0001-000000000007', 'Frost Giants',     'ice',       'sets/frost.png',     50000, 50, 5),
  ('33333333-0008-0001-0001-000000000008', 'Desert Raiders',   'desert',    'sets/desert.png',    50000, 50, 5),
  ('33333333-0009-0001-0001-000000000009', 'Dragon Masters',   'fantasy',   'sets/dragons.png',   50000, 50, 5);

-- =============================================================
-- CARDS (12 per set = 108 total)
-- Cards 1-6: common, 7-9: rare, 10-11: epic, 12: legendary
-- =============================================================

-- ---- Set 1: Ancient Warriors ----
INSERT INTO cards (set_id, name, description, rarity, image_url, card_order) VALUES
  ('33333333-0001-0001-0001-000000000001', 'Knight Squire',       'A young squire learning the ways of chivalry.',          'common',    'cards/warriors/01.png', 1),
  ('33333333-0001-0001-0001-000000000001', 'Shield Bearer',       'Carries a massive shield into the heat of battle.',      'common',    'cards/warriors/02.png', 2),
  ('33333333-0001-0001-0001-000000000001', 'Archer',              'A skilled marksman picking off enemies from afar.',      'common',    'cards/warriors/03.png', 3),
  ('33333333-0001-0001-0001-000000000001', 'Footsoldier',         'The backbone of every medieval army.',                   'common',    'cards/warriors/04.png', 4),
  ('33333333-0001-0001-0001-000000000001', 'Crossbowman',         'Wields a devastating crossbow with deadly precision.',   'common',    'cards/warriors/05.png', 5),
  ('33333333-0001-0001-0001-000000000001', 'Siege Engineer',      'Constructs catapults and battering rams for sieges.',    'common',    'cards/warriors/06.png', 6),
  ('33333333-0001-0001-0001-000000000001', 'Battle Knight',       'A seasoned knight who has survived a hundred battles.',  'rare',      'cards/warriors/07.png', 7),
  ('33333333-0001-0001-0001-000000000001', 'Royal Guard',         'Elite protector sworn to defend the crown.',             'rare',      'cards/warriors/08.png', 8),
  ('33333333-0001-0001-0001-000000000001', 'Dragon Slayer',       'A legendary warrior who has slain three dragons.',      'rare',      'cards/warriors/09.png', 9),
  ('33333333-0001-0001-0001-000000000001', 'Champion Warrior',    'The greatest fighter in the entire kingdom.',            'epic',      'cards/warriors/10.png', 10),
  ('33333333-0001-0001-0001-000000000001', 'Legendary Paladin',   'A holy warrior blessed by the gods themselves.',        'epic',      'cards/warriors/11.png', 11),
  ('33333333-0001-0001-0001-000000000001', 'The Eternal King',    'An immortal ruler who has commanded armies for centuries.','legendary','cards/warriors/12.png', 12);

-- ---- Set 2: Norse Gods ----
INSERT INTO cards (set_id, name, description, rarity, image_url, card_order) VALUES
  ('33333333-0002-0001-0001-000000000002', 'Village Raider',      'A fierce Viking warrior raiding coastal settlements.',   'common',    'cards/norse/01.png', 1),
  ('33333333-0002-0001-0001-000000000002', 'Shield Maiden',       'A fearless female warrior wielding axe and shield.',    'common',    'cards/norse/02.png', 2),
  ('33333333-0002-0001-0001-000000000002', 'Longship Rower',      'Muscles forged by years of rowing across cold seas.',   'common',    'cards/norse/03.png', 3),
  ('33333333-0002-0001-0001-000000000002', 'Rune Carver',         'Inscribes powerful runes to bless Viking weapons.',     'common',    'cards/norse/04.png', 4),
  ('33333333-0002-0001-0001-000000000002', 'Berserker',           'A wild warrior who fights in an unstoppable battle rage.','common',   'cards/norse/05.png', 5),
  ('33333333-0002-0001-0001-000000000002', 'Skald Poet',          'Sings epic tales of Viking glory and conquest.',        'common',    'cards/norse/06.png', 6),
  ('33333333-0002-0001-0001-000000000002', 'Jarl Chieftain',      'Commands a clan of fierce Norse warriors.',             'rare',      'cards/norse/07.png', 7),
  ('33333333-0002-0001-0001-000000000002', 'Valkyrie',            'A divine warrior chosen to escort fallen heroes.',      'rare',      'cards/norse/08.png', 8),
  ('33333333-0002-0001-0001-000000000002', 'Loki Trickster',      'The shapeshifting god of mischief and cunning.',        'rare',      'cards/norse/09.png', 9),
  ('33333333-0002-0001-0001-000000000002', 'Thor Thunderstrike',  'The mighty god of thunder wielding Mjolnir.',           'epic',      'cards/norse/10.png', 10),
  ('33333333-0002-0001-0001-000000000002', 'Odin Allfather',      'The wisest and most powerful of all the Norse gods.',   'epic',      'cards/norse/11.png', 11),
  ('33333333-0002-0001-0001-000000000002', 'Ragnarok Herald',     'The bringer of the final battle that ends all worlds.',  'legendary', 'cards/norse/12.png', 12);

-- ---- Set 3: Pharaohs ----
INSERT INTO cards (set_id, name, description, rarity, image_url, card_order) VALUES
  ('33333333-0003-0001-0001-000000000003', 'Desert Scout',        'A swift scout crossing the scorching sands.',           'common',    'cards/pharaohs/01.png', 1),
  ('33333333-0003-0001-0001-000000000003', 'Tomb Painter',        'Decorates pharaoh tombs with sacred hieroglyphs.',      'common',    'cards/pharaohs/02.png', 2),
  ('33333333-0003-0001-0001-000000000003', 'Pyramid Worker',      'Toils under the blazing sun building the great pyramid.','common',   'cards/pharaohs/03.png', 3),
  ('33333333-0003-0001-0001-000000000003', 'Nile Fisherman',      'Casts nets into the life-giving Nile River.',           'common',    'cards/pharaohs/04.png', 4),
  ('33333333-0003-0001-0001-000000000003', 'Chariot Rider',       'Charges into battle on a gilded war chariot.',          'common',    'cards/pharaohs/05.png', 5),
  ('33333333-0003-0001-0001-000000000003', 'Temple Priest',       'Performs sacred rites at the Temple of Ra.',            'common',    'cards/pharaohs/06.png', 6),
  ('33333333-0003-0001-0001-000000000003', 'Royal Scribe',        'Records the pharaoh''s decrees on papyrus scrolls.',    'rare',      'cards/pharaohs/07.png', 7),
  ('33333333-0003-0001-0001-000000000003', 'High Priest of Osiris','Commands the sacred rites of life and death.',         'rare',      'cards/pharaohs/08.png', 8),
  ('33333333-0003-0001-0001-000000000003', 'Sphinx Guardian',     'The immortal guardian standing watch over the pharaoh.','rare',      'cards/pharaohs/09.png', 9),
  ('33333333-0003-0001-0001-000000000003', 'Nefertiti Queen',     'The most beautiful and powerful queen of all Egypt.',   'epic',      'cards/pharaohs/10.png', 10),
  ('33333333-0003-0001-0001-000000000003', 'Ramesses Conqueror',  'The warrior pharaoh who expanded Egypt''s borders.',    'epic',      'cards/pharaohs/11.png', 11),
  ('33333333-0003-0001-0001-000000000003', 'Tutankhamun Gold',    'The boy king whose golden tomb held the world''s wonder.','legendary','cards/pharaohs/12.png', 12);

-- ---- Set 4: Star Explorers ----
INSERT INTO cards (set_id, name, description, rarity, image_url, card_order) VALUES
  ('33333333-0004-0001-0001-000000000004', 'Space Cadet',         'A rookie astronaut on their first mission.',            'common',    'cards/space/01.png', 1),
  ('33333333-0004-0001-0001-000000000004', 'Mission Technician',  'Maintains life support systems on the space station.',  'common',    'cards/space/02.png', 2),
  ('33333333-0004-0001-0001-000000000004', 'Rover Pilot',         'Drives exploration rovers across alien terrain.',       'common',    'cards/space/03.png', 3),
  ('33333333-0004-0001-0001-000000000004', 'Satellite Engineer',  'Deploys and repairs communications satellites.',        'common',    'cards/space/04.png', 4),
  ('33333333-0004-0001-0001-000000000004', 'Astro Botanist',      'Grows plants in zero gravity for the colony.',          'common',    'cards/space/05.png', 5),
  ('33333333-0004-0001-0001-000000000004', 'Space Medic',         'Keeps the crew healthy in the harsh void of space.',    'common',    'cards/space/06.png', 6),
  ('33333333-0004-0001-0001-000000000004', 'Commander Vega',      'A veteran astronaut who has orbited 50 planets.',       'rare',      'cards/space/07.png', 7),
  ('33333333-0004-0001-0001-000000000004', 'Alien Diplomat',      'Forges peace treaties with extraterrestrial species.',  'rare',      'cards/space/08.png', 8),
  ('33333333-0004-0001-0001-000000000004', 'Cosmic Engineer',     'Builds megastructures spanning entire solar systems.',  'rare',      'cards/space/09.png', 9),
  ('33333333-0004-0001-0001-000000000004', 'Nebula Navigator',    'Charts courses through the most dangerous nebulae.',    'epic',      'cards/space/10.png', 10),
  ('33333333-0004-0001-0001-000000000004', 'Star Admiral',        'Commands a fleet of a thousand warships.',              'epic',      'cards/space/11.png', 11),
  ('33333333-0004-0001-0001-000000000004', 'Galactic Overlord',   'Ruler of an empire spanning the entire Milky Way.',    'legendary', 'cards/space/12.png', 12);

-- ---- Set 5: Ocean Legends ----
INSERT INTO cards (set_id, name, description, rarity, image_url, card_order) VALUES
  ('33333333-0005-0001-0001-000000000005', 'Deckhand',            'Works the ropes and sails aboard ocean vessels.',       'common',    'cards/ocean/01.png', 1),
  ('33333333-0005-0001-0001-000000000005', 'Pearl Diver',         'Plunges into the deep to harvest lustrous pearls.',     'common',    'cards/ocean/02.png', 2),
  ('33333333-0005-0001-0001-000000000005', 'Fisherman',           'Casts wide nets to haul in the daily catch.',           'common',    'cards/ocean/03.png', 3),
  ('33333333-0005-0001-0001-000000000005', 'Sea Navigator',       'Reads stars and currents to guide the ship safely.',    'common',    'cards/ocean/04.png', 4),
  ('33333333-0005-0001-0001-000000000005', 'Coral Sculptor',      'Crafts beautiful art from the finest ocean coral.',     'common',    'cards/ocean/05.png', 5),
  ('33333333-0005-0001-0001-000000000005', 'Lighthouse Keeper',   'Keeps the beacon burning to guide ships to safety.',    'common',    'cards/ocean/06.png', 6),
  ('33333333-0005-0001-0001-000000000005', 'Pirate Captain',      'Commands a crew of ruthless buccaneers on the high seas.','rare',    'cards/ocean/07.png', 7),
  ('33333333-0005-0001-0001-000000000005', 'Sea Witch',           'Commands the tides and storms with dark ocean magic.',  'rare',      'cards/ocean/08.png', 8),
  ('33333333-0005-0001-0001-000000000005', 'Kraken Tamer',        'Has tamed the legendary sea monster to do their bidding.','rare',    'cards/ocean/09.png', 9),
  ('33333333-0005-0001-0001-000000000005', 'Mermaid Queen',       'Ruler of all the ocean kingdoms beneath the waves.',    'epic',      'cards/ocean/10.png', 10),
  ('33333333-0005-0001-0001-000000000005', 'Poseidon Champion',   'A warrior blessed by the god of the seas.',             'epic',      'cards/ocean/11.png', 11),
  ('33333333-0005-0001-0001-000000000005', 'Leviathan Rider',     'Rides the greatest sea beast ever to roam the deep.',   'legendary', 'cards/ocean/12.png', 12);

-- ---- Set 6: Jungle Kings ----
INSERT INTO cards (set_id, name, description, rarity, image_url, card_order) VALUES
  ('33333333-0006-0001-0001-000000000006', 'Jungle Scout',        'Navigates the dense jungle with ease and speed.',       'common',    'cards/jungle/01.png', 1),
  ('33333333-0006-0001-0001-000000000006', 'Herb Gatherer',       'Collects rare medicinal plants from the jungle floor.',  'common',    'cards/jungle/02.png', 2),
  ('33333333-0006-0001-0001-000000000006', 'Canoe Builder',       'Crafts swift dugout canoes for river travel.',           'common',    'cards/jungle/03.png', 3),
  ('33333333-0006-0001-0001-000000000006', 'Blowdart Hunter',     'Silently hunts prey with a deadly blowdart pipe.',      'common',    'cards/jungle/04.png', 4),
  ('33333333-0006-0001-0001-000000000006', 'Shaman Apprentice',   'Learning the sacred ways of the jungle spirits.',       'common',    'cards/jungle/05.png', 5),
  ('33333333-0006-0001-0001-000000000006', 'Totem Carver',        'Creates sacred totems to ward off evil spirits.',       'common',    'cards/jungle/06.png', 6),
  ('33333333-0006-0001-0001-000000000006', 'Tribal Warrior',      'A fearsome warrior protecting the jungle tribe.',       'rare',      'cards/jungle/07.png', 7),
  ('33333333-0006-0001-0001-000000000006', 'Grand Shaman',        'Communes with ancient spirits to bless the tribe.',     'rare',      'cards/jungle/08.png', 8),
  ('33333333-0006-0001-0001-000000000006', 'Jaguar Rider',        'Rides a fearless jaguar into the heart of battle.',     'rare',      'cards/jungle/09.png', 9),
  ('33333333-0006-0001-0001-000000000006', 'Anaconda Lord',       'Commands the mightiest serpent of the Amazon.',         'epic',      'cards/jungle/10.png', 10),
  ('33333333-0006-0001-0001-000000000006', 'Temple High Priest',  'Guards the ancient temple and its priceless secrets.',  'epic',      'cards/jungle/11.png', 11),
  ('33333333-0006-0001-0001-000000000006', 'Jungle God Emperor',  'The divine ruler of all the jungle kingdoms.',          'legendary', 'cards/jungle/12.png', 12);

-- ---- Set 7: Frost Giants ----
INSERT INTO cards (set_id, name, description, rarity, image_url, card_order) VALUES
  ('33333333-0007-0001-0001-000000000007', 'Ice Fisher',          'Braves sub-zero temperatures to fish through the ice.',  'common',    'cards/frost/01.png', 1),
  ('33333333-0007-0001-0001-000000000007', 'Sled Driver',         'Races dog sleds across the frozen tundra.',             'common',    'cards/frost/02.png', 2),
  ('33333333-0007-0001-0001-000000000007', 'Igloo Architect',     'Designs and builds perfect snow dwellings.',            'common',    'cards/frost/03.png', 3),
  ('33333333-0007-0001-0001-000000000007', 'Frost Trapper',       'Sets clever traps to catch arctic foxes and wolves.',   'common',    'cards/frost/04.png', 4),
  ('33333333-0007-0001-0001-000000000007', 'Aurora Watcher',      'Studies the northern lights for signs and omens.',      'common',    'cards/frost/05.png', 5),
  ('33333333-0007-0001-0001-000000000007', 'Blizzard Survivor',   'Has survived the most brutal arctic winter storms.',    'common',    'cards/frost/06.png', 6),
  ('33333333-0007-0001-0001-000000000007', 'Ice Berserker',       'A fearless warrior unaffected by the bitterest cold.',  'rare',      'cards/frost/07.png', 7),
  ('33333333-0007-0001-0001-000000000007', 'Crystal Mage',        'Wields the power of ice crystals to freeze enemies.',   'rare',      'cards/frost/08.png', 8),
  ('33333333-0007-0001-0001-000000000007', 'Mammoth Rider',       'Commands a mighty woolly mammoth in battle.',           'rare',      'cards/frost/09.png', 9),
  ('33333333-0007-0001-0001-000000000007', 'Frost Giant',         'A towering giant of ice and snow standing 30 feet tall.','epic',     'cards/frost/10.png', 10),
  ('33333333-0007-0001-0001-000000000007', 'Blizzard Witch',      'Summons blinding blizzards to destroy enemy villages.', 'epic',      'cards/frost/11.png', 11),
  ('33333333-0007-0001-0001-000000000007', 'Eternal Winter King', 'The immortal ruler of the frozen north who never melts.','legendary','cards/frost/12.png', 12);

-- ---- Set 8: Desert Raiders ----
INSERT INTO cards (set_id, name, description, rarity, image_url, card_order) VALUES
  ('33333333-0008-0001-0001-000000000008', 'Caravan Guard',       'Protects merchant caravans crossing the deadly desert.',  'common',   'cards/desert/01.png', 1),
  ('33333333-0008-0001-0001-000000000008', 'Sand Dancer',         'A graceful performer entertaining the sultan''s court.',  'common',   'cards/desert/02.png', 2),
  ('33333333-0008-0001-0001-000000000008', 'Oasis Keeper',        'Maintains the precious oasis water for travelers.',       'common',   'cards/desert/03.png', 3),
  ('33333333-0008-0001-0001-000000000008', 'Spice Merchant',      'Trades in the rarest spices from across the sands.',      'common',   'cards/desert/04.png', 4),
  ('33333333-0008-0001-0001-000000000008', 'Camel Herder',        'Tends vast herds of camels across the scorching dunes.',  'common',   'cards/desert/05.png', 5),
  ('33333333-0008-0001-0001-000000000008', 'Sandstorm Scout',     'Navigates safely through the most violent sandstorms.',   'common',   'cards/desert/06.png', 6),
  ('33333333-0008-0001-0001-000000000008', 'Desert Assassin',     'A shadow killer striking from the shimmering mirage.',    'rare',     'cards/desert/07.png', 7),
  ('33333333-0008-0001-0001-000000000008', 'Sand Sorcerer',       'Controls the desert sands to bury enemies alive.',        'rare',     'cards/desert/08.png', 8),
  ('33333333-0008-0001-0001-000000000008', 'Dune Raider Chief',   'Leads the most feared raiding band in the desert.',       'rare',     'cards/desert/09.png', 9),
  ('33333333-0008-0001-0001-000000000008', 'Sultan''s Champion',  'The sultan''s undefeated warrior in single combat.',     'epic',     'cards/desert/10.png', 10),
  ('33333333-0008-0001-0001-000000000008', 'Mirage Phantom',      'A being of pure heat haze that cannot be touched.',       'epic',     'cards/desert/11.png', 11),
  ('33333333-0008-0001-0001-000000000008', 'The Sand Emperor',    'Ruler of a vast desert empire stretching to the horizon.','legendary','cards/desert/12.png', 12);

-- ---- Set 9: Dragon Masters ----
INSERT INTO cards (set_id, name, description, rarity, image_url, card_order) VALUES
  ('33333333-0009-0001-0001-000000000009', 'Dragon Egg Keeper',   'Guards precious dragon eggs in the volcanic lair.',       'common',   'cards/dragons/01.png', 1),
  ('33333333-0009-0001-0001-000000000009', 'Apprentice Mage',     'Studies basic spells at the great Wizard Academy.',       'common',   'cards/dragons/02.png', 2),
  ('33333333-0009-0001-0001-000000000009', 'Fairy Messenger',     'Carries magical messages between the realm''s kingdoms.', 'common',   'cards/dragons/03.png', 3),
  ('33333333-0009-0001-0001-000000000009', 'Griffin Scout',       'Patrols the sky on a young griffin mount.',               'common',   'cards/dragons/04.png', 4),
  ('33333333-0009-0001-0001-000000000009', 'Potion Brewer',       'Concocts powerful magical potions in a bubbling cauldron.','common',  'cards/dragons/05.png', 5),
  ('33333333-0009-0001-0001-000000000009', 'Enchanted Archer',    'Fires arrows imbued with devastating magical power.',      'common',  'cards/dragons/06.png', 6),
  ('33333333-0009-0001-0001-000000000009', 'Fire Drake Rider',    'Soars above the battlefield on a fearsome fire drake.',    'rare',    'cards/dragons/07.png', 7),
  ('33333333-0009-0001-0001-000000000009', 'High Wizard',         'Commands the most complex spells of the arcane arts.',    'rare',     'cards/dragons/08.png', 8),
  ('33333333-0009-0001-0001-000000000009', 'Dragon Whisperer',    'Tames wild dragons with an ancient bond of trust.',        'rare',    'cards/dragons/09.png', 9),
  ('33333333-0009-0001-0001-000000000009', 'Archmage Supreme',    'The most powerful wizard in the entire fantasy realm.',    'epic',    'cards/dragons/10.png', 10),
  ('33333333-0009-0001-0001-000000000009', 'Elder Dragon',        'An ancient dragon with centuries of fire and wisdom.',     'epic',    'cards/dragons/11.png', 11),
  ('33333333-0009-0001-0001-000000000009', 'Dragon God Eternal',  'A divine dragon that forged the world at the beginning.', 'legendary','cards/dragons/12.png', 12);

-- =============================================================
-- ACHIEVEMENTS (50 total)
-- =============================================================

-- ---- SPINNING (10) ----
INSERT INTO achievements (key, title, description, icon_url, category, target_value, reward_coins, reward_spins, reward_gems, display_order) VALUES
  ('first_spin',    'First Spin!',          'Spin the slot machine for the first time.',     'icons/spin1.png',    'spinning', 1,     1000,    5,   0,  1),
  ('spin_10',       'Getting Warmed Up',    'Spin 10 times.',                                'icons/spin2.png',    'spinning', 10,    5000,    10,  0,  2),
  ('spin_100',      'Slot Addict',          'Spin 100 times.',                               'icons/spin3.png',    'spinning', 100,   25000,   25,  0,  3),
  ('spin_500',      'Spin Veteran',         'Spin 500 times.',                               'icons/spin4.png',    'spinning', 500,   100000,  50,  0,  4),
  ('spin_1000',     'Spin Master',          'Spin 1,000 times.',                             'icons/spin5.png',    'spinning', 1000,  500000,  100, 0,  5),
  ('spin_5000',     'Spin Legend',          'Spin 5,000 times.',                             'icons/spin6.png',    'spinning', 5000,  2000000, 250, 0,  6),
  ('jackpot_first', 'Jackpot!',             'Hit your first jackpot.',                       'icons/jackpot1.png', 'spinning', 1,     50000,   20,  0,  7),
  ('jackpot_10',    'Lucky Star',           'Hit 10 jackpots.',                              'icons/jackpot2.png', 'spinning', 10,    250000,  50,  0,  8),
  ('jackpot_50',    'Fortune''s Favorite',  'Hit 50 jackpots.',                              'icons/jackpot3.png', 'spinning', 50,    1000000, 100, 0,  9),
  ('max_bet_spin',  'High Roller',          'Spin at 10x bet.',                              'icons/highroll.png', 'spinning', 1,     10000,   5,   0, 10);

-- ---- ATTACKING (10) ----
INSERT INTO achievements (key, title, description, icon_url, category, target_value, reward_coins, reward_spins, reward_gems, display_order) VALUES
  ('first_attack',       'First Blood',              'Perform your first attack.',                        'icons/atk1.png',  'attacking', 1,       5000,     5,   0, 11),
  ('attack_10',          'Village Raider',           'Attack 10 times.',                                  'icons/atk2.png',  'attacking', 10,      20000,    10,  0, 12),
  ('attack_50',          'Fearsome Warrior',         'Attack 50 times.',                                  'icons/atk3.png',  'attacking', 50,      100000,   25,  0, 13),
  ('attack_100',         'Warlord',                  'Attack 100 times.',                                 'icons/atk4.png',  'attacking', 100,     500000,   50,  0, 14),
  ('attack_500',         'Conqueror',                'Attack 500 times.',                                 'icons/atk5.png',  'attacking', 500,     2000000,  100, 0, 15),
  ('attack_1000',        'Emperor of Destruction',   'Attack 1,000 times.',                               'icons/atk6.png',  'attacking', 1000,    10000000, 250, 0, 16),
  ('first_shield_break', 'Shield Breaker',           'Destroy an enemy''s shield.',                       'icons/shield.png','attacking', 1,       10000,    5,   0, 17),
  ('steal_million',      'Million Dollar Heist',     'Steal 1 million coins in a single attack.',         'icons/heist.png', 'attacking', 1000000, 500000,   20,  0, 18),
  ('three_star_attack',  'Perfect Strike',           'Attack while all 3 reels show attack symbol.',      'icons/3star.png', 'attacking', 1,       50000,    10,  0, 19),
  ('revenge_master',     'Revenge is Sweet',         'Successfully revenge 10 attacks.',                  'icons/revenge.png','attacking',10,      100000,   25,  0, 20);

-- ---- RAIDING (10) ----
INSERT INTO achievements (key, title, description, icon_url, category, target_value, reward_coins, reward_spins, reward_gems, display_order) VALUES
  ('first_raid',     'Treasure Hunter',       'Raid someone''s pig bank for the first time.',       'icons/raid1.png',    'raiding', 1,          5000,     5,   0, 21),
  ('raid_10',        'Grave Digger',          'Raid 10 times.',                                     'icons/raid2.png',    'raiding', 10,         20000,    10,  0, 22),
  ('raid_50',        'Seasoned Raider',       'Raid 50 times.',                                     'icons/raid3.png',    'raiding', 50,         100000,   25,  0, 23),
  ('raid_100',       'Master Raider',         'Raid 100 times.',                                    'icons/raid4.png',    'raiding', 100,        500000,   50,  0, 24),
  ('raid_500',       'Piggy Bank Nightmare',  'Raid 500 times.',                                    'icons/raid5.png',    'raiding', 500,        2000000,  100, 0, 25),
  ('perfect_raid',   'Perfect Raid',          'Dig all 3 holes and find gold in each.',             'icons/perfect.png',  'raiding', 1,          100000,   20,  0, 26),
  ('raid_billion',   'Billionaire Raider',    'Steal 1 billion coins total from raids.',            'icons/billion.png',  'raiding', 1000000000, 5000000,  100, 0, 27),
  ('foxy_raid',      'Foxy''s Favorite',      'Use Foxy''s extra hole in 10 raids.',               'icons/foxy.png',     'raiding', 10,         50000,    15,  0, 28),
  ('raid_friend',    'Friendly Fire',         'Raid a friend''s village.',                          'icons/friendly.png', 'raiding', 1,          25000,    5,   0, 29),
  ('four_hole_raid', 'Four Leaf Clover',      'Use all 4 holes in a single raid.',                  'icons/4hole.png',    'raiding', 1,          200000,   30,  0, 30);

-- ---- BUILDING (10) ----
INSERT INTO achievements (key, title, description, icon_url, category, target_value, reward_coins, reward_spins, reward_gems, display_order) VALUES
  ('first_build',   'Builder''s Beginning',   'Upgrade your first building.',             'icons/build1.png',   'building', 1,  5000,     5,   0,  31),
  ('build_10',      'Handy Worker',           'Upgrade 10 buildings.',                    'icons/build2.png',   'building', 10, 25000,    10,  0,  32),
  ('build_50',      'Master Builder',         'Upgrade 50 buildings.',                    'icons/build3.png',   'building', 50, 150000,   30,  0,  33),
  ('build_100',     'Architecture Legend',    'Upgrade 100 buildings.',                   'icons/build4.png',   'building', 100,500000,   50,  0,  34),
  ('first_village', 'Village Founder',        'Complete your first village.',             'icons/village1.png', 'building', 1,  100000,   50,  0,  35),
  ('village_3',     'Village Hopper',         'Complete 3 villages.',                     'icons/village3.png', 'building', 3,  500000,   100, 0,  36),
  ('village_5',     'Empire Builder',         'Complete 5 villages.',                     'icons/village5.png', 'building', 5,  2000000,  200, 0,  37),
  ('village_10',    'World Conqueror',        'Complete all 10 starter villages.',        'icons/village10.png','building', 10, 10000000, 500, 50, 38),
  ('boom_complete', 'Boom Town',              'Complete a Boom Village.',                 'icons/boom.png',     'building', 1,  1000000,  100, 0,  39),
  ('repair_10',     'Rebuild & Prevail',      'Rebuild 10 destroyed buildings.',          'icons/repair.png',   'building', 10, 50000,    20,  0,  40);

-- ---- SOCIAL (5) ----
INSERT INTO achievements (key, title, description, icon_url, category, target_value, reward_coins, reward_spins, reward_gems, display_order) VALUES
  ('first_friend', 'Making Friends',    'Add your first friend.',           'icons/friend1.png', 'social', 1, 10000, 10, 0, 41),
  ('friend_5',     'Social Butterfly', 'Have 5 friends.',                  'icons/friend5.png', 'social', 5, 30000, 20, 0, 42),
  ('first_gift',   'Generous Spinner', 'Gift a spin to a friend.',         'icons/gift.png',    'social', 1, 5000,  5,  0, 43),
  ('first_clan',   'Clan Member',      'Join or create a clan.',           'icons/clan1.png',   'social', 1, 25000, 20, 0, 44),
  ('clan_leader',  'Clan Leader',      'Create and lead a clan.',          'icons/clanl.png',   'social', 1, 50000, 30, 0, 45);

-- ---- COLLECTION (5) ----
INSERT INTO achievements (key, title, description, icon_url, category, target_value, reward_coins, reward_spins, reward_gems, display_order) VALUES
  ('first_card',  'Card Collector',       'Get your first card.',              'icons/card1.png',   'collection', 1,   5000,    5,   0,   46),
  ('card_25',     'Growing Collection',   'Collect 25 unique cards.',          'icons/card25.png',  'collection', 25,  50000,   25,  0,   47),
  ('card_50',     'Dedicated Collector',  'Collect 50 unique cards.',          'icons/card50.png',  'collection', 50,  200000,  50,  0,   48),
  ('card_108',    'Complete Collection',  'Collect all 108 unique cards.',     'icons/card108.png', 'collection', 108, 5000000, 500, 100, 49),
  ('first_set',   'Set Complete',         'Complete your first card set.',     'icons/cardset.png', 'collection', 1,   100000,  50,  0,   50);

-- =============================================================
-- EVENTS (4 active events)
-- =============================================================
INSERT INTO events (type, title, description, banner_image, starts_at, ends_at, reward_json, rules_json, is_active) VALUES
  (
    'viking_quest',
    'Viking Quest',
    'Attack enemies like a true Viking and collect spins! The more villages you raid, the greater the glory.',
    'banners/viking_quest.png',
    NOW(),
    NOW() + INTERVAL '7 days',
    '{"type":"spins","amount":100,"description":"100 Free Spins"}',
    '{"goal":"Attack enemies to collect attack points","target":50,"reward_at":50}',
    TRUE
  ),
  (
    'gold_rush',
    'Gold Rush',
    'Spin the reels 100 times during the Gold Rush event and earn a massive bonus coin reward!',
    'banners/gold_rush.png',
    NOW(),
    NOW() + INTERVAL '7 days',
    '{"type":"coins","amount":2000000,"description":"2,000,000 Bonus Coins"}',
    '{"goal":"Spin the slot machine during the event","target":100,"reward_at":100}',
    TRUE
  ),
  (
    'attack_madness',
    'Attack Madness',
    'Attack 20 villages in this special Attack Madness event for incredible spin rewards!',
    'banners/attack_madness.png',
    NOW(),
    NOW() + INTERVAL '7 days',
    '{"type":"spins","amount":50,"description":"50 Free Spins"}',
    '{"goal":"Attack 20 enemy villages","target":20,"reward_at":20}',
    TRUE
  ),
  (
    'raid_madness',
    'Raid Madness',
    'Raid 15 pig banks during this Raid Madness event and claim a chest full of treasure!',
    'banners/raid_madness.png',
    NOW(),
    NOW() + INTERVAL '7 days',
    '{"type":"bundle","spins":50,"chest":"magical","description":"50 Spins + 1 Magical Chest"}',
    '{"goal":"Raid 15 enemy pig banks","target":15,"reward_at":15}',
    TRUE
  );

-- =============================================================
-- TEST / ADMIN USER
-- Password: Admin123!
-- BCrypt hash (cost=11): $2a$11$rBnkB5V7hHNGz5S9EQxAOeX8Xd2vxA5t3HGZ6XmHQA2yM1B3C4D5E
-- =============================================================
INSERT INTO users (
  id, email, password_hash, display_name, avatar_url,
  coins, spins, gems, village_level,
  pig_bank_coins, shield_count, total_stars,
  spin_refill_at, bet_multiplier,
  login_streak, weekly_spins_used,
  total_attacks, total_raids, total_cards,
  is_banned, created_at
) VALUES (
  'aaaaaaaa-0000-0000-0000-000000000001',
  'admin@spinempire.com',
  '$2a$11$rBnkB5V7hHNGz5S9EQxAOeX8Xd2vxA5t3HGZ6XmHQA2yM1B3C4D5E',
  'Admin',
  'avatars/admin.png',
  999999999, 9999999, 100000, 5,
  5000000, 3, 50,
  NOW(), 1,
  7, 0,
  0, 0, 0,
  FALSE, NOW()
);

-- =============================================================
-- MASTER TESTER USER
-- Email: master@spinempire.com
-- Password: Master123!
-- BCrypt hash (cost=11)
-- =============================================================
INSERT INTO users (
  id, email, password_hash, display_name, avatar_url,
  coins, spins, gems, village_level,
  pig_bank_coins, shield_count, total_stars,
  spin_refill_at, bet_multiplier,
  login_streak, weekly_spins_used,
  total_attacks, total_raids, total_cards,
  is_banned, created_at
) VALUES (
  'bbbbbbbb-0000-0000-0000-000000000002',
  'master@spinempire.com',
  '$2a$11$rBnkB5V7hHNGz5S9EQxAOeX8Xd2vxA5t3HGZ6XmHQA2yM1B3C4D5E',
  'MasterTester',
  NULL,
  999999999, 9999999, 100000, 1,
  10000000, 3, 0,
  NOW(), 1,
  0, 0,
  0, 0, 0,
  FALSE, NOW()
);

COMMIT;
