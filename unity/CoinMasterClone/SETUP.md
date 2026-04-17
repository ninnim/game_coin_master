# Unity Setup Guide — Step-by-Step

All C# scripts are already written. This guide walks through what to build in the Unity Editor to bring the scenes to life.

## 1. Open the project

1. Install **Unity Hub**
2. Install **Unity 2022.3.20f1 LTS** (or any 2022.3 LTS)
3. In Unity Hub → **Open** → select `unity/CoinMasterClone/`
4. Unity will import the project and resolve packages (takes a few minutes on first open)

On first open, verify these packages are installed (Window → Package Manager):
- TextMeshPro
- Newtonsoft.Json (`com.unity.nuget.newtonsoft-json`)
- Universal RP
- Input System

## 2. Configure the backend URL

Open `Assets/Scripts/Api/ApiEndpoints.cs` and set `BaseUrl` to your backend:

```csharp
public const string BaseUrl = "https://your-railway-url.up.railway.app";
// or for local dev:
// public const string BaseUrl = "http://localhost:5000";
```

For local dev on Android, use your PC's LAN IP (e.g. `http://192.168.1.10:5000`) since `localhost` on the device points to the device.

## 3. Create the Boot scene

This scene holds singletons that survive across scene loads.

1. File → New Scene → **Basic (URP)** → save as `Assets/Scenes/Boot.unity`
2. Create empty GameObject **GameRoot**
3. As children of GameRoot add:
   - **ApiClient** — attach `ApiClient.cs`
   - **GameManager** — attach `GameManager.cs`
   - **AudioManager** — attach `AudioManager.cs`. Drag your AudioClips into the fields (see section 8 for sources).
4. Add a simple script that loads `Login` scene on Start, OR just make the Boot scene auto-load `Login` via an empty GameObject with a one-line bootstrap.

Add Boot to **File → Build Settings → Scenes in Build** as **index 0**.

## 4. Create the Login scene

1. New scene → save as `Assets/Scenes/Login.unity`
2. Add a Canvas (Screen Space - Overlay)
3. Inside the canvas create:
   - `TMP_InputField` for **Email**
   - `TMP_InputField` for **Password** (Content Type: Password)
   - `TMP_InputField` for **Display Name** (register only)
   - Two `Button`s: **Login**, **Register**
   - A `TextMeshProUGUI` for status messages
4. Create empty GameObject **AuthController**, attach `AuthController.cs`
5. Drag the Canvas children into the matching inspector fields

## 5. Create the MainGame scene (the slot machine)

This is the centerpiece. Save as `Assets/Scenes/MainGame.unity`.

### 5.1 Scene hierarchy

```
MainCamera (position 0, 0.3, -5, FOV 42, rotation (0,0,0))
DirectionalLight      (key light, cast shadows on)
PointLight_Gold       (position ±2.5, 1, 2.5, color #FFC107, intensity 2.5)
PointLight_Purple     (position 2.5, -1, 2.5, color #7B2FBE, intensity 2)

SlotMachine (empty GameObject at origin)
├── Frame_Gold        (ExtrudeGeometry / imported cabinet mesh with gold PBR material)
├── Backdrop          (dark plane behind reels)
├── Reel_0            (empty GameObject, x = -1.1)
│   └── SymbolRing    (empty child — this is what rotates)
│       ├── Symbol_0  (Quad with Coin texture — position y = sin(0°)·R, z = cos(0°)·R)
│       ├── Symbol_1  (Quad with Attack texture — angle 60°)
│       ├── Symbol_2  (Quad with Raid texture — angle 120°)
│       ├── Symbol_3  (Quad with Shield texture — angle 180°)
│       ├── Symbol_4  (Quad with Energy texture — angle 240°)
│       └── Symbol_5  (Quad with Jackpot texture — angle 300°)
├── Reel_1            (x = 0, same ring structure)
└── Reel_2            (x = 1.1, same ring structure)

Canvas_HUD (Screen Space - Overlay)
├── CoinText, SpinText, LevelText, ShieldIcons[3]
├── BetPanel (- button, BetText, + button)
└── SpinButton (large button at bottom)

Canvas_WinEffect (Screen Space - Overlay, overlay disabled by default)
├── TitleText, AmountText, IconText
└── (optional) ParticleSystems
```

### 5.2 Build the symbol ring (important!)

For each reel, the 6 symbol quads must be arranged in a ring around the X-axis:

| Symbol index | Backend key | Ring angle | Y offset | Z offset | Plane rotation (X-axis) |
|:-:|:--|:-:|:-:|:-:|:-:|
| 0 | coin_* | 0° | 0 | R | 0° |
| 1 | attack | 60° | sin(60°)·R | cos(60°)·R | 60° |
| 2 | raid | 120° | sin(120°)·R | cos(120°)·R | 120° |
| 3 | shield | 180° | 0 | -R | 180° |
| 4 | energy | 240° | sin(240°)·R | cos(240°)·R | 240° |
| 5 | jackpot | 300° | sin(300°)·R | cos(300°)·R | 300° |

Use R = 0.55 (reel radius). Rotating `SymbolRing.rotation.x` by 60° cycles one symbol position.

**The order above MUST match** `SlotMachineController.SymbolIndex()` — do not reorder.

### 5.3 Wire up the scripts

