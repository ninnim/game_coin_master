# AGENT 3 — FRONTEND GAME AGENT
## Mission: Build the complete Flutter + Flame game "Spin Empire"

You are the **Frontend Game Agent** for "Spin Empire" — a Coin Master clone game.
Your ONLY job is to create ALL frontend files in `d:/coin_master_clone/frontend/`.
Do NOT touch any other folder.

---

## Technology Stack
- **Flutter SDK**: 3.19+
- **Game Engine**: Flame 1.17+ (2D game engine for Flutter)
- **State Management**: Riverpod 2.x (flutter_riverpod)
- **Audio**: flame_audio (FlameAudio.bgm, FlameAudio.play)
- **Animations**: flutter_animate + Flame particle systems
- **HTTP**: dio (with interceptors for JWT)
- **SignalR**: signalr_netcore
- **Storage**: flutter_secure_storage (JWT token)
- **Navigation**: go_router
- **Particles**: particles_flutter or custom Flame particles
- **Haptics**: flutter_vibrate or vibration package

---

## pubspec.yaml

```yaml
name: coin_master_flutter
description: Spin Empire - Coin Master Clone

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Game Engine
  flame: ^1.17.0
  flame_audio: ^2.10.0
  
  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  
  # Navigation
  go_router: ^13.2.0
  
  # Network
  dio: ^5.4.3
  signalr_netcore: ^1.3.6
  
  # Storage
  flutter_secure_storage: ^9.0.0
  
  # UI & Animations
  flutter_animate: ^4.5.0
  cached_network_image: ^3.3.1
  
  # Utils
  intl: ^0.19.0
  vibration: ^1.8.4
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/images/slots/
    - assets/images/buildings/
    - assets/images/pets/
    - assets/images/cards/
    - assets/images/ui/
    - assets/images/villages/
    - assets/audio/sfx/
    - assets/audio/music/
    - assets/fonts/
    - assets/data/
```

---

## Complete Folder Structure

