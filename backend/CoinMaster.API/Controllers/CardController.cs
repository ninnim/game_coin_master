using System.Security.Claims;
using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api")]
public class CardController : ControllerBase
{
    private readonly CardService _cardService;
    private readonly AppDbContext _db;
    private readonly ILogger<CardController> _logger;

    public CardController(CardService cardService, AppDbContext db, ILogger<CardController> logger)
    {
        _cardService = cardService;
        _db = db;
        _logger = logger;
    }

    [HttpGet("cards")]
    public async Task<ActionResult<CardCollectionSummaryDto>> GetCollection(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _cardService.GetCollectionAsync(userId, ct);
        return Ok(result);
    }

    [HttpGet("chests")]
    public async Task<ActionResult<List<ChestTypeDto>>> GetChestTypes(CancellationToken ct)
    {
        var chests = await _db.ChestTypes
            .Select(c => new ChestTypeDto(c.Id, c.Name, c.PriceCoins, c.CardCountMin, c.CardCountMax, c.ImageUrl))
            .ToListAsync(ct);
        return Ok(chests);
    }

    [HttpPost("chests/open")]
    public async Task<ActionResult<OpenChestResultDto>> OpenChest([FromBody] OpenChestRequest req, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _cardService.OpenChestAsync(userId, req.ChestTypeId, req.Quantity, ct);
        return Ok(result);
    }

    [HttpPost("trades")]
    public async Task<ActionResult<TradeDto>> InitiateTrade([FromBody] InitiateTradeRequest req, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _cardService.InitiateTradeAsync(userId, req.ReceiverId, req.OfferedCardId, req.RequestedCardId, ct);
        return CreatedAtAction(nameof(GetTrades), result);
    }

    [HttpGet("trades")]
    public async Task<ActionResult<List<TradeDto>>> GetTrades(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var trades = await _cardService.GetPendingTradesAsync(userId, ct);
        return Ok(trades);
    }

    [HttpPut("trades/{id}/respond")]
    public async Task<ActionResult<TradeDto>> RespondTrade(Guid id, [FromBody] TradeResponseRequest req, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _cardService.RespondTradeAsync(userId, id, req.Accept, ct);
        return Ok(result);
    }
}
