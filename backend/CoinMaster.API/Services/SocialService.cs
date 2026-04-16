using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Hubs;
using CoinMaster.API.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class SocialService
{
    private readonly AppDbContext _db;
    private readonly GameSettings _settings;
    private readonly IHubContext<GameHub> _hub;
    private readonly NotificationService _notifications;
    private readonly AttackService _attackService;
    private readonly ILogger<SocialService> _logger;

    public SocialService(
        AppDbContext db,
        GameSettings settings,
        IHubContext<GameHub> hub,
        NotificationService notifications,
        AttackService attackService,
        ILogger<SocialService> logger)
    {
        _db = db;
        _settings = settings;
        _hub = hub;
        _notifications = notifications;
        _attackService = attackService;
        _logger = logger;
    }

    public async Task<List<FriendDto>> GetFriendsAsync(Guid userId, CancellationToken ct)
    {
        var friendships = await _db.Friendships
            .Include(f => f.Friend)
            .Where(f => f.UserId == userId && f.Status == "accepted")
            .ToListAsync(ct);

        // Also include incoming accepted
        var incomingFriendships = await _db.Friendships
            .Include(f => f.User)
            .Where(f => f.FriendId == userId && f.Status == "accepted")
            .ToListAsync(ct);

        var result = new List<FriendDto>();

        foreach (var f in friendships)
        {
            bool canGift = f.SpinsGiftedToday == 0 || f.SpinsGiftedResetAt < DateTime.UtcNow;
            result.Add(new FriendDto(
                f.FriendId, f.Friend.DisplayName, f.Friend.AvatarUrl,
                f.Friend.VillageLevel,
                GameHub.IsUserOnline(f.FriendId.ToString()),
                canGift,
                f.Status
            ));
        }

        foreach (var f in incomingFriendships)
        {
            if (result.Any(r => r.UserId == f.UserId)) continue;
            result.Add(new FriendDto(
                f.UserId, f.User.DisplayName, f.User.AvatarUrl,
                f.User.VillageLevel,
                GameHub.IsUserOnline(f.UserId.ToString()),
                false,
                f.Status
            ));
        }

        return result;
    }

    public async Task<Friendship> SendFriendRequestAsync(Guid userId, Guid targetId, CancellationToken ct)
    {
        if (userId == targetId)
            throw new InvalidOperationException("Cannot add yourself.");

        var target = await _db.Users.FirstOrDefaultAsync(u => u.Id == targetId, ct)
            ?? throw new KeyNotFoundException("User not found.");

        var existing = await _db.Friendships
            .FirstOrDefaultAsync(f => (f.UserId == userId && f.FriendId == targetId)
                || (f.UserId == targetId && f.FriendId == userId), ct);

        if (existing != null)
            throw new InvalidOperationException($"Friendship already exists with status: {existing.Status}");

        var friendship = new Friendship
        {
            UserId = userId,
            FriendId = targetId,
            Status = "pending"
        };
        _db.Friendships.Add(friendship);
        await _db.SaveChangesAsync(ct);

        await _notifications.CreateAsync(targetId, "friend_request", "Friend Request",
            $"You have a new friend request!", null, ct);

        return friendship;
    }

    public async Task<Friendship> RespondFriendRequestAsync(Guid userId, Guid friendshipId, bool accept, CancellationToken ct)
    {
        var friendship = await _db.Friendships
            .FirstOrDefaultAsync(f => f.Id == friendshipId && f.FriendId == userId, ct)
            ?? throw new KeyNotFoundException("Friend request not found.");

        friendship.Status = accept ? "accepted" : "declined";
        await _db.SaveChangesAsync(ct);

        if (accept)
        {
            await _notifications.CreateAsync(friendship.UserId, "friend_accepted", "Friend Request Accepted",
                "Your friend request was accepted!", null, ct);
        }

        return friendship;
    }

    public async Task GiftSpinAsync(Guid senderId, Guid receiverId, CancellationToken ct)
    {
        var friendship = await _db.Friendships
            .FirstOrDefaultAsync(f => f.UserId == senderId && f.FriendId == receiverId && f.Status == "accepted", ct)
            ?? await _db.Friendships
                .FirstOrDefaultAsync(f => f.UserId == receiverId && f.FriendId == senderId && f.Status == "accepted", ct)
            ?? throw new InvalidOperationException("Not friends with this user.");

        // Check daily gift limit
        if (friendship.SpinsGiftedResetAt < DateTime.UtcNow)
        {
            friendship.SpinsGiftedToday = 0;
            friendship.SpinsGiftedResetAt = DateTime.UtcNow.AddHours(_settings.SpinGiftCooldownHours);
        }

        if (friendship.SpinsGiftedToday >= 1)
            throw new InvalidOperationException("You already gifted a spin to this friend today.");

        var receiver = await _db.Users.FirstOrDefaultAsync(u => u.Id == receiverId, ct)
            ?? throw new KeyNotFoundException("Receiver not found.");

        receiver.Spins = Math.Min(_settings.MaxSpins, receiver.Spins + 1);
        friendship.SpinsGiftedToday++;

        await _db.SaveChangesAsync(ct);

        var sender = await _db.Users.FirstOrDefaultAsync(u => u.Id == senderId, ct);
        await _notifications.CreateAsync(receiverId, "spin_gift", "Free Spin!",
            $"{sender?.DisplayName} gifted you a free spin!", null, ct);

        await _hub.Clients.Group($"user_{receiverId}").SendAsync("OnSpinReceived", new { from = sender?.DisplayName }, ct);
        _logger.LogInformation("User {SenderId} gifted spin to {ReceiverId}", senderId, receiverId);
    }

    public async Task<List<LeaderboardEntryDto>> GetLeaderboardAsync(string type, string period, CancellationToken ct)
    {
        IQueryable<Models.User> query = _db.Users.Where(u => !u.IsBanned);

        List<(Guid Id, string DisplayName, string? AvatarUrl, long Value, int VillageLevel)> entries;

        switch (type.ToLower())
        {
            case "village":
                entries = await query
                    .OrderByDescending(u => u.VillageLevel).ThenByDescending(u => u.TotalStars)
                    .Take(100)
                    .Select(u => new ValueTuple<Guid, string, string?, long, int>(u.Id, u.DisplayName, u.AvatarUrl, (long)u.VillageLevel, u.VillageLevel))
                    .ToListAsync(ct);
                break;
            case "cards":
                entries = await query
                    .OrderByDescending(u => u.TotalCards)
                    .Take(100)
                    .Select(u => new ValueTuple<Guid, string, string?, long, int>(u.Id, u.DisplayName, u.AvatarUrl, (long)u.TotalCards, u.VillageLevel))
                    .ToListAsync(ct);
                break;
            case "attacks":
                entries = await query
                    .OrderByDescending(u => u.TotalAttacks)
                    .Take(100)
                    .Select(u => new ValueTuple<Guid, string, string?, long, int>(u.Id, u.DisplayName, u.AvatarUrl, (long)u.TotalAttacks, u.VillageLevel))
                    .ToListAsync(ct);
                break;
            default: // coins
                entries = await query
                    .OrderByDescending(u => u.Coins)
                    .Take(100)
                    .Select(u => new ValueTuple<Guid, string, string?, long, int>(u.Id, u.DisplayName, u.AvatarUrl, u.Coins, u.VillageLevel))
                    .ToListAsync(ct);
                break;
        }

        return entries.Select((e, i) => new LeaderboardEntryDto(i + 1, e.Id, e.DisplayName, e.AvatarUrl, e.Value, e.VillageLevel)).ToList();
    }

    public async Task<RevengeResultDto> RevengeAsync(Guid userId, Guid attackId, CancellationToken ct)
    {
        var attack = await _db.Attacks
            .Include(a => a.Attacker)
            .FirstOrDefaultAsync(a => a.Id == attackId && a.DefenderId == userId, ct)
            ?? throw new KeyNotFoundException("Attack not found.");

        if (attack.WasRevenged)
            throw new InvalidOperationException("Already revenged this attack.");

        if (attack.RevengeDeadline.HasValue && attack.RevengeDeadline < DateTime.UtcNow)
            throw new InvalidOperationException("Revenge window has expired.");

        // Execute counter-attack
        try
        {
            var result = await _attackService.AttackAsync(userId, attack.AttackerId, ct);
            attack.WasRevenged = true;
            await _db.SaveChangesAsync(ct);

            return new RevengeResultDto(true, result.CoinsStolen, $"Successfully revenged against {attack.Attacker.DisplayName}!");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Revenge failed for user {UserId} on attack {AttackId}", userId, attackId);
            return new RevengeResultDto(false, 0, ex.Message);
        }
    }

    public async Task<List<RecentAttackDto>> GetRecentAttacksAsync(Guid userId, CancellationToken ct)
    {
        var attacks = await _db.Attacks
            .Include(a => a.Attacker)
            .Where(a => a.DefenderId == userId)
            .OrderByDescending(a => a.CreatedAt)
            .Take(10)
            .ToListAsync(ct);

        return attacks.Select(a => new RecentAttackDto(
            a.Id,
            a.Attacker.DisplayName,
            a.Attacker.AvatarUrl,
            a.CoinsStolen,
            a.WasBlockedByShield,
            a.CreatedAt,
            !a.WasRevenged && a.RevengeDeadline.HasValue && a.RevengeDeadline > DateTime.UtcNow,
            a.WasRevenged
        )).ToList();
    }
}