```
d:/coin_master_clone/frontend/coin_master_flutter/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app.dart                           # MaterialApp + GoRouter setup
│   │
│   ├── game/                              # FLAME GAME ENGINE
│   │   ├── spin_empire_game.dart          # Main FlameGame class
│   │   ├── components/
│   │   │   ├── slot_machine/
│   │   │   │   ├── slot_machine_component.dart    # Container for 3 reels
│   │   │   │   ├── slot_reel_component.dart       # Single spinning reel
│   │   │   │   └── slot_symbol_component.dart     # Individual symbol sprite
│   │   │   ├── village/
│   │   │   │   ├── village_scene_component.dart   # Village world renderer
│   │   │   │   ├── building_component.dart        # Tappable building
│   │   │   │   └── sky_component.dart             # Animated sky/weather
│   │   │   ├── pets/
│   │   │   │   └── pet_companion_component.dart   # Animated pet companion
│   │   │   └── effects/
│   │   │       ├── coin_shower_effect.dart        # Coins flying on win
│   │   │       ├── attack_effect.dart             # Hammer/cannon animation
│   │   │       ├── raid_effect.dart               # Digging animation
│   │   │       ├── shield_effect.dart             # Shield bubble animation
│   │   │       └── jackpot_effect.dart            # Full screen jackpot
│   │   │
│   │   ├── overlays/
│   │   │   ├── hud_overlay.dart                   # Top bar: coins, spins, shields
│   │   │   ├── spin_button_overlay.dart           # Big SPIN button area
│   │   │   ├── bet_selector_overlay.dart          # 1x/2x/3x/5x/10x selector
│   │   │   ├── spin_result_overlay.dart           # Result popup (attack/raid/shield)
│   │   │   ├── attack_picker_overlay.dart         # Pick target to attack
│   │   │   ├── raid_overlay.dart                  # Dig holes interface
│   │   │   └── revenge_overlay.dart               # Revenge option popup
│   │   │
│   │   └── audio/
│   │       ├── audio_manager.dart                 # Centralized audio controller
│   │       └── sound_ids.dart                     # String constants for sounds
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   ├── splash_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── providers/
│   │   │       └── auth_provider.dart
│   │   │
│   │   ├── main_game/                     # The main game screen
│   │   │   ├── screens/
│   │   │   │   └── main_game_screen.dart  # Flame GameWidget wrapper
│   │   │   └── providers/
│   │   │       ├── spin_provider.dart
│   │   │       ├── player_state_provider.dart
│   │   │       └── attack_raid_provider.dart
│   │   │
│   │   ├── village/
│   │   │   ├── screens/
│   │   │   │   ├── village_map_screen.dart       # World map of all villages
│   │   │   │   └── village_detail_screen.dart    # Current village building view
│   │   │   └── providers/
│   │   │       └── village_provider.dart
│   │   │
│   │   ├── cards/
│   │   │   ├── screens/
│   │   │   │   ├── card_collection_screen.dart   # Album view of all cards
│   │   │   │   ├── chest_shop_screen.dart        # Buy and open chests
│   │   │   │   └── trade_screen.dart             # Trade with friends
│   │   │   └── providers/
│   │   │       └── card_provider.dart
│   │   │
│   │   ├── pets/
│   │   │   ├── screens/
│   │   │   │   └── pets_screen.dart              # Pet management
│   │   │   └── providers/
│   │   │       └── pet_provider.dart
│   │   │
│   │   ├── social/
│   │   │   ├── screens/
│   │   │   │   ├── friends_screen.dart
│   │   │   │   ├── leaderboard_screen.dart
│   │   │   │   └── clans_screen.dart
│   │   │   └── providers/
│   │   │       └── social_provider.dart
│   │   │
│   │   ├── events/
│   │   │   ├── screens/
│   │   │   │   └── events_screen.dart            # Active events calendar
│   │   │   └── providers/
│   │   │       └── event_provider.dart
│   │   │
│   │   ├── achievements/
│   │   │   ├── screens/
│   │   │   │   └── achievements_screen.dart
│   │   │   └── providers/
│   │   │       └── achievement_provider.dart
│   │   │
│   │   ├── shop/
│   │   │   ├── screens/
│   │   │   │   └── shop_screen.dart              # Buy spins, gems
│   │   │   └── providers/
│   │   │       └── shop_provider.dart
│   │   │
│   │   └── profile/
│   │       ├── screens/
│   │       │   └── profile_screen.dart
│   │       └── providers/
│   │           └── profile_provider.dart
│   │
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart            # Dio setup with JWT interceptor
│   │   │   ├── api_endpoints.dart         # All URL constants
│   │   │   ├── signalr_service.dart       # SignalR connection manager
│   │   │   └── api_exception.dart         # Error model
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── village_model.dart
│   │   │   ├── building_model.dart
│   │   │   ├── spin_result_model.dart
│   │   │   ├── card_model.dart
│   │   │   ├── pet_model.dart
│   │   │   ├── attack_model.dart
│   │   │   ├── raid_model.dart
│   │   │   ├── clan_model.dart
│   │   │   ├── event_model.dart
│   │   │   ├── achievement_model.dart
│   │   │   └── player_state_model.dart    # Full game state
│   │   └── storage/
│   │       └── secure_storage.dart        # JWT token storage
│   │
│   ├── shared/
│   │   ├── theme/
│   │   │   ├── app_colors.dart            # Full color palette
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_theme.dart
│   │   ├── widgets/
│   │   │   ├── glass_card.dart            # Glassmorphism card
│   │   │   ├── glass_button.dart          # Primary/secondary buttons
│   │   │   ├── coin_display.dart          # Animated coin counter
│   │   │   ├── spin_counter.dart          # Spins remaining display
│   │   │   ├── shield_indicator.dart      # Shield icons row
│   │   │   ├── rarity_badge.dart          # Card rarity chip
│   │   │   ├── loading_skeleton.dart      # Shimmer skeleton
│   │   │   ├── empty_state.dart           # Empty state widget
│   │   │   ├── toast_notification.dart    # Game-style toasts
│   │   │   └── user_avatar.dart           # Avatar with level badge
│   │   └── animations/
│   │       ├── number_ticker.dart         # Animated number counting up
│   │       └── glow_effect.dart           # Cyan glow wrapper
│   │
│   └── router.dart                        # GoRouter configuration
│
└── assets/ (placeholder folders — filled by art agent or using placeholder PNGs)
    ├── images/
    │   ├── slots/                         # coin.png, attack.png, raid.png, shield.png, energy.png, jackpot.png
    │   ├── buildings/                     # medieval_castle_0.png ... _4.png (5 states per building)
    │   ├── pets/                          # foxy.png, tiger.png, rhino.png (with animation frames)
    │   ├── cards/                         # card_back.png + individual card images
    │   ├── villages/                      # village backgrounds
    │   └── ui/                            # buttons, icons, backgrounds
    ├── audio/
    │   ├── sfx/                           # See sound list below
    │   └── music/                         # village_bgm.mp3, spin_bgm.mp3, victory.mp3
    └── fonts/
        └── GameFont.ttf
```

