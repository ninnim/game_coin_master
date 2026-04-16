# AGENT 2 — BACKEND AGENT
## Mission: Build the complete C# ASP.NET Core 8 API for Spin Empire

You are the **Backend Agent** for "Spin Empire" — a Coin Master clone game.
Your ONLY job is to create ALL backend files in `d:/coin_master_clone/backend/`.
Do NOT touch any other folder.

---

## Project Setup

Create a new ASP.NET Core 8 Web API project:
```
d:/coin_master_clone/backend/
├── CoinMaster.API/
│   ├── CoinMaster.API.csproj
│   ├── Program.cs
│   ├── appsettings.json
│   ├── appsettings.Development.json
│   ├── Dockerfile
│   ├── Controllers/
│   ├── Services/
│   ├── Models/
│   ├── DTOs/
│   ├── Data/
│   ├── Hubs/
│   └── Middleware/
└── CoinMaster.sln
```

---

## Required NuGet Packages

```xml
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.*" />
<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.*" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.*" />
<PackageReference Include="BCrypt.Net-Next" Version="4.0.*" />
<PackageReference Include="Microsoft.AspNetCore.SignalR" Version="1.1.*" />
<PackageReference Include="System.IdentityModel.Tokens.Jwt" Version="7.0.*" />
<PackageReference Include="Microsoft.AspNetCore.StaticFiles" Version="2.2.*" />
```

---

## Database Connection Configuration

### appsettings.json (Railway production)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "${DATABASE_URL}",
    "LocalConnection": "Host=localhost;Port=5432;Database=spin_empire_db;Username=postgres;Password=TimeCapsule2026!"
  },
  "JwtSettings": {
    "SecretKey": "SpinEmpire_SuperSecretKey_MustBe32CharsLong!!",
    "Issuer": "SpinEmpireAPI",
    "Audience": "SpinEmpireApp",
    "ExpirationDays": 30
  },
  "GameSettings": {
    "MaxSpins": 50,
    "SpinRefillRate": 5,
    "SpinRefillIntervalMinutes": 60,
    "MaxShields": 3,
    "AttackCoinStealPercent": 0.20,
    "RaidCoinStealPercent": 0.33,
    "PigBankFillRatePerSpin": 100,
    "JackpotMultiplier": 50,
    "SpinGiftCooldownHours": 24,
    "RevengWindowHours": 24,
    "MaxDailyLoginStreak": 7
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

### appsettings.Development.json (Local)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=spin_empire_db;Username=postgres;Password=TimeCapsule2026!"
  }
}
```

---

## Program.cs Setup

```csharp
// Order matters:
// 1. UseExceptionHandler (global JSON error handler)
// 2. UseCors (allow all origins for dev)
// 3. UseAuthentication
// 4. UseAuthorization
// 5. UseStaticFiles (serve uploads/)
// 6. MapControllers
// 7. MapHub<GameHub>("/hubs/game")

// Use DATABASE_URL env var if present (Railway), else DefaultConnection
string connectionString = Environment.GetEnvironmentVariable("DATABASE_URL") 
    ?? builder.Configuration.GetConnectionString("DefaultConnection")!;
