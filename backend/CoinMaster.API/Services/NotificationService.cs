using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class NotificationService
{
    private readonly AppDbContext _db;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(AppDbContext db, ILogger<NotificationService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task CreateAsync(Guid userId, string type, string title, string message, string? dataJson, CancellationToken ct = default)
    {
        var notification = new Notification
        {
            UserId = userId,
            Type = type,
            Title = title,
            Message = message,
            DataJson = dataJson
        };
        _db.Notifications.Add(notification);
        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("Created notification type={Type} for user={UserId}", type, userId);
    }

    public async Task<List<NotificationDto>> GetUnreadAsync(Guid userId, CancellationToken ct)
    {
        return await _db.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .Select(n => new NotificationDto(n.Id, n.Type, n.Title, n.Message, n.IsRead, n.CreatedAt, n.DataJson))
            .ToListAsync(ct);
    }

    public async Task MarkAllReadAsync(Guid userId, CancellationToken ct)
    {
        await _db.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true), ct);
    }

    public async Task DeleteAsync(Guid userId, Guid notificationId, CancellationToken ct)
    {
        var notification = await _db.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId, ct)
            ?? throw new KeyNotFoundException("Notification not found.");

        _db.Notifications.Remove(notification);
        await _db.SaveChangesAsync(ct);
    }

    public async Task<int> GetUnreadCountAsync(Guid userId, CancellationToken ct)
    {
        return await _db.Notifications.CountAsync(n => n.UserId == userId && !n.IsRead, ct);
    }
}
