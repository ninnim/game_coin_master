namespace CoinMaster.API.DTOs;

public record PetDto(Guid PetId, string Name, string AbilityType, string AbilityDescription, string? ImageUrl, int Level, int Xp, int TreatsFed, bool IsActive, int MaxLevel, decimal AbilityStrength);
public record FeedPetRequest(int Treats);
public record FeedResultDto(int NewLevel, int XpGained, bool LeveledUp, decimal AbilityStrength);
