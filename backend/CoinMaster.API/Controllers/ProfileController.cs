using System.Security.Claims;
using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api/profile")]
public class ProfileController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ILogger<ProfileController> _logger;
    private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".gif" };
    private const long MaxFileSize = 50 * 1024 * 1024; // 50MB

    public ProfileController(AppDbContext db, ILogger<ProfileController> logger)
    {
        _db = db;
        _logger = logger;
    }

    [HttpPut]
    public async Task<ActionResult<UserDto>> UpdateProfile([FromBody] UpdateProfileRequest req, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user == null) return NotFound(new { error = "User not found." });

        if (!string.IsNullOrWhiteSpace(req.DisplayName))
        {
            if (req.DisplayName.Trim().Length < 2 || req.DisplayName.Length > 100)
                return BadRequest(new { error = "Display name must be between 2 and 100 characters." });
            user.DisplayName = req.DisplayName.Trim();
        }

        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("User {UserId} updated profile", userId);

        return Ok(new UserDto(user.Id, user.Email, user.DisplayName, user.AvatarUrl,
            user.Coins, user.Spins, user.Gems, user.VillageLevel,
            user.ShieldCount, user.TotalStars, user.PigBankCoins, user.CreatedAt));
    }

    [HttpGet("{userId}")]
    public async Task<ActionResult<object>> GetPublicProfile(Guid userId, CancellationToken ct)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user == null) return NotFound(new { error = "User not found." });

        return Ok(new
        {
            user.Id,
            user.DisplayName,
            user.AvatarUrl,
            user.VillageLevel,
            user.TotalStars,
            user.TotalAttacks,
            user.TotalRaids,
            user.TotalCards,
            user.LoginStreak,
            user.CreatedAt
        });
    }

    [HttpPost("avatar")]
    public async Task<ActionResult<object>> UploadAvatar([FromForm] IFormFile file, CancellationToken ct)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { error = "No file provided." });

        if (file.Length > MaxFileSize)
            return BadRequest(new { error = "File size exceeds 50MB limit." });

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(ext))
            return BadRequest(new { error = "Invalid file type. Allowed: jpg, jpeg, png, gif." });

        // Validate content type header
        var allowedContentTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif" };
        if (!allowedContentTypes.Contains(file.ContentType.ToLower()))
            return BadRequest(new { error = "Invalid content type." });

        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user == null) return NotFound(new { error = "User not found." });

        // Sanitize filename - strip path traversal chars
        var originalName = Path.GetFileNameWithoutExtension(file.FileName)
            .Replace("..", "").Replace("/", "").Replace("\\", "")
            .Replace(" ", "_");
        var safeFileName = $"{Guid.NewGuid()}_{originalName}{ext}";

        var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "uploads");
        Directory.CreateDirectory(uploadsDir);
        var filePath = Path.Combine(uploadsDir, safeFileName);

        await using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream, ct);
        }

        user.AvatarUrl = $"/uploads/{safeFileName}";
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("User {UserId} uploaded avatar: {File}", userId, safeFileName);

        return Ok(new { avatarUrl = user.AvatarUrl });
    }
}

public record UpdateProfileRequest(string? DisplayName);
