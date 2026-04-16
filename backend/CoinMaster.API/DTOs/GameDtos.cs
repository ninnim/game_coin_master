namespace CoinMaster.API.DTOs;

public record AttackRequest(Guid TargetUserId);
public record AttackResultDto(
    bool WasBlocked, long CoinsStolen, string? BuildingDestroyed,
    bool PetBonusApplied, decimal PetBonus, Guid AttackId, string DefenderName
);

public record RaidRequest(Guid VictimId, List<int> HolePositions);
public record HoleResultDto(int Position, long CoinsFound);
public record RaidResultDto(
    long TotalCoinsStolen, List<HoleResultDto> HolesResults,
    bool PetExtraHole, string VictimName
);

public record PlayerTargetDto(Guid UserId, string DisplayName, string? AvatarUrl, int VillageLevel, long PigBankCoins);

public record PlayerStateDto(
    UserDto User,
    VillageDto CurrentVillage,
    List<UserBuildingDto> Buildings,
    PetDto? ActivePet,
    List<PetDto> AllPets,
    CardCollectionSummaryDto Cards,
    int PendingAttacks,
    int PendingRaids,
    List<ActiveEventDto> ActiveEvents,
    int UnreadNotifications,
    List<RecentAttackDto> RecentAttacks
);
