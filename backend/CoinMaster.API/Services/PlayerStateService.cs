using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class PlayerStateService
{
    private readonly AppDbContext _db;
    private readonly CardService _cardService;
    private readonly PetService _petService;
    private readonly EventService _eventService;
    private readonly NotificationService _notificationService;
    private readonly SocialService _socialService;
    private readonly ILogger<PlayerStateService> _logger;

    public PlayerStateService(
        AppDbContext db,
        CardService cardService,
        PetService petService,
        EventService eventService,
        NotificationService notificationService,
        SocialService socialService,
        ILogger<PlayerStateService> logger)
    {
        _db = db;
        _cardService = cardService;
        _petService = petService;
        _eventService = eventService;
        _notificationService = notificationService;
        _socialService = socialService;
        _logger = logger;
    }

    public async Task<PlayerStateDto> GetStateAsync(Guid userId, CancellationToken ct)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new KeyNotFoundException("User not found.");

        var userDto = new UserDto(
            user.Id, user.Email, user.DisplayName, user.AvatarUrl,
            user.Coins, user.Spins, user.Gems, user.VillageLevel,
            user.ShieldCount, user.TotalStars, user.PigBankCoins, user.CreatedAt
        );

        // Current village
        var activeVillage = await _db.UserVillages
            .Include(uv => uv.Village)
            .FirstOrDefaultAsync(uv => uv.UserId == userId && uv.IsActive && !uv.IsCompleted, ct);

        VillageDto villageDto;
        if (activeVillage != null)
        {
            villageDto = new VillageDto(
                activeVillage.Village.Id, activeVillage.Village.Name, activeVillage.Village.Theme,
                activeVillage.Village.OrderNum, activeVillage.Village.IsBoom,
                activeVillage.Village.SkyColor, activeVillage.Village.Description,
                activeVillage.IsCompleted, activeVillage.IsActive
            );
        }
        else
        {
            // Fallback to first village
            var firstVillage = await _db.Villages.OrderBy(v => v.OrderNum).FirstOrDefaultAsync(ct);
            villageDto = firstVillage != null
                ? new VillageDto(firstVillage.Id, firstVillage.Name, firstVillage.Theme,
                    firstVillage.OrderNum, firstVillage.IsBoom, firstVillage.SkyColor,
                    firstVillage.Description, false, true)
                : new VillageDto(Guid.Empty, "Default Village", "default", 1, false, "#1565C0", null, false, true);
        }

        // Buildings
        List<UserBuildingDto> buildingDtos = new();
        if (activeVillage != null)
        {
            var buildings = await _db.Buildings
                .Where(b => b.VillageId == activeVillage.VillageId)
                .ToListAsync(ct);

            var userBuildings = await _db.UserBuildings
                .Where(ub => ub.UserId == userId && buildings.Select(b => b.Id).Contains(ub.BuildingId))
                .ToDictionaryAsync(ub => ub.BuildingId, ct);

            buildingDtos = buildings.Select(b =>
            {
                userBuildings.TryGetValue(b.Id, out var ub);
                int level = ub?.UpgradeLevel ?? 0;
                long nextCost = b.UpgradeCosts.Length > level ? b.UpgradeCosts[level] : 0;
                return new UserBuildingDto(
                    b.Id, b.Name, b.ImageBase, b.PositionX, b.PositionY,
                    level, ub?.IsDestroyed ?? false, nextCost, user.Coins >= nextCost
                );
            }).ToList();
        }

        // Pets
        var allPets = await _petService.GetUserPetsAsync(userId, ct);
        var activePet = allPets.FirstOrDefault(p => p.IsActive);

        // Cards summary
        var cardSummary = await _cardService.GetCollectionAsync(userId, ct);

        // Unread notifications
        int unreadCount = await _notificationService.GetUnreadCountAsync(userId, ct);

        // Active events (last 3)
        var activeEvents = await _eventService.GetActiveEventsAsync(userId, ct);

        // Recent attacks (last 3)
        var recentAttacks = await _socialService.GetRecentAttacksAsync(userId, ct);
        var last3Attacks = recentAttacks.Take(3).ToList();

        // Pending attacks/raids (unread notifications of those types)
        int pendingAttacks = await _db.Notifications
            .CountAsync(n => n.UserId == userId && n.Type == "attack" && !n.IsRead, ct);
        int pendingRaids = await _db.Notifications
            .CountAsync(n => n.UserId == userId && n.Type == "raid" && !n.IsRead, ct);

        return new PlayerStateDto(
            User: userDto,
            CurrentVillage: villageDto,
            Buildings: buildingDtos,
            ActivePet: activePet,
            AllPets: allPets,
            Cards: cardSummary,
            PendingAttacks: pendingAttacks,
            PendingRaids: pendingRaids,
            ActiveEvents: activeEvents,
            UnreadNotifications: unreadCount,
            RecentAttacks: last3Attacks
        );
    }
}
