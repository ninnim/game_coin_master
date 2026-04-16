using System.Text.Json;
using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class CardService
{
    private readonly AppDbContext _db;
    private readonly ILogger<CardService> _logger;

    public CardService(AppDbContext db, ILogger<CardService> logger)
    {
        _db = db;
        _logger = logger;
    }

    private static string PickRarityByWeights(Dictionary<string, int> weights)
    {
        int total = weights.Values.Sum();
        if (total == 0) return "common";

        int roll = Random.Shared.Next(total);
        int cumulative = 0;
        foreach (var (rarity, weight) in weights)
        {
            cumulative += weight;
            if (roll < cumulative) return rarity;
        }
        return "common";
    }

    public async Task<OpenChestResultDto> OpenChestAsync(Guid userId, Guid chestTypeId, int quantity, CancellationToken ct)
    {
        if (quantity < 1 || quantity > 10)
            throw new InvalidOperationException("Quantity must be between 1 and 10.");

        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new KeyNotFoundException("User not found.");

        var chestType = await _db.ChestTypes.FirstOrDefaultAsync(c => c.Id == chestTypeId, ct)
            ?? throw new KeyNotFoundException("Chest type not found.");

        long totalCost = chestType.PriceCoins * quantity;
        if (user.Coins < totalCost)
            throw new InvalidOperationException($"Insufficient coins. Need {totalCost:N0}, have {user.Coins:N0}.");

        user.Coins -= totalCost;

        // Parse rarity weights
        Dictionary<string, int> rarityWeights;
        try
        {
            rarityWeights = JsonSerializer.Deserialize<Dictionary<string, int>>(chestType.RarityWeightsJson)
                ?? new Dictionary<string, int> { { "common", 70 }, { "rare", 20 }, { "epic", 8 }, { "legendary", 2 } };
        }
        catch
        {
            rarityWeights = new Dictionary<string, int> { { "common", 70 }, { "rare", 20 }, { "epic", 8 }, { "legendary", 2 } };
        }

        // Load all cards grouped by rarity
        var allCards = await _db.Cards
            .Include(c => c.CardSet)
            .ToListAsync(ct);

        var cardsByRarity = allCards.GroupBy(c => c.Rarity)
            .ToDictionary(g => g.Key, g => g.ToList());

        var cardsReceived = new List<CardDto>();
        var userCardsMap = await _db.UserCards
            .Where(uc => uc.UserId == userId)
            .ToDictionaryAsync(uc => uc.CardId, ct);

        for (int q = 0; q < quantity; q++)
        {
            int cardCount = Random.Shared.Next(chestType.CardCountMin, chestType.CardCountMax + 1);
            for (int i = 0; i < cardCount; i++)
            {
                string rarity = PickRarityByWeights(rarityWeights);

                List<Card>? candidates;
                if (!cardsByRarity.TryGetValue(rarity, out candidates) || candidates.Count == 0)
                    candidates = allCards.Count > 0 ? allCards : null;

                if (candidates == null || candidates.Count == 0) continue;

                var card = candidates[Random.Shared.Next(candidates.Count)];

                // Upsert user card
                if (userCardsMap.TryGetValue(card.Id, out var existing))
                {
                    existing.Quantity++;
                }
                else
                {
                    var newUserCard = new UserCard
                    {
                        UserId = userId,
                        CardId = card.Id,
                        Quantity = 1
                    };
                    _db.UserCards.Add(newUserCard);
                    userCardsMap[card.Id] = newUserCard;
                }

                cardsReceived.Add(new CardDto(card.Id, card.Name, card.Description, card.Rarity, card.ImageUrl, 1, true));
            }
        }

        user.TotalCards += cardsReceived.Count;
        await _db.SaveChangesAsync(ct);

        // Check for completed sets
        var completedSets = new List<string>();
        var allSets = await _db.CardSets.Include(s => s.Cards).ToListAsync(ct);
        var updatedUserCards = await _db.UserCards.Where(uc => uc.UserId == userId).ToDictionaryAsync(uc => uc.CardId, ct);

        foreach (var set in allSets)
        {
            bool allOwned = set.Cards.Count > 0 && set.Cards.All(c => updatedUserCards.ContainsKey(c.Id));
            if (allOwned)
            {
                // Award rewards
                if (set.RewardCoins > 0) user.Coins += set.RewardCoins;
                if (set.RewardSpins > 0) user.Spins = Math.Min(50, user.Spins + set.RewardSpins);
                if (set.RewardGems > 0) user.Gems += set.RewardGems;
                completedSets.Add(set.Name);
            }
        }

        if (completedSets.Any())
            await _db.SaveChangesAsync(ct);

        await tx.CommitAsync(ct);

        _logger.LogInformation("User {UserId} opened {Qty}x chest {ChestId}, received {Count} cards", userId, quantity, chestTypeId, cardsReceived.Count);

        return new OpenChestResultDto(
            CardsReceived: cardsReceived,
            SetsCompleted: completedSets,
            CoinsSpent: totalCost,
            CoinsRemaining: user.Coins
        );
    }

    public async Task<CardCollectionSummaryDto> GetCollectionAsync(Guid userId, CancellationToken ct)
    {
        var allSets = await _db.CardSets.Include(s => s.Cards).ToListAsync(ct);
        var userCards = await _db.UserCards
            .Where(uc => uc.UserId == userId)
            .ToDictionaryAsync(uc => uc.CardId, uc => uc.Quantity, ct);

        var setDtos = allSets.Select(set =>
        {
            var cardDtos = set.Cards.Select(c => new CardDto(
                c.Id, c.Name, c.Description, c.Rarity, c.ImageUrl,
                userCards.GetValueOrDefault(c.Id, 0),
                userCards.ContainsKey(c.Id)
            )).ToList();

            int ownedCount = cardDtos.Count(c => c.IsOwned);
            bool isComplete = set.Cards.Count > 0 && ownedCount == set.Cards.Count;

            return new CardSetDto(set.Id, set.Name, set.Theme, cardDtos, ownedCount, set.Cards.Count, isComplete);
        }).ToList();

        int totalOwned = userCards.Values.Sum();
        int totalUnique = userCards.Count;

        return new CardCollectionSummaryDto(totalOwned, totalUnique, setDtos);
    }

    public async Task<TradeDto> InitiateTradeAsync(Guid senderId, Guid receiverId, Guid offeredCardId, Guid requestedCardId, CancellationToken ct)
    {
        // Verify sender owns the offered card
        var senderCard = await _db.UserCards
            .FirstOrDefaultAsync(uc => uc.UserId == senderId && uc.CardId == offeredCardId && uc.Quantity > 0, ct)
            ?? throw new InvalidOperationException("You don't own the offered card.");

        var receiver = await _db.Users.FirstOrDefaultAsync(u => u.Id == receiverId, ct)
            ?? throw new KeyNotFoundException("Receiver not found.");

        var offeredCard = await _db.Cards.FirstOrDefaultAsync(c => c.Id == offeredCardId, ct)
            ?? throw new KeyNotFoundException("Offered card not found.");

        var requestedCard = await _db.Cards.FirstOrDefaultAsync(c => c.Id == requestedCardId, ct)
            ?? throw new KeyNotFoundException("Requested card not found.");

        var sender = await _db.Users.FirstOrDefaultAsync(u => u.Id == senderId, ct)!;

        var trade = new TradeRequest
        {
            SenderId = senderId,
            ReceiverId = receiverId,
            OfferedCardId = offeredCardId,
            RequestedCardId = requestedCardId,
            Status = "pending",
            ExpiresAt = DateTime.UtcNow.AddDays(2)
        };
        _db.TradeRequests.Add(trade);
        await _db.SaveChangesAsync(ct);

        return new TradeDto(
            trade.Id,
            sender!.DisplayName,
            receiver.DisplayName,
            new CardDto(offeredCard.Id, offeredCard.Name, offeredCard.Description, offeredCard.Rarity, offeredCard.ImageUrl, senderCard.Quantity, true),
            new CardDto(requestedCard.Id, requestedCard.Name, requestedCard.Description, requestedCard.Rarity, requestedCard.ImageUrl, 0, false),
            trade.Status,
            trade.ExpiresAt
        );
    }

    public async Task<TradeDto> RespondTradeAsync(Guid userId, Guid tradeId, bool accept, CancellationToken ct)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var trade = await _db.TradeRequests
            .Include(t => t.Sender)
            .Include(t => t.Receiver)
            .Include(t => t.OfferedCard)
            .Include(t => t.RequestedCard)
            .FirstOrDefaultAsync(t => t.Id == tradeId && t.ReceiverId == userId, ct)
            ?? throw new KeyNotFoundException("Trade not found.");

        if (trade.Status != "pending")
            throw new InvalidOperationException("Trade is no longer pending.");

        if (trade.ExpiresAt < DateTime.UtcNow)
        {
            trade.Status = "expired";
            await _db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);
            throw new InvalidOperationException("Trade has expired.");
        }

        if (accept)
        {
            // Verify receiver owns the requested card
            var receiverCard = await _db.UserCards
                .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CardId == trade.RequestedCardId && uc.Quantity > 0, ct)
                ?? throw new InvalidOperationException("You don't own the requested card.");

            // Verify sender still owns offered card
            var senderCard = await _db.UserCards
                .FirstOrDefaultAsync(uc => uc.UserId == trade.SenderId && uc.CardId == trade.OfferedCardId && uc.Quantity > 0, ct)
                ?? throw new InvalidOperationException("Sender no longer owns the offered card.");

            // Execute trade: deduct from each, add to other
            senderCard.Quantity--;
            receiverCard.Quantity--;

            // Add to sender (requested card)
            var senderRequestedCard = await _db.UserCards
                .FirstOrDefaultAsync(uc => uc.UserId == trade.SenderId && uc.CardId == trade.RequestedCardId, ct);
            if (senderRequestedCard != null)
                senderRequestedCard.Quantity++;
            else
                _db.UserCards.Add(new UserCard { UserId = trade.SenderId, CardId = trade.RequestedCardId, Quantity = 1 });

            // Add to receiver (offered card)
            var receiverOfferedCard = await _db.UserCards
                .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CardId == trade.OfferedCardId, ct);
            if (receiverOfferedCard != null)
                receiverOfferedCard.Quantity++;
            else
                _db.UserCards.Add(new UserCard { UserId = userId, CardId = trade.OfferedCardId, Quantity = 1 });

            trade.Status = "accepted";
        }
        else
        {
            trade.Status = "declined";
        }

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        var offeredCardInfo = trade.OfferedCard;
        var requestedCardInfo = trade.RequestedCard;

        return new TradeDto(
            trade.Id,
            trade.Sender.DisplayName,
            trade.Receiver.DisplayName,
            new CardDto(offeredCardInfo.Id, offeredCardInfo.Name, offeredCardInfo.Description, offeredCardInfo.Rarity, offeredCardInfo.ImageUrl, 0, true),
            new CardDto(requestedCardInfo.Id, requestedCardInfo.Name, requestedCardInfo.Description, requestedCardInfo.Rarity, requestedCardInfo.ImageUrl, 0, true),
            trade.Status,
            trade.ExpiresAt
        );
    }

    public async Task<List<TradeDto>> GetPendingTradesAsync(Guid userId, CancellationToken ct)
    {
        var trades = await _db.TradeRequests
            .Include(t => t.Sender)
            .Include(t => t.Receiver)
            .Include(t => t.OfferedCard)
            .Include(t => t.RequestedCard)
            .Where(t => (t.ReceiverId == userId || t.SenderId == userId)
                && t.Status == "pending"
                && t.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync(ct);

        return trades.Select(t => new TradeDto(
            t.Id,
            t.Sender.DisplayName,
            t.Receiver.DisplayName,
            new CardDto(t.OfferedCard.Id, t.OfferedCard.Name, t.OfferedCard.Description, t.OfferedCard.Rarity, t.OfferedCard.ImageUrl, 0, true),
            new CardDto(t.RequestedCard.Id, t.RequestedCard.Name, t.RequestedCard.Description, t.RequestedCard.Rarity, t.RequestedCard.ImageUrl, 0, true),
            t.Status,
            t.ExpiresAt
        )).ToList();
    }
}
