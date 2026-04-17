# Spin Empire — Unity Client

A Unity-based Coin Master clone that talks to the existing ASP.NET Core backend.

The Flutter project in `frontend/` still works (and will keep working). This Unity project is the recommended path for **realistic 3D** matching the real Coin Master's Unity-rendered look (cylindrical reels with PBR materials, dynamic lighting, particle effects, 3D villages).

## What's here

All the game logic, API client, and data models are pre-written in C#. What you need to do in the Unity Editor is build the **visual scenes** — create the 3D models (or import from the Asset Store), arrange them, and wire up the references on the script components.

See [SETUP.md](./SETUP.md) for a step-by-step walkthrough.

## Folder layout

```
Assets/Scripts/
├── Api/                  REST client + endpoints + data models
│   ├── ApiClient.cs      UnityWebRequest-based async HTTP with JWT
│   ├── ApiEndpoints.cs   All backend routes (auth, spin, attack, raid, villages)
│   └── Models/Models.cs  Serializable DTOs matching backend shapes
├── Auth/
│   └── AuthController.cs Login/Register UI wiring
├── Core/
│   ├── GameManager.cs    Singleton: player state, bet tiers, scene navigation
│   └── AudioManager.cs   Pooled AudioSource playback
├── Slot/
│   ├── SlotMachineController.cs  Orchestrates the full spin flow
│   └── ReelController.cs         Single 3D cylindrical reel
├── UI/
│   ├── HUDController.cs         Coin/spin/shield display
│   ├── BetSelector.cs           +/- bet multiplier (x1..x100K)
│   ├── SpinButton.cs            Main SPIN action
│   └── WinEffectController.cs   Win overlay + auto-navigate to attack/raid
├── Attack/
│   └── AttackScreenController.cs  Random target + hammer smash animation
├── Raid/
│   ├── RaidScreenController.cs  Random target + 3x3 dig mini-game
│   └── HoleTile.cs               Tappable mound with reveal animation
└── Village/
    ├── VillageController.cs     3D village with tappable buildings + upgrade panel
    └── BuildingTile.cs          Single building (5 level-visual swaps)
```

## Backend

This project connects to the existing ASP.NET Core API. Update `ApiEndpoints.BaseUrl` in `Assets/Scripts/Api/ApiEndpoints.cs` to point at your backend (local or Railway).

The following endpoints are used:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/auth/login` | POST | JWT login |
| `/api/auth/register` | POST | Create account |
| `/api/player/state` | GET | Full player snapshot |
| `/api/player/targets` | GET | 5 random public players for attack/raid |
| `/api/spin` | POST | Execute a spin |
| `/api/attack` | POST | Execute attack on a target |
| `/api/raid` | POST | Execute raid (with 3 hole positions) |
| `/api/villages/current` | GET | Current village + buildings |
| `/api/buildings/{id}/upgrade` | POST | Upgrade a building |

## Dependencies

`Packages/manifest.json` includes everything you need:
- **TextMeshPro** — better text rendering
- **Newtonsoft.Json** — JSON (handles nested objects better than `JsonUtility`)
- **Universal Render Pipeline** — modern PBR lighting
- **Post-processing** — bloom, color grading (the cinematic Coin Master look)
- **Input System** — modern touch input

## Unity version

`2022.3.20f1 LTS` (see `ProjectSettings/ProjectVersion.txt`). Any Unity 2022.3 LTS should work. If you want to use a newer version, just let Unity upgrade the project on first open.
