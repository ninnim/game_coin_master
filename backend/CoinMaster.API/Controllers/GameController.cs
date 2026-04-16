using System.Security.Claims;
using CoinMaster.API.DTOs;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api")]
public class GameController : ControllerBase
{
    private readonly AttackService _attackService;
    private readonly RaidService _raidService;
    private readonly PlayerStateService _playerState;
    private readonly ILogger<GameController> _logger;

    public GameController(
        AttackService attackService,
        RaidService raidService,
        PlayerStateService playerState,
        ILogger<GameController> logger)
    {
        _attackService = attackService;
        _raidService = raidService;
        _playerState = playerState;
        _logger = logger;
    }

    [HttpPost("attack")]
    public async Task<ActionResult<AttackResultDto>> Attack([FromBody] AttackRequest req, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _attackService.AttackAsync(userId, req.TargetUserId, ct);
        return Ok(result);
    }

    [HttpPost("raid")]
    public async Task<ActionResult<RaidResultDto>> Raid([FromBody] RaidRequest req, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _raidService.RaidAsync(userId, req.VictimId, req.HolePositions, ct);
        return Ok(result);
    }

    [HttpGet("player/state")]
    public async Task<ActionResult<PlayerStateDto>> GetState(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var state = await _playerState.GetStateAsync(userId, ct);
        return Ok(state);
    }

    [HttpGet("player/targets")]
    public async Task<ActionResult<List<PlayerTargetDto>>> GetTargets(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var targets = await _attackService.GetTargetsAsync(userId, ct);
        return Ok(targets);
    }
}
