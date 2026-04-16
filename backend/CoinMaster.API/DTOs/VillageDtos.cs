namespace CoinMaster.API.DTOs;

public record VillageDto(Guid Id, string Name, string Theme, int OrderNum, bool IsBoom, string SkyColor, string? Description, bool IsCompleted, bool IsActive);
public record BuildingDto(Guid Id, string Name, string ImageBase, decimal PositionX, decimal PositionY, long[] UpgradeCosts, string? Description, int BuildingOrder);
public record UserBuildingDto(Guid BuildingId, string BuildingName, string ImageBase, decimal PositionX, decimal PositionY, int UpgradeLevel, bool IsDestroyed, long NextUpgradeCost, bool CanAfford);
public record BuildResultDto(Guid BuildingId, string BuildingName, int NewLevel, long CoinsSpent, long CoinsRemaining, bool VillageCompleted, VillageDto? NextVillage);
