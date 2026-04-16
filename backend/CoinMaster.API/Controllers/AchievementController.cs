using System.Security.Claims;
using CoinMaster.API.DTOs;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api/achievements")]
public class AchievementController : ControllerBase
{
    private readonly AchievementService _achievementService;
    private readonly ILogger<AchievementController> _logger;

    public AchievementController(AchievementService achievementService, ILogger<AchievementController> logger)
    {
        _achievementService = achievementService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<List<AchievementDto>>> GetAchievements(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var achievements = await _achievementService.GetAllAsync(userId, ct);
        return Ok(achievements);
    }

    [HttpPost("{id}/claim")]
    public async Task<ActionResult<AchievementDto>> ClaimReward(Guid id, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _achievementService.ClaimRewardAsync(userId, id, ct);
        return Ok(result);
    }
}