---

## Color Palette (app_colors.dart)

```dart
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0A1A);
  static const Color surface = Color(0xFF1A1030);
  static const Color surfaceLight = Color(0xFF241840);
  
  // Gold (primary currency)
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFF176);
  static const Color goldDark = Color(0xFFFF8F00);
  
  // Purple (royal theme)
  static const Color purple = Color(0xFF6A1B9A);
  static const Color purpleLight = Color(0xFFCE93D8);
  static const Color purpleDark = Color(0xFF4A148C);
  
  // Status colors
  static const Color emerald = Color(0xFF00C853);   // shields, success
  static const Color crimson = Color(0xFFD50000);   // attacks, danger
  static const Color cyan = Color(0xFF00E5FF);       // special/magic
  static const Color amber = Color(0xFFFFB300);      // warnings, rare
  
  // Card rarities
  static const Color rarityCommon = Color(0xFF90A4AE);
  static const Color rarityRare = Color(0xFF42A5F5);
  static const Color rarityEpic = Color(0xFFAB47BC);
  static const Color rarityLegendary = Color(0xFFFF8F00);
  
  // Glass effects
  static const Color cardGlass = Color(0xB31A1030);
  static const Color borderGlow = Color(0x4DFFD700);
  static const Color borderGlowCyan = Color(0x4D00E5FF);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textGold = Color(0xFFFFD700);
}
```

---

## Main Game Screen Implementation

### main_game_screen.dart
The main game screen wraps the Flame `GameWidget` with Flutter UI overlays:

```dart
// Layout (bottom-up):
// 1. Flame GameWidget (full screen background) — shows village scene
// 2. HUD overlay (top): coins counter | village name | shields | spins
// 3. Slot machine area (center): 3 reels with symbols
// 4. Spin button area (bottom): big SPIN button + bet selector + pet indicator
// 5. Navigation bar (very bottom): Home/Cards/Social/Events/Profile

// The Flame game renders:
// - Village background (parallax scroll)
// - 9 building sprites positioned on village
// - Animated pet companion (bottom-left corner)
// - Particle effects (coins, attacks, raids)
// - Attack/Raid animations (full-screen overlays in Flame)
```

---

## Slot Machine Component (CRITICAL — Most Important Part)

### slot_reel_component.dart — Physics-based reel
```dart
// Each reel is a vertical strip of 7 symbols that "spins"
// Physics simulation:
// 1. On spin start: set high velocity (5000 px/s)
// 2. Apply deceleration curve (ease-out-quart)
// 3. Snap to nearest symbol position with spring bounce
// 4. Stagger: Reel 1 stops first, then Reel 2 (400ms later), then Reel 3 (800ms later)
// 5. Each stop plays "clunk" sound + symbol flash effect

// Symbol sprite sheet: 7 symbols in loop
// Symbols: coin (gold), attack (hammer), raid (shovel), shield (shield), 
//          energy (lightning bolt), jackpot (star), blank

// Visual effects per symbol:
// - coin: golden glow when landing
// - attack: red pulse when landing
// - raid: brown dust puff when landing
// - shield: blue shimmer when landing
// - energy: electric crackle when landing
// - jackpot: rainbow glow + screen flash

// When 3 matching symbols: JACKPOT animation
// - All 3 reels flash in sync
// - Coins shower from top of screen
// - Dramatic JACKPOT text with scale bounce
// - Camera shake
// - 3-second celebration before result is processed
```

