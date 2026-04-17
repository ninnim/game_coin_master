using System;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace CoinMasterClone.Api.Models
{
    // ══════════════════════ AUTH ══════════════════════

    public class LoginRequest
    {
        [JsonProperty("email")] public string Email;
        [JsonProperty("password")] public string Password;
    }

    public class RegisterRequest
    {
        [JsonProperty("email")] public string Email;
        [JsonProperty("password")] public string Password;
        [JsonProperty("displayName")] public string DisplayName;
    }

    public class AuthResponse
    {
        [JsonProperty("token")] public string Token;
        [JsonProperty("user")] public UserModel User;
    }

    // ══════════════════════ USER ══════════════════════

    public class UserModel
    {
        [JsonProperty("id")] public string Id;
        [JsonProperty("email")] public string Email;
        [JsonProperty("displayName")] public string DisplayName;
        [JsonProperty("avatarUrl")] public string AvatarUrl;
        [JsonProperty("coins")] public long Coins;
        [JsonProperty("spins")] public int Spins;
        [JsonProperty("gems")] public int Gems;
        [JsonProperty("villageLevel")] public int VillageLevel;
        [JsonProperty("shieldCount")] public int ShieldCount;
        [JsonProperty("totalStars")] public int TotalStars;
        [JsonProperty("pigBankCoins")] public long PigBankCoins;
    }

    // ══════════════════════ VILLAGE ══════════════════════

    public class VillageModel
    {
        [JsonProperty("id")] public string Id;
        [JsonProperty("name")] public string Name;
        [JsonProperty("theme")] public string Theme;
        [JsonProperty("orderNum")] public int OrderNum;
        [JsonProperty("isBoom")] public bool IsBoom;
        [JsonProperty("isCompleted")] public bool IsCompleted;
        [JsonProperty("isActive")] public bool IsActive;
        [JsonProperty("skyColor")] public string SkyColor;
        [JsonProperty("description")] public string Description;
    }

    public class UserBuildingModel
    {
        [JsonProperty("buildingId")] public string BuildingId;
        [JsonProperty("buildingName")] public string BuildingName;
        [JsonProperty("imageBase")] public string ImageBase;
        [JsonProperty("positionX")] public float PositionX;
        [JsonProperty("positionY")] public float PositionY;
        [JsonProperty("upgradeLevel")] public int UpgradeLevel;
        [JsonProperty("isDestroyed")] public bool IsDestroyed;
        [JsonProperty("nextUpgradeCost")] public long NextUpgradeCost;
        [JsonProperty("canAfford")] public bool CanAfford;
    }

    public class BuildResultModel
    {
        [JsonProperty("buildingId")] public string BuildingId;
        [JsonProperty("buildingName")] public string BuildingName;
        [JsonProperty("newLevel")] public int NewLevel;
        [JsonProperty("coinsSpent")] public long CoinsSpent;
        [JsonProperty("coinsRemaining")] public long CoinsRemaining;
        [JsonProperty("villageCompleted")] public bool VillageCompleted;
        [JsonProperty("nextVillage")] public VillageModel NextVillage;
    }

    // ══════════════════════ PLAYER STATE ══════════════════════

    public class PlayerStateModel
    {
        [JsonProperty("user")] public UserModel User;
        [JsonProperty("currentVillage")] public VillageModel CurrentVillage;
        [JsonProperty("buildings")] public List<UserBuildingModel> Buildings;
        [JsonProperty("pendingAttacks")] public int PendingAttacks;
        [JsonProperty("pendingRaids")] public int PendingRaids;
        [JsonProperty("unreadNotifications")] public int UnreadNotifications;
    }

    // ══════════════════════ SPIN ══════════════════════

    public class SpinRequest
    {
        [JsonProperty("betMultiplier")] public int BetMultiplier;
    }

    public class SpinAnimationModel
    {
        [JsonProperty("stopDelayMs")] public int[] StopDelayMs;
        [JsonProperty("isJackpot")] public bool IsJackpot;
        [JsonProperty("symbolColor")] public string SymbolColor;
    }

    public class SpinResultModel
    {
        [JsonProperty("slot1")] public string Slot1;
        [JsonProperty("slot2")] public string Slot2;
        [JsonProperty("slot3")] public string Slot3;
        [JsonProperty("resultType")] public string ResultType;
        [JsonProperty("coinsEarned")] public long CoinsEarned;
        [JsonProperty("spinsEarned")] public int SpinsEarned;
        [JsonProperty("spinsRemaining")] public int SpinsRemaining;
        [JsonProperty("currentCoins")] public long CurrentCoins;
        [JsonProperty("betMultiplier")] public int BetMultiplier;
        [JsonProperty("specialAction")] public string SpecialAction;
        [JsonProperty("petBonusApplied")] public bool PetBonusApplied;
        [JsonProperty("animation")] public SpinAnimationModel Animation;

        [JsonIgnore]
        public bool IsJackpot => Slot1 == Slot2 && Slot2 == Slot3;
    }

    // ══════════════════════ ATTACK / RAID ══════════════════════

    public class PlayerTargetModel
    {
        [JsonProperty("userId")] public string UserId;
        [JsonProperty("displayName")] public string DisplayName;
        [JsonProperty("avatarUrl")] public string AvatarUrl;
        [JsonProperty("villageLevel")] public int VillageLevel;
        [JsonProperty("pigBankCoins")] public long PigBankCoins;
    }

    public class AttackRequest
    {
        [JsonProperty("targetUserId")] public string TargetUserId;
    }

    public class AttackResultModel
    {
        [JsonProperty("wasBlocked")] public bool WasBlocked;
        [JsonProperty("coinsStolen")] public long CoinsStolen;
        [JsonProperty("buildingDestroyed")] public string BuildingDestroyed;
        [JsonProperty("defenderName")] public string DefenderName;
        [JsonProperty("attackId")] public string AttackId;
        [JsonProperty("petBonusApplied")] public bool PetBonusApplied;
        [JsonProperty("petBonus")] public float PetBonus;
    }

    public class RaidRequest
    {
        [JsonProperty("victimId")] public string VictimId;
        [JsonProperty("holePositions")] public int[] HolePositions;
    }

    public class HoleResultModel
    {
        [JsonProperty("position")] public int Position;
        [JsonProperty("coinsFound")] public long CoinsFound;
    }

    public class RaidResultModel
    {
        [JsonProperty("totalCoinsStolen")] public long TotalCoinsStolen;
        [JsonProperty("holeResults")] public List<HoleResultModel> HoleResults;
        [JsonProperty("petExtraHole")] public bool PetExtraHole;
        [JsonProperty("victimName")] public string VictimName;
    }
}
