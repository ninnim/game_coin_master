namespace CoinMaster.API.DTOs;

public record ActiveEventDto(Guid Id, string Type, string Title, string? Description, string? BannerImage, DateTime EndsAt, int UserProgress, bool IsClaimed);
