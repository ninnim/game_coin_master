using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class BuildingService
{
    private readonly AppDbContext _db;
    private readonly ILogger<BuildingService> _logger;

    public BuildingService(AppDbContext db, ILogger<BuildingService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<BuildResultDto> UpgradeBuildingAsync(Guid userId, Guid buildingId, CancellationToken ct)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new KeyNotFoundException("User not found.");

        var building = await _db.Buildings
            .Include(b => b.Village)
            .FirstOrDefaultAsync(b => b.Id == buildingId, ct)
            ?? throw new KeyNotFoundException("Building not found.");

        // Ensure the building belongs to user's current active village
        var activeVillage = await _db.UserVillages
            .FirstOrDefaultAsync(uv => uv.UserId == userId && uv.IsActive && !uv.IsCompleted, ct)
            ?? throw new InvalidOperationException("No active village found.");

        if (building.VillageId != activeVillage.VillageId)
            throw new InvalidOperationException("Building does not belong to your current village.");

        // Load or create UserBuilding record
        var userBuilding = await _db.UserBuildings
            .FirstOrDefaultAsync(ub => ub.UserId == userId && ub.BuildingId == buildingId, ct);

        if (userBuilding == null)
        {
            userBuilding = new UserBuilding
            {
                UserId = userId,
                BuildingId = buildingId,
                UpgradeLevel = 0
            };
            _db.UserBuildings.Add(userBuilding);
        }

        if (userBuilding.IsDestroyed)
            throw new InvalidOperationException("Building is destroyed and must be repaired first.");

        if (userBuilding.UpgradeLevel >= 4)
            throw new InvalidOperationException("Building is already at maximum level.");

        // Get cost
        if (building.UpgradeCosts.Length <= userBuilding.UpgradeLevel)
            throw new InvalidOperationException("No upgrade cost defined for this level.");

        long cost = building.UpgradeCosts[userBuilding.UpgradeLevel];

        if (user.Coins < cost)
            throw new InvalidOperationException($"Insufficient coins. Need {cost:N0}, have {user.Coins:N0}.");

        // Deduct coins and upgrade
        user.Coins -= cost;
        userBuilding.UpgradeLevel++;
        userBuilding.CoinsSpent += cost;

        await _db.SaveChangesAsync(ct);

        // Check if all buildings in current village are at level 4
        var allBuildingsInVillage = await _db.Buildings
            .Where(b => b.VillageId == activeVillage.VillageId)
            .Select(b => b.Id)
            .ToListAsync(ct);

        var allUserBuildings = await _db.UserBuildings
            .Where(ub => ub.UserId == userId && allBuildingsInVillage.Contains(ub.BuildingId))
            .ToListAsync(ct);

        bool villageCompleted = allBuildingsInVillage.Count == allUserBuildings.Count
            && allUserBuildings.All(ub => ub.UpgradeLevel >= 4 && !ub.IsDestroyed);

        VillageDto? nextVillageDto = null;

        if (villageCompleted)
        {
            activeVillage.IsCompleted = true;
            activeVillage.IsActive = false;
            activeVillage.CompletedAt = DateTime.UtcNow;

            user.VillageLevel++;
            user.TotalStars++;

            _logger.LogInformation("User {UserId} completed village {VillageId}, advancing to level {Level}", userId, activeVillage.VillageId, user.VillageLevel);

            // Find or create next village entry
            var nextVillage = await _db.Villages
                .OrderBy(v => v.OrderNum)
                .FirstOrDefaultAsync(v => v.OrderNum == building.Village.OrderNum + 1, ct);

            if (nextVillage != null)
            {
                var newUserVillage = new UserVillage
                {
                    UserId = userId,
                    VillageId = nextVillage.Id,
                    IsActive = true
                };
                _db.UserVillages.Add(newUserVillage);

                nextVillageDto = new VillageDto(
                    nextVillage.Id, nextVillage.Name, nextVillage.Theme,
                    nextVillage.OrderNum, nextVillage.IsBoom, nextVillage.SkyColor,
                    nextVillage.Description, false, true
                );
            }

            await _db.SaveChangesAsync(ct);
        }

        await tx.CommitAsync(ct);

        _logger.LogInformation("User {UserId} upgraded building {BuildingId} to level {Level}", userId, buildingId, userBuilding.UpgradeLevel);

        return new BuildResultDto(
            BuildingId: buildingId,
            BuildingName: building.Name,
            NewLevel: userBuilding.UpgradeLevel,
            CoinsSpent: cost,
            CoinsRemaining: user.Coins,
            VillageCompleted: villageCompleted,
            NextVillage: nextVillageDto
        );
    }
}
