using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Hubs;
using CoinMaster.API.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class RaidService
{
    private readonly AppDbContext _db;
    private readonly GameSettings _settings;
    private readonly IHubContext<GameHub> _hub;
    private readonly NotificationService _notifications;
    private readonly ILogger<RaidService> _logger;

    public RaidService(
        AppDbContext db,
        GameSettings settings,
        IHubContext<GameHub> hub,
        NotificationService notifications,
        ILogger<RaidService> logger)
    {
        _db = db;
        _settings = settings;
        _hub = hub;
        _notifications = notifications;
        _logger = logger;
    }

    public async Task<RaidResultDto> RaidAsync(Guid raiderId, Guid victimId, List<int> holePositions, CancellationToken ct)
    {
        if (raiderId == victimId)
            throw new InvalidOperationException("Cannot raid yourself.");

        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var raider = await _db.Users
            .Include(u => u.UserPets).ThenInclude(up => up.Pet)
            .FirstOrDefaultAsync(u => u.Id == raiderId, ct)
            ?? throw new KeyNotFoundException("Raider not found.");

        var victim = await _db.Users
            .FirstOrDefaultAsync(u => u.Id == victimId, ct)
            ?? throw new KeyNotFoundException("Victim not found.");

        _logger.LogInformation("Raid: raider={RaiderId} victim={VictimId}", raiderId, victimId);

        // Check Foxy pet for extra hole
        var activePet = raider.UserPets.FirstOrDefault(up => up.IsActive);
        bool petExtraHole = activePet?.Pet?.AbilityType == "extra_hole" && activePet.Level >= 11;
        int maxHoles = petExtraHole ? 4 : 3;

        // Validate hole count
        if (holePositions.Count == 0 || holePositions.Count > maxHoles)
            throw new InvalidOperationException($"Invalid number of holes. Max allowed: {maxHoles}.");

        // Validate positions (0-8 grid positions)
        if (holePositions.Any(p => p < 0 || p > 8))
            throw new InvalidOperationException("Hole positions must be between 0 and 8.");

        if (holePositions.Distinct().Count() != holePositions.Count)
            throw new InvalidOperationException("Duplicate hole positions not allowed.");

        int holeCount = holePositions.Count;
        long totalPigBank = victim.PigBankCoins;
        long totalStolen = 0;
        var holeResults = new List<HoleResultDto>();

        // Each hole steals a portion, with 30% chance of being empty
        long perHoleMax = holeCount > 0 ? (long)(totalPigBank * _settings.RaidCoinStealPercent * raider.BetMultiplier / holeCount) : 0;

        foreach (var pos in holePositions)
        {
            bool isEmpty = Random.Shared.Next(100) < 30; // 30% empty
            long found = isEmpty ? 0 : perHoleMax;
            holeResults.Add(new HoleResultDto(pos, found));
            totalStolen += found;
        }

        // Cap at actual pig bank
        totalStolen = Math.Min(totalStolen, victim.PigBankCoins);
        totalStolen = Math.Max(0, totalStolen);

        // If over cap, proportionally reduce
        if (totalStolen > victim.PigBankCoins && victim.PigBankCoins > 0)
        {
            double ratio = (double)victim.PigBankCoins / totalStolen;
            holeResults = holeResults
                .Select(h => new HoleResultDto(h.Position, (long)(h.CoinsFound * ratio)))
                .ToList();
            totalStolen = victim.PigBankCoins;
        }

        // Transfer coins
        victim.PigBankCoins -= totalStolen;
        raider.Coins += totalStolen;
        raider.TotalRaids++;

        // Save raid record
        var raid = new Raid
        {
            RaiderId = raiderId,
            VictimId = victimId,
            HolesDug = holeCount,
            HolesPositions = holePositions.ToArray(),
            CoinsStolen = totalStolen,
            BetMultiplier = raider.BetMultiplier,
            PetBonusExtraHole = petExtraHole
        };
        _db.Raids.Add(raid);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        // Notify victim
        await _notifications.CreateAsync(victimId, "raid",
            "Your Village Was Raided!",
            $"{raider.DisplayName} raided your pig bank and stole {totalStolen:N0} coins!",
            $"{{\"raidId\":\"{raid.Id}\",\"raiderId\":\"{raiderId}\"}}",
            ct);

        // SignalR push
        await _hub.Clients.Group($"user_{victimId}").SendAsync("OnRaided", new
        {
            raidId = raid.Id,
            raiderName = raider.DisplayName,
            coinsStolen = totalStolen
        }, ct);

        _logger.LogInformation("Raid result: stolen={Coins}, holes={Holes}", totalStolen, holeCount);

        return new RaidResultDto(
            TotalCoinsStolen: totalStolen,
            HolesResults: holeResults,
            PetExtraHole: petExtraHole,
            VictimName: victim.DisplayName
        );
    }
}
