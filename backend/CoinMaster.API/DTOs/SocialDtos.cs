namespace CoinMaster.API.DTOs;

public record FriendDto(Guid UserId, string DisplayName, string? AvatarUrl, int VillageLevel, bool IsOnline, bool CanGiftSpin, string FriendshipStatus);
public record LeaderboardEntryDto(int Rank, Guid UserId, string DisplayName, string? AvatarUrl, long Value, int VillageLevel);
public record RevengeResultDto(bool Success, long CoinsStolen, string? Message);
public record RecentAttackDto(Guid AttackId, string AttackerName, string? AttackerAvatar, long CoinsStolen, bool WasBlocked, DateTime CreatedAt, bool CanRevenge, bool WasRevenged);
