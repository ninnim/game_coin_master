using System.Security.Claims;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api")]
public class SocialController : ControllerBase
{
    private readonly SocialService _socialService;
    private readonly ILogger<SocialController> _logger;

    public SocialController(SocialService socialService, ILogger<SocialController> logger)
    {
        _socialService = socialService;
        _logger = logger;
    }

    [HttpGet("friends")]
    public async Task<ActionResult<List<FriendDto>>> GetFriends(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var friends = await _socialService.GetFriendsAsync(userId, ct);
        return Ok(friends);
    }

    [HttpPost("friends/{targetUserId}/request")]
    public async Task<ActionResult> SendFriendRequest(Guid targetUserId, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var friendship = await _socialService.SendFriendRequestAsync(userId, targetUserId, ct);
        return Ok(new { message = "Friend request sent.", friendshipId = friendship.Id });
    }

    [HttpPut("friends/{requestId}/respond")]
    public async Task<ActionResult> RespondFriendRequest(Guid requestId, [FromBody] bool accept, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var friendship = await _socialService.RespondFriendRequestAsync(userId, requestId, accept, ct);
        return Ok(new { status = friendship.Status });
    }

    [HttpPost("friends/{targetUserId}/gift-spin")]
    public async Task<ActionResult> GiftSpin(Guid targetUserId, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        await _socialService.GiftSpinAsync(userId, targetUserId, ct);
        return Ok(new { message = "Spin gifted successfully!" });
    }

    [HttpGet("leaderboard")]
    public async Task<ActionResult<List<LeaderboardEntryDto>>> GetLeaderboard(
        [FromQuery] string type = "coins",
        [FromQuery] string period = "alltime",
        CancellationToken ct = default)
    {
        var leaderboard = await _socialService.GetLeaderboardAsync(type, period, ct);
        return Ok(leaderboard);
    }

    [HttpPost("revenge/{attackId}")]
    public async Task<ActionResult<RevengeResultDto>> Revenge(Guid attackId, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _socialService.RevengeAsync(userId, attackId, ct);
        return Ok(result);
    }
}
