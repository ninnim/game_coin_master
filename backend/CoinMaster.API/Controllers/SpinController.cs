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
[Route("api/spin")]
public class SpinController : ControllerBase
{
    private readonly SpinService _spinService;
    private readonly AppDbContext _db;
    private readonly ILogger<SpinController> _logger;

    public SpinController(SpinService spinService, AppDbContext db, ILogger<SpinController> logger)
    {
        _spinService = spinService;
        _db = db;
        _logger = logger;
    }

    [HttpPost]
    public async Task<ActionResult<SpinResultDto>> Spin([FromBody] SpinRequest req, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _spinService.SpinAsync(userId, req.BetMultiplier, ct);
        return Ok(result);
    }

    [HttpGet("history")]
    public async Task<ActionResult<List<object>>> GetHistory(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var history = await _spinService.GetHistoryAsync(userId, ct);
        var result = history.Select(s => new
        {
            s.Id,
            s.Slot1,
            s.Slot2,
            s.Slot3,
            s.ResultType,
            s.CoinsEarned,
            s.SpinsEarned,
            s.BetMultiplier,
            s.PetBonusApplied,
            s.CreatedAt
        });
        return Ok(result);
    }

    [HttpPut("bet")]
    public async Task<ActionResult> SetBet([FromBody] SetBetRequest req, CancellationToken ct)
    {
        int[] allowed = { 1, 2, 3, 5, 10 };
        if (!allowed.Contains(req.Multiplier))
            return BadRequest(new { error = "Bet multiplier must be 1, 2, 3, 5, or 10." });

        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user == null) return NotFound(new { error = "User not found." });

        user.BetMultiplier = req.Multiplier;
        await _db.SaveChangesAsync(ct);
        return Ok(new { betMultiplier = req.Multiplier });
    }
}
