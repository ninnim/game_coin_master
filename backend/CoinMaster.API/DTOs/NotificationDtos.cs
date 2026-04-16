namespace CoinMaster.API.DTOs;

public record NotificationDto(Guid Id, string Type, string Title, string Message, bool IsRead, DateTime CreatedAt, string? DataJson);