---

## Audio Manager Implementation

### audio_manager.dart
```dart
class AudioManager {
  static const String SPIN_START = 'sfx/spin_start.mp3';
  static const String REEL_STOP = 'sfx/reel_stop.mp3';
  static const String COIN_COLLECT = 'sfx/coins.mp3';
  static const String JACKPOT = 'sfx/jackpot.mp3';
  static const String ATTACK = 'sfx/attack_boom.mp3';
  static const String SHIELD_BLOCK = 'sfx/shield_block.mp3';
  static const String RAID_DIG = 'sfx/raid_dig.mp3';
  static const String RAID_GOLD = 'sfx/gold_found.mp3';
  static const String BUILD_COMPLETE = 'sfx/build.mp3';
  static const String VILLAGE_COMPLETE = 'sfx/village_complete.mp3';
  static const String CARD_REVEAL = 'sfx/card_reveal.mp3';
  static const String PET_ACTIVATE = 'sfx/pet_activate.mp3';
  static const String LEVEL_UP = 'sfx/level_up.mp3';
  static const String ERROR = 'sfx/error.mp3';
  static const String BUTTON_CLICK = 'sfx/click.mp3';
  
  // BGM tracks
  static const String BGM_VILLAGE = 'music/village_peace.mp3';
  static const String BGM_SPIN = 'music/spin_tension.mp3';
  static const String BGM_VICTORY = 'music/victory_fanfare.mp3';
  
  // FlameAudio.bgm.play() for looping music
  // FlameAudio.play() for one-shot SFX
  // Implement volume control + mute toggle stored in SharedPreferences
}
```

**IMPORTANT**: Since real audio files won't exist yet, create placeholder audio files or generate them.
Use `flutter_tts` as fallback for missing audio. All audio calls must be wrapped in try-catch
to not crash if files are missing.

---

## Key Screens — Detailed Requirements

### Splash Screen
- Dark background with centered logo "SPIN EMPIRE"
- Logo text has animated golden glow pulse (2s loop)
- Subtle star particle field in background (Flame or custom painter)
- Auto-navigate to login or main game after 2.5 seconds
- Check JWT token validity on load

### Main Game Screen (Village + Slot Machine)
```
┌─────────────────────────────────┐
│ [💰 1,234,567] Village 1 [🛡🛡] [⚡50]│  ← HUD
├─────────────────────────────────┤
│                                 │
│    VILLAGE SCENE (Flame)        │  ← Background: village with buildings
│    Buildings are tappable       │
│    Pet walks around bottom      │
│                                 │
├─────────────────────────────────┤
│  ┌───┐    ┌───┐    ┌───┐       │
│  │ ⚔ │    │ 🪙 │    │ 🪙 │       │  ← Slot Machine (3 reels)
│  └───┘    └───┘    └───┘       │
│           ═══════               │  ← Payline indicator
├─────────────────────────────────┤
│  [BET: 1x ▼]        [🦊 FOXY]   │  ← Bet selector + active pet
│                                 │
│       ╔═══════════╗             │
│       ║   SPIN    ║             │  ← SPIN button (large, gold, glowing)
│       ╚═══════════╝             │
│         50 spins left           │
├─────────────────────────────────┤
│ [🏘 HOME] [🃏 CARDS] [👥 SOCIAL] [🏆 EVENTS] [👤 PROFILE] │
└─────────────────────────────────┘
```

### Attack Flow
1. User gets "ATTACK" result on reels → reel flashes red
2. AttackPickerOverlay slides up:
   - Shows 5 random player cards with avatar, name, village level
   - "ATTACK" button on each card (red, glowing)
3. User taps attack → confirmation "Crush {Name}'s village?"
4. API call → attack_effect.dart plays:
   - Cannon shoots across screen
   - Target building crumbles (damage sprite)
   - Coins shower with "STOLEN: +X,XXX" text
