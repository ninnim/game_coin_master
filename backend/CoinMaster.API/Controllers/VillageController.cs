using System.Security.Claims;
using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api")]
public class VillageController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly BuildingService _buildingService;
    private readonly ILogger<VillageController> _logger;

    public VillageController(AppDbContext db, BuildingService buildingService, ILogger<VillageController> logger)
    {
        _db = db;
        _buildingService = buildingService;
        _logger = logger;
    }

    [HttpGet("villages")]
    public async Task<ActionResult<List<VillageDto>>> GetAllVillages(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var villages = await _db.Villages.OrderBy(v => v.OrderNum).ToListAsync(ct);
        var userVillages = await _db.UserVillages
            .Where(uv => uv.UserId == userId)
            .ToDictionaryAsync(uv => uv.VillageId, ct);

        return Ok(villages.Select(v =>
        {
            userVillages.TryGetValue(v.Id, out var uv);
            return new VillageDto(v.Id, v.Name, v.Theme, v.OrderNum, v.IsBoom, v.SkyColor, v.Description,
                uv?.IsCompleted ?? false, uv?.IsActive ?? false);
        }));
    }

    [HttpGet("villages/current")]
    public async Task<ActionResult<object>> GetCurrentVillage(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user == null) return NotFound(new { error = "User not found." });

        var activeVillage = await _db.UserVillages
            .Include(uv => uv.Village).ThenInclude(v => v.Buildings)
            .FirstOrDefaultAsync(uv => uv.UserId == userId && uv.IsActive && !uv.IsCompleted, ct);

        if (activeVillage == null)
            return NotFound(new { error = "No active village found." });

        var buildingIds = activeVillage.Village.Buildings.Select(b => b.Id).ToList();
        var userBuildings = await _db.UserBuildings
            .Where(ub => ub.UserId == userId && buildingIds.Contains(ub.BuildingId))
            .ToDictionaryAsync(ub => ub.BuildingId, ct);

        var villageDto = new VillageDto(
            activeVillage.Village.Id, activeVillage.Village.Name, activeVillage.Village.Theme,
            activeVillage.Village.OrderNum, activeVillage.Village.IsBoom,
            activeVillage.Village.SkyColor, activeVillage.Village.Description,
            activeVillage.IsCompleted, activeVillage.IsActive
        );

        var buildingDtos = activeVillage.Village.Buildings.Select(b =>
        {
            userBuildings.TryGetValue(b.Id, out var ub);
            int level = ub?.UpgradeLevel ?? 0;
            long nextCost = b.UpgradeCosts.Length > level ? b.UpgradeCosts[level] : 0;
            return new UserBuildingDto(
                b.Id, b.Name, b.ImageBase, b.PositionX, b.PositionY,
                level, ub?.IsDestroyed ?? false, nextCost, user.Coins >= nextCost
            );
        }).ToList();

        return Ok(new { Village = villageDto, Buildings = buildingDtos });
    }

    [HttpPost("buildings/{buildingId}/upgrade")]
    public async Task<ActionResult<BuildResultDto>> UpgradeBuilding(Guid buildingId, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _buildingService.UpgradeBuildingAsync(userId, buildingId, ct);
        return Ok(result);
    }
}
