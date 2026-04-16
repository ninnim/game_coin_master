namespace CoinMaster.API.DTOs;

public record CreateClanRequest(string Name, string? Description, bool IsPublic = true);
public record ClanDto(Guid Id, string Name, string? Description, int MemberCount, long TotalPoints, bool IsPublic, int MinVillageLevel, string LeaderName, DateTime CreatedAt);
public record ClanMemberDto(Guid UserId, string DisplayName, string? AvatarUrl, string Role, long PointsContributed, int WeeklySpins);
public record ClanDetailDto(ClanDto Clan, List<ClanMemberDto> Members, string? CurrentUserRole);
