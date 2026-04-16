using System.Security.Claims;
using CoinMaster.API.DTOs;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api/notifications")]
public class NotificationController : ControllerBase
{
    private readonly NotificationService _notificationService;
    private readonly ILogger<NotificationController> _logger;

    public NotificationController(NotificationService notificationService, ILogger<NotificationController> logger)
    {
        _notificationService = notificationService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<List<NotificationDto>>> GetNotifications(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var notifications = await _notificationService.GetUnreadAsync(userId, ct);
        return Ok(notifications);
    }

    [HttpPut("read")]
    public async Task<ActionResult> MarkAllRead(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        await _notificationService.MarkAllReadAsync(userId, ct);
        return Ok(new { message = "All notifications marked as read." });
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteNotification(Guid id, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        await _notificationService.DeleteAsync(userId, id, ct);
        return Ok(new { message = "Notification deleted." });
    }
}