```

---

## Models (EF Core Entities)

Create ONE class per table from the database schema. Key models:

### User.cs
```csharp
public class User {
    public Guid Id { get; set; }
    public string Email { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;
    public string DisplayName { get; set; } = null!;
    public string? AvatarUrl { get; set; }
    public long Coins { get; set; } = 500;
    public int Spins { get; set; } = 50;
    public int Gems { get; set; } = 10;
    public int VillageLevel { get; set; } = 1;
    public long PigBankCoins { get; set; } = 0;
    public int ShieldCount { get; set; } = 0;
    public int TotalStars { get; set; } = 0;
    public DateTime SpinRefillAt { get; set; } = DateTime.UtcNow;
    public int BetMultiplier { get; set; } = 1;
    public Guid? ActivePetId { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public int LoginStreak { get; set; } = 0;
    public int WeeklySpinsUsed { get; set; } = 0;
    public int TotalAttacks { get; set; } = 0;
    public int TotalRaids { get; set; } = 0;
    public bool IsBanned { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation
    public ICollection<SpinResult> SpinResults { get; set; } = [];
    public ICollection<UserCard> Cards { get; set; } = [];
    public ICollection<UserPet> Pets { get; set; } = [];
}
```

Create ALL other entity models following the schema from Agent 1's database design.

---

## Services to Implement

### 1. SpinService.cs — Core game mechanic
```csharp
// Spin result weights (adjustable in GameSettings):
// Coin x1 (3 coins): 35%
// Coin x2 (medium coins): 20%
// Coin x3 (large coins): 10%
// Attack: 12%
// Raid: 8%
// Shield: 8%
// Energy (+5 spins): 5%
// Jackpot (3x coin special): 2%

// Methods:
// Task<SpinResultDto> SpinAsync(Guid userId, int betMultiplier)
// - Check user has spins available
// - Deduct 1 spin
// - Apply bet multiplier to results
// - Add pig bank contribution (100 coins * betMultiplier)
// - Check active pet bonuses
// - Save spin_results record
// - Return full result with animation data
// - Handle spin refill timer (5 spins/hour, max 50)

// SpinResultDto must include:
// { slot1, slot2, slot3, resultType, coinsEarned, spinsLeft, 
//   specialAction (null|"attack"|"raid"|"shield"|"energy"),
//   petBonusApplied, animationData: { stopDelays: [ms, ms, ms] } }
```

### 2. AttackService.cs
```csharp
// Task<AttackResultDto> AttackAsync(Guid attackerId, Guid targetId, int betMultiplier)
// 1. Check attacker has a pending attack action from spin
// 2. If target has shield: consume shield, no coins stolen, return blocked=true
// 3. If Rhino pet active at max level: auto-block chance
// 4. Select a random non-destroyed building from target's current village
// 5. Mark building as destroyed
// 6. Steal AttackCoinStealPercent (20%) of target's pig_bank_coins (not main coins)
// 7. Apply Tiger pet bonus (extra coin % per level)
// 8. Apply bet multiplier
// 9. Set revenge_deadline = NOW() + 24h on attack record
// 10. Create notification for defender: "You were attacked by {name}!"
// 11. Send SignalR notification to defender
// 12. Return: { coinsStolen, wasBlocked, buildingDestroyed, petBonusApplied }
```

### 3. RaidService.cs
```csharp
// Task<RaidResultDto> RaidAsync(Guid raiderId, Guid victimId, List<int> holePositions, int betMultiplier)
// 1. Foxy pet at high level = 4th hole allowed, else max 3
// 2. Victim's pig bank has virtual "pockets" at positions 0-8
// 3. Each hole: steal RaidCoinStealPercent (33%) of pig_bank_coins / 3
// 4. Total max steal: 100% of pig_bank_coins
// 5. Update victim's pig_bank_coins
// 6. Create notification for victim: "You were raided by {name}!"
// 7. Return: { coinsStolen, holesResults: [{position, coinsFound}], petExtraHole }
```

### 4. BuildingService.cs
```csharp
// Task<BuildResultDto> BuildAsync(Guid userId, Guid buildingId)
// 1. Get user's current village
// 2. Check building belongs to current village
// 3. Check building is not already at max level (4)
// 4. Get next upgrade cost from upgrade_costs array
// 5. Deduct coins from user
// 6. Increment upgrade_level
// 7. Check if ALL buildings in village are at level 4 → village complete
// 8. If village complete: advance user to next village, give star reward
// 9. Return: { newLevel, coinsSpent, villageCompleted, nextVillage? }
```

### 5. CardService.cs
```csharp
// Task<OpenChestResultDto> OpenChestAsync(Guid userId, Guid chestTypeId, int quantity)
// 1. Deduct coins × quantity
// 2. For each chest: generate random cards using rarity_weights from chest_types table
// 3. Save to user_cards (increment quantity if already owned)
// 4. Check for completed card sets → award set completion reward
// 5. Return: { cardsReceived[], setsCompleted[], coinsSpent }

// Task<TradeResultDto> InitiateTradeAsync(Guid senderId, Guid receiverId, Guid offeredCardId, Guid requestedCardId)
// Task<bool> RespondTradeAsync(Guid tradeId, Guid responderId, bool accept)
```

### 6. PetService.cs
```csharp
// Task<PetDto> ActivatePetAsync(Guid userId, Guid petId)
// Task<FeedResultDto> FeedPetAsync(Guid userId, Guid petId, int treats)
// - Deduct treats from user inventory
// - Add XP to pet
// - Check level up (xp >= level * treats_per_level)
// - Return: { newLevel, xpGained, leveledUp, abilityStrength }

// GetPetBonus(User user, string bonusType) → decimal bonus value
// - Foxy lvl1-10: 0 extra holes; lvl11-20: 1 extra hole
// - Tiger lvl1-20: 10% × level coin bonus on attack
// - Rhino lvl1-20: 5% × level shield chance
```

### 7. SocialService.cs
```csharp
// Task<bool> GiftSpinAsync(Guid senderId, Guid receiverId)
// - Check daily limit (1 per friend)
// - Deduct 0 spins from sender (gift is "free")
// - Add 1 spin to receiver
// - Reset spins_gifted_today at midnight UTC
// - Create notification + SignalR event

// Task<List<LeaderboardEntryDto>> GetLeaderboardAsync(string type, string period)
// - type: "coins" | "village" | "cards" | "attacks"
// - period: "weekly" | "alltime"
// - Return top 100 players

// Task<RevengeResultDto> RevengeAsync(Guid userId, Guid attackId)
// - Check attack is within revenge_deadline
// - Execute attack against original attacker
// - Mark was_revenged = true on original attack
```

### 8. EventService.cs
```csharp
// Task<List<EventDto>> GetActiveEventsAsync()
// Task UpdateEventProgressAsync(Guid userId, string eventType, int amount)
// - Called after each relevant action (spin for Gold Rush, attack for Attack Madness, etc.)
```

### 9. AchievementService.cs
```csharp
// Task CheckAchievementsAsync(Guid userId, string category, int newValue)
// - Called after each game action
// - Update user_achievements.current_value
// - If >= target_value: mark unlocked, create notification
```

### 10. PlayerStateService.cs
```csharp
// Task<PlayerStateDto> GetPlayerStateAsync(Guid userId)
// Returns complete player state:
// { user, currentVillage, buildings[], activePet, cards, shields,
//   pendingAttacks[], pendingRaids[], activeEvents[], notifications[] }
// This is the main "load game" endpoint called on app start
```

---

## Controllers to Implement

### AuthController
- `POST /api/auth/register` — validate email/pass, BCrypt hash, JWT token
- `POST /api/auth/login` — validate credentials, JWT token
- `GET /api/auth/me` — return user profile

### SpinController
- `POST /api/spin` → `{ betMultiplier }` → SpinResultDto
- `GET /api/spin/history` → last 20 spin results
- `PUT /api/spin/bet` → `{ multiplier }` → set bet multiplier

### GameController
- `POST /api/attack` → `{ targetUserId }` → AttackResultDto
- `POST /api/raid` → `{ targetUserId, holePositions[] }` → RaidResultDto
- `GET /api/player/state` → PlayerStateDto (main game load)
- `GET /api/player/targets` → List of 5 random attackable/raidable players

### VillageController
- `GET /api/villages` → All villages with user progress
- `GET /api/villages/current` → Current village with building states
- `POST /api/buildings/{buildingId}/upgrade` → BuildResultDto

### CardController
- `GET /api/cards` → User's full card collection grouped by set
- `POST /api/chests/open` → `{ chestTypeId, quantity }` → OpenChestResultDto
- `GET /api/chests` → Available chest types
- `POST /api/trades` → Initiate trade request
- `GET /api/trades` → Pending trades
- `PUT /api/trades/{id}/respond` → `{ accept: bool }` → TradeResultDto

### PetController
- `GET /api/pets` → User's pets with stats
- `POST /api/pets/{petId}/activate` → ActivatePetDto
- `POST /api/pets/{petId}/feed` → `{ treats }` → FeedResultDto

### SocialController
- `GET /api/friends` → Friend list with online status + today's gift status
- `POST /api/friends/{userId}/request` → Send friend request
- `PUT /api/friends/{requestId}/respond` → `{ accept: bool }`
- `POST /api/friends/{userId}/gift-spin` → Gift spin
- `GET /api/leaderboard` → `?type=coins&period=weekly` → Top 100
- `POST /api/revenge/{attackId}` → Revenge attack

### ClanController
- `GET /api/clans` → Public clans list (with member counts, total points)
- `POST /api/clans` → `{ name, description, isPublic }` → Create clan
- `GET /api/clans/{id}` → Clan details with member list
- `POST /api/clans/{id}/join` → Join public clan
- `GET /api/clans/my` → User's clan

### EventController
- `GET /api/events/active` → Active events with user progress
- `GET /api/events/history` → Past events

### AchievementController
- `GET /api/achievements` → All achievements with user progress
- `POST /api/achievements/{id}/claim` → Claim reward

### NotificationController
- `GET /api/notifications` → Unread notifications
- `PUT /api/notifications/read` → Mark all as read
- `DELETE /api/notifications/{id}` → Delete notification

### ProfileController
- `PUT /api/profile` → `{ displayName }` → Update display name
- `POST /api/profile/avatar` → Multipart avatar upload
- `GET /api/profile/{userId}` → Public profile

---

## SignalR Hub: GameHub.cs

```csharp
[Authorize]
public class GameHub : Hub
{
    // Client calls:
    // JoinGame() - adds user to their personal group
    // JoinClan(string clanId)
    // LeaveGame()

    // Server sends:
    // OnAttacked(AttackEventDto data) - sent to defender
    // OnRaided(RaidEventDto data) - sent to victim  
    // OnSpinGifted(GiftEventDto data) - sent to receiver
    // OnTradeRequest(TradeEventDto data) - sent to receiver
    // OnFriendRequest(FriendEventDto data) - sent to receiver
    // OnAchievementUnlocked(AchievementEventDto data) - sent to achiever
    // OnEventUpdate(EventProgressDto data) - sent to user
    // OnVillageCompleted(VillageCompleteDto data) - sent to user

    // Track online users in static ConcurrentDictionary<Guid, string>
    // connectionId → userId mapping
    
    public override async Task OnConnectedAsync() { /* add to online dict */ }
    public override async Task OnDisconnectedAsync(Exception? e) { /* remove from online dict */ }
}
```

---

## DTOs

### SpinResultDto
```csharp
public record SpinResultDto(
    string Slot1, string Slot2, string Slot3,
    string ResultType,
    long CoinsEarned, int SpinsEarned,
    int SpinsRemaining, long CurrentCoins,
    int BetMultiplier,
    string? SpecialAction, // "attack", "raid", "shield", "energy", null
    bool PetBonusApplied,
    SpinAnimationDto Animation
);

public record SpinAnimationDto(
    int[] StopDelayMs, // [800, 1200, 1600] per reel
    bool IsJackpot,
    string SymbolColor // for glow effect
);
```

### PlayerStateDto
```csharp
public record PlayerStateDto(
    UserDto User,
    VillageDto CurrentVillage,
    List<UserBuildingDto> Buildings,
    UserPetDto? ActivePet,
    List<UserPetDto> AllPets,
    CardCollectionSummaryDto Cards,
    int PendingAttacks, // count of attack actions available
    int PendingRaids,   // count of raid actions available
    List<ActiveEventDto> ActiveEvents,
    int UnreadNotifications,
    List<RecentAttackDto> RecentAttacks, // last 3 attacks received
    LeaderboardRankDto? WeeklyRank
);
```

---

## Game Logic Details

### Slot Machine Weights
```csharp
// Symbol pool (out of 100):
// "coin_small" → 35 slots
// "coin_medium" → 20 slots  
// "coin_large" → 10 slots
// "attack" → 12 slots
// "raid" → 8 slots
// "shield" → 8 slots
// "energy" → 5 slots
// "jackpot" → 2 slots

// Result determination:
// Roll 3 independent symbols
// If all 3 same → jackpot result for that symbol
// If 2 same → minor bonus
// Coin results: small=500, medium=2500, large=10000 (× bet × village_level)
// Jackpot 3x coins → 50× village coin value
```

### Village Completion Stars
- Complete village 1-10: 1 star each
- Complete village 11-30: 2 stars each
- Complete village 31-100: 3 stars each
- Complete boom villages: +1 extra star
- Stars go toward profile badge tiers

### Daily Spin Gifts Login Streaks
- Day 1: 25 spins
- Day 2: 30 spins
- Day 3: 50 spins (+ 1 rare card)
- Day 4: 35 spins
- Day 5: 45 spins
- Day 6: 40 spins
- Day 7: 75 spins + 1 epic card + 5000 coins
- Streak resets if user misses a day

---

## Error Handling
All errors return: `{ "error": "Human readable message" }`
- 400: validation errors, insufficient coins/spins
- 401: not authenticated
- 403: banned user, insufficient permissions
- 404: resource not found
- 409: conflict (duplicate friend request, trade already pending)
- 500: internal server error (never expose stack trace)

---

## Dockerfile
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["CoinMaster.API/CoinMaster.API.csproj", "CoinMaster.API/"]
RUN dotnet restore "CoinMaster.API/CoinMaster.API.csproj"
COPY . .
WORKDIR "/src/CoinMaster.API"
RUN dotnet build -c Release -o /app/build
RUN dotnet publish -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "CoinMaster.API.dll"]
```

---

## railway.toml (place at d:/coin_master_clone/)
```toml
[build]
dockerfilePath = "backend/CoinMaster.API/Dockerfile"

[deploy]
startCommand = "dotnet CoinMaster.API.dll"
healthcheckPath = "/health"
healthcheckTimeout = 30
restartPolicyType = "on_failure"
```

---

## IMPORTANT RULES
- NEVER use async void — always async Task
- Use ILogger<T> in all services and controllers
- Log all spin results at Debug level
- Log all attacks/raids at Information level
- Log all auth events at Information level
- Use transactions (IDbContextTransaction) for all multi-table operations
- Validate JWT expiry properly
- Sanitize all user inputs
- File uploads: UUID prefix + extension whitelist (.jpg,.jpeg,.png,.gif,.webp)
- Use CancellationToken in all async methods
- The spin endpoint must be idempotent-safe (check for duplicate rapid calls)
- Connection string: prefer DATABASE_URL env var → then appsettings DefaultConnection

Start immediately. Create the complete solution with ALL controllers, services, models, DTOs, and configuration files. Every endpoint must be fully implemented — no TODOs or stubs.
