namespace CoinMaster.API.DTOs;

public record CardDto(Guid Id, string Name, string? Description, string Rarity, string? ImageUrl, int Quantity, bool IsOwned);
public record CardSetDto(Guid Id, string Name, string Theme, List<CardDto> Cards, int OwnedCount, int TotalCount, bool IsComplete);
public record CardCollectionSummaryDto(int TotalOwned, int TotalUnique, List<CardSetDto> Sets);
public record OpenChestRequest(Guid ChestTypeId, int Quantity = 1);
public record OpenChestResultDto(List<CardDto> CardsReceived, List<string> SetsCompleted, long CoinsSpent, long CoinsRemaining);
public record ChestTypeDto(Guid Id, string Name, long PriceCoins, int CardCountMin, int CardCountMax, string? ImageUrl);
public record InitiateTradeRequest(Guid ReceiverId, Guid OfferedCardId, Guid RequestedCardId);
public record TradeResponseRequest(bool Accept);
public record TradeDto(Guid Id, string SenderName, string ReceiverName, CardDto OfferedCard, CardDto RequestedCard, string Status, DateTime ExpiresAt);