5. If blocked by shield: shield bubble appears, deflects cannon, "BLOCKED!" text

### Raid Flow
1. User gets "RAID" result → reels flash brown/gold
2. RaidOverlay full-screen:
   - Shows 3x3 grid of dirt patches (9 holes)
   - Pig in center
   - User taps to dig holes (tap animation: shovel dig)
   - Foxy pet: shows 4th hole option
3. Each tapped hole: dig animation, reveal coins or empty (coin amount floats up)
4. Total coins stolen shown at end with "RAIDED!" banner

### Card Collection Screen
- Grid of card cards (album style)
- Each card: shows image if owned, grey silhouette if not
- Rarity border glow: common=grey, rare=blue, epic=purple, legendary=gold
- Card sets organized in tabs
- Set progress bar at top (X/12 cards)
- "Complete!" banner on finished sets
- Tap card: large preview modal with lore description

### Village Map Screen
- Scrollable horizontal world map
- Villages shown as islands/locations
- Completed villages: bright, with checkmark star
- Current village: pulsing gold outline
- Future villages: dark/locked
- Tap village: shows "Village X: [Name]" popup with theme description

### Pets Screen
- 3 pet cards (Foxy, Tiger, Rhino)
- Active pet has gold glow border
- Each card: animated pet sprite, level badge, XP bar, ability description
- "ACTIVATE" button (cyan) if not active
- "FEED" button: shows treats count, feeding animation with hearts

### Leaderboard Screen
- 3 tabs: Coins / Village Level / Cards Collected
- Filter: Weekly / All Time
- Top 3 get special gold/silver/bronze crown frames
- Your rank highlighted in gold row even if outside top 10
- Rank number, avatar, name, value, animated count-up on load

---

## Animation Specifications

### Coin Shower (coin_shower_effect.dart — Flame ParticleSystemComponent)
```dart
// On large coin win:
// - 50 coin sprites spawn at top-center
// - Each has random horizontal velocity (-200 to 200)
// - Gravity: 300 px/s²
// - Spin rotation on each coin
// - Fade out on reaching bottom
// - Duration: 1.5 seconds total
// - Coins make soft "ding" sounds as they land
```

### Building Destruction Animation
```dart
// When a building is attacked:
// 1. Red damage flash on building sprite (0.2s)
// 2. Crack overlay appears on building
// 3. Dust particle burst from building center
// 4. Building changes to destroyed sprite (broken/rubble state)
// 5. Shake animation on entire village scene (0.3s, ±5px)
```

### Village Complete Animation
```dart
// 1. All buildings light up gold sequentially
// 2. Large "VILLAGE COMPLETE!" text bursts from center
// 3. Fireworks particle effect (5 bursts)
// 4. Stars fly to total stars counter
// 5. Transition to next village after 3 seconds
// Victory fanfare music plays
```

### Slot Spin Button States
```dart
// Normal: gold gradient, "SPIN" text, subtle glow pulse
// Press: scale to 0.92, darker shade
// Spinning: disabled, reels are animating
// No spins: grey, "WAIT X:XX" countdown timer displayed
// Jackpot: rainbow color-cycle glow
```

---

## SignalR Integration (signalr_service.dart)

```dart
class SignalRService {
  // Connect on app start after login
  // Hub URL: http://localhost:5001/hubs/game (dev) or Railway URL (prod)
  // Auto-reconnect with exponential backoff
  
  // Event listeners:
  // "OnAttacked" → show toast + trigger AttackReceivedOverlay
  // "OnRaided" → show toast + update coin display
  // "OnSpinGifted" → show toast + update spin counter
  // "OnTradeRequest" → show badge on Cards tab
  // "OnFriendRequest" → show badge on Social tab
  // "OnAchievementUnlocked" → show achievement popup
}
```

---

## Navigation (router.dart)

