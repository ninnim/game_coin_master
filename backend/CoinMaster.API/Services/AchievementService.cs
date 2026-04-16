using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class AchievementService
{
    private readonly AppDbContext _db;
    private readonly ILogger<AchievementService> _logger;

    public AchievementService(AppDbContext db, ILogger<AchievementService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<List<AchievementDto>> GetAllAsync(Guid userId, CancellationToken ct)
    {
        var achievements = await _db.Achievements
            .OrderBy(a => a.DisplayOrder)
            .ToListAsync(ct);

        var userAchievements = await _db.UserAchievements
            .Where(ua => ua.UserId == userId)
            .ToDictionaryAsync(ua => ua.AchievementId, ct);

        return achievements.Select(a =>
        {
            userAchievements.TryGetValue(a.Id, out var ua);
            return new AchievementDto(
                a.Id, a.Key, a.Title, a.Description, a.Category,
                a.TargetValue,
                ua?.CurrentValue ?? 0,
                ua?.IsUnlocked ?? false,
                ua?.IsClaimed ?? false,
                a.RewardCoins, a.RewardSpins, a.RewardGems
            );
        }).ToList();
    }

    public async Task CheckAndUpdateAsync(Guid userId, string category, int value, CancellationToken ct)
    {
        var achievements = await _db.Achievements
            .Where(a => a.Category == category)
            .ToListAsync(ct);

        foreach (var achievement in achievements)
        {
            var ua = await _db.UserAchievements
                .FirstOrDefaultAsync(u => u.UserId == userId && u.AchievementId == achievement.Id, ct);

            if (ua == null)
            {
                ua = new UserAchievement { UserId = userId, AchievementId = achievement.Id };
                _db.UserAchievements.Add(ua);
            }

            if (ua.IsUnlocked) continue;

            // Update if new value exceeds current
            if (value > ua.CurrentValue)
                ua.CurrentValue = value;

            // Unlock if target reached
            if (ua.CurrentValue >= achievement.TargetValue && !ua.IsUnlocked)
            {
                ua.IsUnlocked = true;
                ua.UnlockedAt = DateTime.UtcNow;
                _logger.LogInformation("User {UserId} unlocked achievement {Key}", userId, achievement.Key);
            }
        }

        await _db.SaveChangesAsync(ct);
    }

    public async Task<AchievementDto> ClaimRewardAsync(Guid userId, Guid achievementId, CancellationToken ct)
    {
        var ua = await _db.UserAchievements
            .Include(u => u.Achievement)
            .FirstOrDefaultAsync(u => u.UserId == userId && u.AchievementId == achievementId, ct)
            ?? throw new KeyNotFoundException("Achievement not found for this user.");

        if (!ua.IsUnlocked)
            throw new InvalidOperationException("Achievement is not yet unlocked.");

        if (ua.IsClaimed)
            throw new InvalidOperationException("Reward already claimed.");

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)!;
        user!.Coins += ua.Achievement.RewardCoins;
        user.Spins = Math.Min(50, user.Spins + ua.Achievement.RewardSpins);
        user.Gems += ua.Achievement.RewardGems;

        ua.IsClaimed = true;
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} claimed achievement {Key}, rewards: coins={Coins} spins={Spins} gems={Gems}",
            userId, ua.Achievement.Key, ua.Achievement.RewardCoins, ua.Achievement.RewardSpins, ua.Achievement.RewardGems);

        return new AchievementDto(
            ua.Achievement.Id, ua.Achievement.Key, ua.Achievement.Title, ua.Achievement.Description,
            ua.Achievement.Category, ua.Achievement.TargetValue, ua.CurrentValue,
            true, true, ua.Achievement.RewardCoins, ua.Achievement.RewardSpins, ua.Achievement.RewardGems
        );
    }
}
