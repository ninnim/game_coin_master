using System.Security.Claims;
using System.Text.RegularExpressions;
using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly JwtService _jwt;
    private readonly PetService _petService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(AppDbContext db, JwtService jwt, PetService petService, ILogger<AuthController> logger)
    {
        _db = db;
        _jwt = jwt;
        _petService = petService;
        _logger = logger;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest req, CancellationToken ct)
    {
        // Validate email
        if (string.IsNullOrWhiteSpace(req.Email) || !Regex.IsMatch(req.Email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$"))
            return BadRequest(new { error = "Invalid email format." });

        if (req.Email.Length > 255)
            return BadRequest(new { error = "Email must be at most 255 characters." });

        // Validate password
        if (string.IsNullOrWhiteSpace(req.Password) || req.Password.Length < 6)
            return BadRequest(new { error = "Password must be at least 6 characters." });

        if (req.Password.Length > 100)
            return BadRequest(new { error = "Password must be at most 100 characters." });

        // Validate displayName
        if (string.IsNullOrWhiteSpace(req.DisplayName) || req.DisplayName.Trim().Length < 2)
            return BadRequest(new { error = "Display name must be at least 2 characters." });

        if (req.DisplayName.Length > 100)
            return BadRequest(new { error = "Display name must be at most 100 characters." });

        // Check uniqueness
        if (await _db.Users.AnyAsync(u => u.Email == req.Email.ToLower(), ct))
        {
            _logger.LogInformation("Register failed: email already exists {Email}", req.Email);
            return BadRequest(new { error = "An account with this email already exists." });
        }

        var user = new User
        {
            Email = req.Email.ToLower().Trim(),
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
            DisplayName = req.DisplayName.Trim(),
            LastLoginAt = DateTime.UtcNow,
            LoginStreak = 1
        };
        _db.Users.Add(user);

        // Setup first village
        var firstVillage = await _db.Villages.OrderBy(v => v.OrderNum).FirstOrDefaultAsync(ct);
        if (firstVillage != null)
        {
            _db.UserVillages.Add(new UserVillage
            {
                UserId = user.Id,
                VillageId = firstVillage.Id,
                IsActive = true
            });
        }

        await _db.SaveChangesAsync(ct);

        // Initialize pets
        await _petService.InitializeUserPetsAsync(user.Id, ct);

        _logger.LogInformation("User registered: {Email}", user.Email);

        var token = _jwt.GenerateToken(user.Id, user.Email);
        var userDto = ToDto(user);
        return CreatedAtAction(nameof(Me), new AuthResponse(token, userDto));
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest req, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(new { error = "Email and password are required." });

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == req.Email.ToLower().Trim(), ct);
        if (user == null || !BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
        {
            _logger.LogInformation("Login failed for {Email}", req.Email);
            return Unauthorized(new { error = "Invalid email or password." });
        }

        if (user.IsBanned)
            return Unauthorized(new { error = "This account has been banned." });

        // Login streak
        if (user.LastLoginAt.HasValue)
        {
            var daysSinceLast = (DateTime.UtcNow - user.LastLoginAt.Value).TotalDays;
            if (daysSinceLast >= 1 && daysSinceLast < 2)
                user.LoginStreak = Math.Min(user.LoginStreak + 1, 7);
            else if (daysSinceLast >= 2)
                user.LoginStreak = 1;
        }
        else
        {
            user.LoginStreak = 1;
        }

        user.LastLoginAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("User logged in: {Email}, streak={Streak}", user.Email, user.LoginStreak);

        var token = _jwt.GenerateToken(user.Id, user.Email);
        return Ok(new AuthResponse(token, ToDto(user)));
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> Me(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user == null) return NotFound(new { error = "User not found." });
        return Ok(ToDto(user));
    }

    private static UserDto ToDto(User u) => new(
        u.Id, u.Email, u.DisplayName, u.AvatarUrl,
        u.Coins, u.Spins, u.Gems, u.VillageLevel,
        u.ShieldCount, u.TotalStars, u.PigBankCoins, u.CreatedAt
    );
}
