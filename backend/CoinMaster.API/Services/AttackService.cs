using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Hubs;
using CoinMaster.API.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class AttackService
{
    private readonly AppDbContext _db;
    private readonly GameSettings _settings;
    private readonly IHubContext<GameHub> _hub;
    private readonly NotificationService _notifications;
    private readonly ILogger<AttackService> _logger;

    public AttackService(
        AppDbContext db,
        GameSettings settings,
        IHubContext<GameHub> hub,
        NotificationService notifications,
        ILogger<AttackService> logger)
    {
        _db = db;
        _settings = settings;
        _hub = hub;
        _notifications = notifications;
        _logger = logger;
    }

    public async Task<AttackResultDto> AttackAsync(Guid attackerId, Guid targetId, CancellationToken ct)
    {
        if (attackerId == targetId)
            throw new InvalidOperationException("Cannot attack yourself.");

        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var attacker = await _db.Users
            .Include(u => u.UserPets).ThenInclude(up => up.Pet)
            .FirstOrDefaultAsync(u => u.Id == attackerId, ct)
            ?? throw new KeyNotFoundException("Attacker not found.");

        var defender = await _db.Users
            .Include(u => u.UserBuildings).ThenInclude(ub => ub.Building)
            .FirstOrDefaultAsync(u => u.Id == targetId, ct)
            ?? throw new KeyNotFoundException("Target player not found.");

        _logger.LogInformation("Attack: attacker={AttackerId} defender={DefenderId}", attackerId, targetId);

        bool wasBlocked = false;
        long coinsStolen = 0;
        string? buildingDestroyed = null;
        bool petBonusApplied = false;
        decimal petBonus = 0;

        // Check shield
        if (defender.ShieldCount > 0)
        {
            defender.ShieldCount--;
            wasBlocked = true;
        }
        else
        {
            // Find a random non-destroyed building for defender's current village
            var activeVillage = await _db.UserVillages
                .Include(uv => uv.Village)
                .FirstOrDefaultAsync(uv => uv.UserId == targetId && uv.IsActive && !uv.IsCompleted, ct);

            UserBuilding? targetBuilding = null;
            if (activeVillage != null)
            {
                var buildingsInVillage = await _db.Buildings
                    .Where(b => b.VillageId == activeVillage.VillageId)
                    .Select(b => b.Id)
                    .ToListAsync(ct);

                var userBuildings = await _db.UserBuildings
                    .Include(ub => ub.Building)
                    .Where(ub => ub.UserId == targetId && buildingsInVillage.Contains(ub.BuildingId) && !ub.IsDestroyed)
                    .ToListAsync(ct);

                if (userBuildings.Any())
                {
                    targetBuilding = userBuildings[Random.Shared.Next(userBuildings.Count)];
                    targetBuilding.IsDestroyed = true;
                    targetBuilding.DestroyedBy = attackerId;
                    targetBuilding.DestroyedAt = DateTime.UtcNow;
                    buildingDestroyed = targetBuilding.Building.Name;
                }
            }

            // Calculate coins to steal from pig bank
            var baseSteal = (long)(defender.PigBankCoins * _settings.AttackCoinStealPercent * attacker.BetMultiplier);

            // Tiger pet bonus
            var activePet = attacker.UserPets.FirstOrDefault(up => up.IsActive);
            if (activePet?.Pet?.AbilityType == "coin_boost")
            {
                petBonus = activePet.Level * 0.10m;
                var bonusAmount = (long)(baseSteal * petBonus);
                coinsStolen = baseSteal + bonusAmount;
                petBonusApplied = true;
            }
            else
            {
                coinsStolen = baseSteal;
            }

            coinsStolen = Math.Min(coinsStolen, defender.PigBankCoins);
            coinsStolen = Math.Max(0, coinsStolen);

            // Transfer coins
            defender.PigBankCoins -= coinsStolen;
            attacker.Coins += coinsStolen;
        }

        attacker.TotalAttacks++;

        // Create attack record
        var attack = new Attack
        {
            AttackerId = attackerId,
            DefenderId = targetId,
            BuildingId = null,
            CoinsStolen = coinsStolen,
            WasBlockedByShield = wasBlocked,
            RevengeDeadline = DateTime.UtcNow.AddHours(_settings.RevengeWindowHours),
            BetMultiplier = attacker.BetMultiplier,
            PetBonus = petBonus
        };
        _db.Attacks.Add(attack);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        // Notify defender
        string notifMessage = wasBlocked
            ? $"{attacker.DisplayName} attacked you but your shield blocked it!"
            : $"{attacker.DisplayName} attacked you and stole {coinsStolen:N0} coins!";

        await _notifications.CreateAsync(targetId, "attack",
            wasBlocked ? "Attack Blocked!" : "You Were Attacked!",
            notifMessage,
            $"{{\"attackId\":\"{attack.Id}\",\"attackerId\":\"{attackerId}\"}}",
            ct);

        // SignalR push
        await _hub.Clients.Group($"user_{targetId}").SendAsync("OnAttacked", new
        {
            attackId = attack.Id,
            attackerName = attacker.DisplayName,
            coinsStolen,
            wasBlocked,
            buildingDestroyed
        }, ct);

        _logger.LogInformation("Attack result: blocked={Blocked}, stolen={Coins}, building={Building}", wasBlocked, coinsStolen, buildingDestroyed);

        return new AttackResultDto(
            WasBlocked: wasBlocked,
            CoinsStolen: coinsStolen,
            BuildingDestroyed: buildingDestroyed,
            PetBonusApplied: petBonusApplied,
            PetBonus: petBonus,
            AttackId: attack.Id,
            DefenderName: defender.DisplayName
        );
    }

    public async Task<List<PlayerTargetDto>> GetTargetsAsync(Guid userId, CancellationToken ct)
    {
        // Return 5 random users excluding self
        var users = await _db.Users
            .Where(u => u.Id != userId && !u.IsBanned)
            .OrderBy(u => Guid.NewGuid()) // random order via DB
            .Take(5)
            .Select(u => new PlayerTargetDto(u.Id, u.DisplayName, u.AvatarUrl, u.VillageLevel, u.PigBankCoins))
            .ToListAsync(ct);

        return users;
    }
}