```dart
// Routes:
// /splash → SplashScreen
// /login → LoginScreen
// /register → RegisterScreen
// /game → MainGameScreen (requires auth)
// /village-map → VillageMapScreen
// /cards → CardCollectionScreen
// /chests → ChestShopScreen
// /trade → TradeScreen
// /pets → PetsScreen
// /friends → FriendsScreen
// /leaderboard → LeaderboardScreen
// /clans → ClansScreen
// /events → EventsScreen
// /achievements → AchievementsScreen
// /shop → ShopScreen
// /profile → ProfileScreen
// /profile/:userId → PublicProfileScreen

// Auth guard: redirect to /login if no JWT token
// Bottom navigation tabs: Home(game), Cards, Social, Events, Profile
```

---

## API Client (api_client.dart)

```dart
class ApiClient {
  final Dio _dio;
  static const String baseUrl = 'http://localhost:5001'; // Dev
  // Railway URL from environment/config for production

  // Interceptors:
  // 1. AuthInterceptor: adds "Authorization: Bearer {token}" header
  // 2. ErrorInterceptor: converts DioException → ApiException with user-friendly messages
  // 3. RetryInterceptor: retry once on 503/network errors

  // Key methods mirroring all API endpoints
}
```

---

## Placeholder Assets Strategy

Since real game art won't be available, implement:

1. **Slot Symbols**: Use emoji rendered to canvas or simple geometric shapes
   - Coin: golden circle with "$" 
   - Attack: red circle with "⚔"
   - Raid: brown circle with "⛏"
   - Shield: blue circle with "🛡"
   - Energy: yellow circle with "⚡"
   - Jackpot: rainbow circle with "★"

2. **Buildings**: Colored rectangles with building name text, 5 states (0=empty lot, 1-4=progressively more built)

3. **Pets**: Simple animal emoji rendered to canvas

4. **Cards**: Colored gradient rectangles with card name, rarity-colored border

5. **Backgrounds**: LinearGradient sky colors per village theme

6. **Audio**: Use `audioplayers` with asset paths; create 1-second silent placeholder MP3s for missing files

**ALL placeholder code must be wrapped in a `#if PLACEHOLDER` style comment so real assets can drop in.**

---

## Empty States (Required for All List Screens)

```dart
// Friends: People icon + "No friends yet. Invite your friends to join!"
// Leaderboard loading: Skeleton rows (5 shimmer rows)
// Cards: Locked card icon + "Open chests to collect cards!"
// Events: Calendar icon + "No events active right now. Check back soon!"
// Achievements: Trophy icon + "Complete actions to earn achievements!"
// Notifications: Bell icon + "You're all caught up!"
```

---

## Performance Requirements

- Target: 60 FPS on mid-range Android (Pixel 3a equivalent)
- Slot machine reels: use SpriteAnimationComponent with pre-loaded sprite sheet
- Village scene: cache all building sprites on load, never load from disk during gameplay
- Particle systems: max 100 particles simultaneously
- Audio: preload all SFX on game start, use pool for frequently played sounds (reel_stop)
- Network: cache player state for 5 seconds; don't re-fetch on every reel stop

---

## Configuration (lib/core/config.dart)

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL', 
    defaultValue: 'http://10.0.2.2:5001' // Android emulator localhost
  );
  static const String signalRUrl = '$apiBaseUrl/hubs/game';
}
// For iOS simulator: use 'http://localhost:5001'
// For real device: use computer's local IP e.g. 'http://192.168.1.x:5001'
```

---

## IMPORTANT RULES
- Every screen must have loading, error, and empty states
- NEVER hardcode user IDs or tokens
- Secure JWT storage using flutter_secure_storage (not SharedPreferences)
- All API calls must handle errors and show user-friendly messages via toast
- Spin button must be disabled during API call to prevent double-spin
- Use const constructors everywhere possible for performance
- Dispose all controllers, timers, and listeners in widget dispose()
- SignalR must reconnect automatically on app resume from background
- Game screen must NOT rebuild on every frame — use Flame overlays for HUD
- All coin/number displays must use NumberFormat with comma separators
- Support both dark/light mode? NO — game is always dark theme

Start immediately. Create the COMPLETE Flutter project with all files.
The game must be runnable with `flutter run` after creating the project.
Every screen listed must be implemented — no placeholder screens.
Focus on making the slot machine animation feel GREAT — that is the core mechanic.
