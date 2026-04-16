namespace CoinMaster.API.DTOs;

public record AchievementDto(Guid Id, string Key, string Title, string Description, string Category, int TargetValue, int CurrentValue, bool IsUnlocked, bool IsClaimed, long RewardCoins, int RewardSpins, int RewardGems);