| GameObject | Script | Inspector fields |
|------------|--------|------------------|
| SlotMachine | `SlotMachineController` | Drag Reel_0, Reel_1, Reel_2 into `reels[]` |
| Reel_0 | `ReelController` | `reelIndex=0`, drag its SymbolRing child |
| Reel_1 | `ReelController` | `reelIndex=1`, drag its SymbolRing |
| Reel_2 | `ReelController` | `reelIndex=2`, drag its SymbolRing |
| Canvas_HUD | `HUDController` | Drag the 3 TMP texts + 3 shield images |
| BetPanel | `BetSelector` | Drag the two buttons and bet text |
| SpinButton | `SpinButton` | Drag SlotMachine + WinEffect + label TMP |
| Canvas_WinEffect | `WinEffectController` | Drag overlay root + title/amount/icon texts |

Add MainGame to **Build Settings** as index 2.

## 6. Create the Attack scene

1. Save as `Assets/Scenes/Attack.unity`
2. Build a simple 3D village: a ground plane, 5–9 building meshes (cubes for now, or free asset-store models later)
3. Place a hammer mesh high above the scene as `Hammer`
4. Canvas with: target name text, result panel (hidden), continue button
5. Add empty GameObject **AttackScreenController** with the script attached
6. Drag all building GameObjects into `buildings[]`, hammer into `hammer`, UI elements into fields
7. Optional: drag in a ParticleSystem prefab for the explosion

Add to Build Settings as index 3.

## 7. Create the Raid scene

1. Save as `Assets/Scenes/Raid.unity`
2. Layout 9 mound GameObjects in a 3×3 grid (each with a Collider and the `HoleTile.cs` script)
3. Each HoleTile needs:
   - `moundMesh` — dirt pile visible before digging
   - `dugMesh` — hole visible after digging
   - `coinText` — TMP text for "+X coins" or "empty"
   - `selectedHighlight` — glow when picked
4. Place a pig 3D model anywhere as `pig`
5. Create a canvas with target name, pig-bank text, instruction text, result panel, continue button
6. Add empty GameObject **RaidScreenController**, attach the script, wire the 9 tiles into `tiles[]` in **order 0..8 (left→right, top→bottom)**

Add to Build Settings as index 4.

## 8. Create the Village scene

1. Save as `Assets/Scenes/Village.unity`
2. Create 9 BuildingTile GameObjects (one per building in the current village)
3. Each has 5 **child GameObjects** as level stages:
   - `[0]` Construction site (scaffolding)
   - `[1]` Small version
   - `[2]` Medium
   - `[3]` Large
   - `[4]` Fully upgraded (with gold trim / particle glow)
4. Only one stage is visible at a time — `BuildingTile.ApplyLevelVisuals()` handles the swap
5. Build a Canvas with: village name, progress slider, upgrade panel (name/level/cost/coins), upgrade/close buttons, village-complete dialog
6. Drag the 9 tiles into `VillageController.tiles[]`

Add to Build Settings as index 5.

## 9. Sound effects

Drop any royalty-free `.wav`/`.mp3` files into `Assets/Audio/` and drag them into **AudioManager** in the Boot scene. Recommended free sources:
- `freesound.org` (casino coin, slot spin, hammer strike, pig oink)
- Unity Asset Store — "Free Sound Effects Pack"

If you leave clips empty, the game works silently (no crash).

## 10. Scene flow summary

```
Boot → Login → MainGame ⇄ Village
                    │
                    ├─ 3 attacks (specialAction="attack") → Attack → MainGame
                    └─ 3 raids   (specialAction="raid")   → Raid   → MainGame
```

`WinEffectController.Show()` handles the auto-navigation for you — no extra code needed.

## 11. Test accounts

Log in with the existing backend test accounts:

| Email | Password | Notes |
|-------|----------|-------|
| admin@spinempire.com | Admin123! | 999M coins, 9.9M spins |
| master@spinempire.com | Master123! | Same — use this for playtesting |

## 12. Build for Android

1. File → Build Settings → switch to Android
2. Player Settings → Other Settings:
   - Min API Level: 24
   - Target API: 34
   - Scripting Backend: IL2CPP (required for 64-bit stores)
   - Target Architectures: ARM64
3. Player Settings → Resolution → Orientation: Portrait
4. **Internet permission** is already required (Unity adds it for UnityWebRequest)
5. Build and Run

## 13. Recommended Asset Store freebies for production look

- **POLYGON Fantasy Kingdom (Synty)** — paid but the gold standard for Coin Master-style buildings
- **Low Poly Free Pack** — free, good for prototyping villages
- **Modular Medieval Kit** — free buildings
- **Casino Icons Pack** — free slot machine symbols
- **Unity Particle Pack** — free explosion/coin/shield FX
- **Post Processing Stack** — for bloom on gold frame

## Common gotchas

- **JSON errors:** Make sure Newtonsoft.Json is installed. Unity's built-in `JsonUtility` can't handle the backend's nested objects.
- **CORS:** Not an issue for mobile builds. If testing in WebGL, the backend needs `AllowAnyOrigin`.
- **Token expiration:** On 401 responses, clear the token (`ApiClient.Instance.ClearToken()`) and route back to Login.
- **Reel lands on wrong symbol:** Check that your symbol quads in the ring are in the exact order listed in section 5.2, and that `SymbolIndex()` maps to the same indices.
- **Nothing happens on spin:** Verify the SpinButton has `slotMachine` and `winEffect` dragged in, and that `ApiClient.Token` is set (it is after successful login).
