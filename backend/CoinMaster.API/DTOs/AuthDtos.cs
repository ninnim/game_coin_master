namespace CoinMaster.API.DTOs;

public record RegisterRequest(string Email, string Password, string DisplayName);
public record LoginRequest(string Email, string Password);
public record AuthResponse(string Token, UserDto User);
public record UserDto(Guid Id, string Email, string DisplayName, string? AvatarUrl, long Coins, int Spins, int Gems, int VillageLevel, int ShieldCount, int TotalStars, long PigBankCoins, DateTime CreatedAt);
