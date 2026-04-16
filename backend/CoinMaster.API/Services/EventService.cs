using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class EventService
{
    private readonly AppDbContext _db;
    private readonly ILogger<EventService> _logger;

    public EventService(AppDbContext db, ILogger<EventService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<List<ActiveEventDto>> GetActiveEventsAsync(Guid userId, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var events = await _db.Events
            .Where(e => e.IsActive && e.StartsAt <= now && e.EndsAt >= now)
            .ToListAsync(ct);

        var eventIds = events.Select(e => e.Id).ToList();
        var userProgress = await _db.UserEventProgresses
            .Where(p => p.UserId == userId && eventIds.Contains(p.EventId))
            .ToDictionaryAsync(p => p.EventId, ct);

        return events.Select(e =>
        {
            userProgress.TryGetValue(e.Id, out var prog);
            return new ActiveEventDto(
                e.Id, e.Type, e.Title, e.Description, e.BannerImage,
                e.EndsAt,
                prog?.Progress ?? 0,
                prog?.IsClaimed ?? false
            );
        }).ToList();
    }

    public async Task<UserEventProgress?> GetUserProgressAsync(Guid userId, Guid eventId, CancellationToken ct)
    {
        return await _db.UserEventProgresses
            .FirstOrDefaultAsync(p => p.UserId == userId && p.EventId == eventId, ct);
    }

    public async Task UpdateProgressAsync(Guid userId, string eventType, int amount, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var activeEvents = await _db.Events
            .Where(e => e.IsActive && e.Type == eventType && e.StartsAt <= now && e.EndsAt >= now)
            .ToListAsync(ct);

        foreach (var ev in activeEvents)
        {
            var prog = await _db.UserEventProgresses
                .FirstOrDefaultAsync(p => p.UserId == userId && p.EventId == ev.Id, ct);

            if (prog == null)
            {
                prog = new UserEventProgress { UserId = userId, EventId = ev.Id, Progress = 0 };
                _db.UserEventProgresses.Add(prog);
            }

            prog.Progress += amount;
        }

        if (activeEvents.Any())
            await _db.SaveChangesAsync(ct);
    }

    public async Task<List<GameEvent>> GetPastEventsAsync(CancellationToken ct)
    {
        return await _db.Events
            .Where(e => e.EndsAt < DateTime.UtcNow)
            .OrderByDescending(e => e.EndsAt)
            .Take(20)
            .ToListAsync(ct);
    }
}
