using System.Security.Claims;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api/events")]
public class EventController : ControllerBase
{
    private readonly EventService _eventService;
    private readonly ILogger<EventController> _logger;

    public EventController(EventService eventService, ILogger<EventController> logger)
    {
        _eventService = eventService;
        _logger = logger;
    }

    [HttpGet("active")]
    public async Task<ActionResult<List<ActiveEventDto>>> GetActiveEvents(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var events = await _eventService.GetActiveEventsAsync(userId, ct);
        return Ok(events);
    }

    [HttpGet("history")]
    public async Task<ActionResult<List<GameEvent>>> GetEventHistory(CancellationToken ct)
    {
        var events = await _eventService.GetPastEventsAsync(ct);
        return Ok(events);
    }
}
