using System.Security.Claims;
using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api/clans")]
public class ClanController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ILogger<ClanController> _logger;

    public ClanController(AppDbContext db, ILogger<ClanController> logger)
    {
        _db = db;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<List<ClanDto>>> GetPublicClans(CancellationToken ct)
    {
        var clans = await _db.Clans
            .Include(c => c.Leader)
            .Where(c => c.IsPublic)
            .OrderByDescending(c => c.TotalPoints)
            .Take(50)
            .ToListAsync(ct);

        return Ok(clans.Select(c => new ClanDto(
            c.Id, c.Name, c.Description, c.MemberCount, c.TotalPoints,
            c.IsPublic, c.MinVillageLevel, c.Leader.DisplayName, c.CreatedAt
        )));
    }

    [HttpPost]
    public async Task<ActionResult<ClanDto>> CreateClan([FromBody] CreateClanRequest req, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Name) || req.Name.Length < 2 || req.Name.Length > 50)
            return BadRequest(new { error = "Clan name must be between 2 and 50 characters." });

        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        // Check if user is already in a clan
        var existingMembership = await _db.ClanMembers
            .AnyAsync(cm => cm.UserId == userId, ct);
        if (existingMembership)
            return BadRequest(new { error = "You are already in a clan." });

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)!;

        var clan = new Clan
        {
            Name = req.Name.Trim(),
            Description = req.Description?.Trim(),
            LeaderId = userId,
            IsPublic = req.IsPublic,
            MemberCount = 1
        };
        _db.Clans.Add(clan);

        var member = new ClanMember
        {
            ClanId = clan.Id,
            UserId = userId,
            Role = "leader"
        };
        _db.ClanMembers.Add(member);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} created clan {ClanId}", userId, clan.Id);

        return CreatedAtAction(nameof(GetClan), new { id = clan.Id },
            new ClanDto(clan.Id, clan.Name, clan.Description, 1, 0, clan.IsPublic, clan.MinVillageLevel, user!.DisplayName, clan.CreatedAt));
    }

    [HttpGet("my")]
    public async Task<ActionResult<ClanDetailDto?>> GetMyClan(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var membership = await _db.ClanMembers
            .Include(cm => cm.Clan).ThenInclude(c => c.Leader)
            .FirstOrDefaultAsync(cm => cm.UserId == userId, ct);

        if (membership == null) return Ok(null);

        return await GetClanDetail(membership.ClanId, userId, ct);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ClanDetailDto>> GetClan(Guid id, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var detail = await GetClanDetail(id, userId, ct);
        if (detail == null) return NotFound(new { error = "Clan not found." });
        return Ok(detail);
    }

    [HttpPost("{id}/join")]
    public async Task<ActionResult> JoinClan(Guid id, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user == null) return NotFound(new { error = "User not found." });

        var clan = await _db.Clans.FirstOrDefaultAsync(c => c.Id == id && c.IsPublic, ct);
        if (clan == null) return NotFound(new { error = "Clan not found or is private." });

        if (user.VillageLevel < clan.MinVillageLevel)
            return BadRequest(new { error = $"You need to be at least village level {clan.MinVillageLevel} to join." });

        var existing = await _db.ClanMembers.AnyAsync(cm => cm.UserId == userId, ct);
        if (existing)
            return BadRequest(new { error = "You are already in a clan." });

        _db.ClanMembers.Add(new ClanMember { ClanId = id, UserId = userId, Role = "member" });
        clan.MemberCount++;
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} joined clan {ClanId}", userId, id);
        return Ok(new { message = "Joined clan successfully!" });
    }

    private async Task<ClanDetailDto?> GetClanDetail(Guid clanId, Guid currentUserId, CancellationToken ct)
    {
        var clan = await _db.Clans
            .Include(c => c.Leader)
            .Include(c => c.Members).ThenInclude(m => m.User)
            .FirstOrDefaultAsync(c => c.Id == clanId, ct);

        if (clan == null) return null;

        var currentMember = clan.Members.FirstOrDefault(m => m.UserId == currentUserId);

        var clanDto = new ClanDto(clan.Id, clan.Name, clan.Description, clan.MemberCount, clan.TotalPoints,
            clan.IsPublic, clan.MinVillageLevel, clan.Leader.DisplayName, clan.CreatedAt);

        var memberDtos = clan.Members
            .OrderByDescending(m => m.PointsContributed)
            .Select(m => new ClanMemberDto(m.UserId, m.User.DisplayName, m.User.AvatarUrl, m.Role, m.PointsContributed, m.WeeklySpins))
            .ToList();

        return new ClanDetailDto(clanDto, memberDtos, currentMember?.Role);
    }
}
