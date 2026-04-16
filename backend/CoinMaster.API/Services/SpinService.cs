using System.Collections.Concurrent;
using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class SpinService
{
    private readonly AppDbContext _db;
    private readonly GameSettings _settings;
    private readonly ILogger<SpinService> _logger;

    // Spin lock to prevent concurrent double-spins
    private static readonly ConcurrentDictionary<Guid, bool> _spinLock = new();

    // Pending special actions per user (attack/raid/shield/energy)
    private static readonly ConcurrentDictionary<Guid, string> _pendingActions = new();

    // Symbol weights: coin_small=35, coin_medium=20, coin_large=10, attack=12, raid=8, shield=8, energy=5, jackpot=2
    private static readonly (string Symbol, int Weight)[] _symbolWeights =
    {
        ("coin_small",  35),
        ("coin_medium", 20),
        ("coin_large",  10),
        ("attack",      12),
        ("raid",         8),
        ("shield",       8),
        ("energy",       5),
        ("jackpot",      2)
    };

    private static readonly int _totalWeight = _symbolWeights.Sum(s => s.Weight);

    public SpinService(AppDbContext db, GameSettings settings, ILogger<SpinService> logger)
    {
        _db = db;
        _settings = settings;
        _logger = logger;
    }

    private static string RollSymbol()
    {
        var rng = Random.Shared;
        int roll = rng.Next(_totalWeight);
        int cumulative = 0;
        foreach (var (symbol, weight) in _symbolWeights)
        {
            cumulative += weight;
            if (roll < cumulative) return symbol;
        }
        return "coin_small";
    }

    public async Task<SpinResultDto> SpinAsync(Guid userId, int betMultiplier, CancellationToken ct)
    {
        // Prevent concurrent spins
        if (!_spinLock.TryAdd(userId, true))
            throw new InvalidOperationException("A spin is already in progress.");

        try
        {
            var user = await _db.Users
                .Include(u => u.UserPets).ThenInclude(up => up.Pet)
                .FirstOrDefaultAsync(u => u.Id == userId, ct)
                ?? throw new KeyNotFoundException("User not found.");

            if (user.IsBanned)
                throw new InvalidOperationException("Account is banned.");

            // Validate bet multiplier
            int[] allowedBets = { 1, 2, 3, 5, 10 };
            if (!allowedBets.Contains(betMultiplier))
                betMultiplier = user.BetMultiplier;

            // Refill spins if timer has elapsed
            if (DateTime.UtcNow >= user.SpinRefillAt && user.Spins < _settings.MaxSpins)
            {
                var intervalsPassed = (int)((DateTime.UtcNow - user.SpinRefillAt).TotalMinutes / _settings.SpinRefillIntervalMinutes);
                intervalsPassed = Math.Max(1, intervalsPassed);
                var refillAmount = intervalsPassed * _settings.SpinRefillRate;
                user.Spins = Math.Min(_settings.MaxSpins, user.Spins + refillAmount);
                user.SpinRefillAt = DateTime.UtcNow.AddMinutes(_settings.SpinRefillIntervalMinutes);
                _logger.LogInformation("Refilled {Amount} spins for user {UserId}", refillAmount, userId);
            }

            if (user.Spins < betMultiplier)
                throw new InvalidOperationException($"Not enough spins. You have {user.Spins}, need {betMultiplier}.");

            // Deduct spins (one per bet multiplier)
            user.Spins -= betMultiplier;
            user.WeeklySpinsUsed += betMultiplier;

            // Roll 3 symbols
            var slot1 = RollSymbol();
            var slot2 = RollSymbol();
            var slot3 = RollSymbol();

            // Determine result
            string resultType;
            long coinsEarned = 0;
            int spinsEarned = 0;
            string? specialAction = null;
            bool petBonusApplied = false;
            bool isJackpot = false;

            // Check active pet
            var activePetEntry = user.UserPets.FirstOrDefault(up => up.IsActive);
            Pet? activePet = activePetEntry?.Pet;

            // All 3 same = jackpot of that type
            if (slot1 == slot2 && slot2 == slot3)
            {
                resultType = $"jackpot_{slot1}";
                isJackpot = true;

                switch (slot1)
                {
                    case "coin_small":
                        coinsEarned = 500L * betMultiplier * user.VillageLevel;
                        break;
                    case "coin_medium":
                        coinsEarned = 2500L * betMultiplier * user.VillageLevel;
                        break;
                    case "coin_large":
                        coinsEarned = 10000L * betMultiplier * user.VillageLevel;
                        break;
                    case "jackpot":
                        coinsEarned = (long)_settings.JackpotMultiplier * user.VillageLevel * 1000L * betMultiplier;
                        isJackpot = true;
                        break;
                    case "attack":
                        specialAction = "attack";
                        break;
                    case "raid":
                        specialAction = "raid";
                        break;
                    case "shield":
                        int newShields = Math.Min(_settings.MaxShields, user.ShieldCount + 1);
                        user.ShieldCount = newShields;
                        break;
                    case "energy":
                        spinsEarned = 10 * betMultiplier;
                        user.Spins = Math.Min(_settings.MaxSpins, user.Spins + spinsEarned);
                        break;
                }
            }
            else
            {
                // Check for 2 of the same
                string? twoMatch = null;
                if (slot1 == slot2) twoMatch = slot1;
                else if (slot2 == slot3) twoMatch = slot2;
                else if (slot1 == slot3) twoMatch = slot1;

                if (twoMatch != null)
                {
                    resultType = $"pair_{twoMatch}";
                    switch (twoMatch)
                    {
                        case "coin_small":
                            coinsEarned = 100L * betMultiplier * user.VillageLevel;
                            break;
                        case "coin_medium":
                            coinsEarned = 500L * betMultiplier * user.VillageLevel;
                            break;
                        case "coin_large":
                            coinsEarned = 2000L * betMultiplier * user.VillageLevel;
                            break;
                        case "jackpot":
                            coinsEarned = 5000L * betMultiplier * user.VillageLevel;
                            break;
                        case "attack":
                            // No special action for pairs, minor coin bonus
                            coinsEarned = 50L * betMultiplier;
                            break;
                        case "raid":
                            coinsEarned = 50L * betMultiplier;
                            break;
                        case "shield":
                            // small chance for shield on pair
                            if (Random.Shared.Next(100) < 30)
                            {
                                user.ShieldCount = Math.Min(_settings.MaxShields, user.ShieldCount + 1);
                            }
                            break;
                        case "energy":
                            spinsEarned = 3 * betMultiplier;
                            user.Spins = Math.Min(_settings.MaxSpins, user.Spins + spinsEarned);
                            break;
                    }
                }
                else
                {
                    resultType = "miss";
                    // Small consolation
                    coinsEarned = 10L * betMultiplier;
                }
            }

            // Apply Tiger pet coin bonus
            if (activePet?.AbilityType == "coin_boost" && coinsEarned > 0)
            {
                decimal tigerBonus = activePetEntry!.Level * 0.10m;
                long bonusCoins = (long)(coinsEarned * tigerBonus);
                coinsEarned += bonusCoins;
                petBonusApplied = true;
            }

            // Pig bank fill
            user.PigBankCoins += _settings.PigBankFillRatePerSpin * betMultiplier;

            // Add coins
            user.Coins += coinsEarned;

            // Store pending action
            if (specialAction != null)
                _pendingActions[userId] = specialAction;

            // Save spin result
            var spinResult = new SpinResult
            {
                UserId = userId,
                Slot1 = slot1,
                Slot2 = slot2,
                Slot3 = slot3,
                ResultType = resultType,
                CoinsEarned = coinsEarned,
                SpinsEarned = spinsEarned,
                BetMultiplier = betMultiplier,
                PetBonusApplied = petBonusApplied
            };
            _db.SpinResults.Add(spinResult);
            await _db.SaveChangesAsync(ct);

            _logger.LogInformation("User {UserId} spun: [{S1},{S2},{S3}] => {ResultType}, coins={Coins}", userId, slot1, slot2, slot3, resultType, coinsEarned);

            string symbolColor = resultType.Contains("jackpot") ? "#FFD700" :
                                 coinsEarned > 0 ? "#00E5FF" : "#A0A3BD";

            return new SpinResultDto(
                Slot1: slot1,
                Slot2: slot2,
                Slot3: slot3,
                ResultType: resultType,
                CoinsEarned: coinsEarned,
                SpinsEarned: spinsEarned,
                SpinsRemaining: user.Spins,
                CurrentCoins: user.Coins,
                BetMultiplier: betMultiplier,
                SpecialAction: specialAction,
                PetBonusApplied: petBonusApplied,
                Animation: new SpinAnimationDto(
                    StopDelayMs: new[] { 800, 1200, 1600 },
                    IsJackpot: isJackpot,
                    SymbolColor: symbolColor
                )
            );
        }
        finally
        {
            _spinLock.TryRemove(userId, out _);
        }
    }

    public async Task<List<SpinResult>> GetHistoryAsync(Guid userId, CancellationToken ct)
    {
        return await _db.SpinResults
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.CreatedAt)
            .Take(20)
            .ToListAsync(ct);
    }

    public string? GetPendingAction(Guid userId)
    {
        _pendingActions.TryGetValue(userId, out var action);
        return action;
    }

    public void ClearPendingAction(Guid userId)
    {
        _pendingActions.TryRemove(userId, out _);
    }
}
