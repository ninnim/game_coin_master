using System.Security.Claims;
using CoinMaster.API.DTOs;
using CoinMaster.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CoinMaster.API.Controllers;

[Authorize]
[ApiController]
[Route("api/pets")]
public class PetController : ControllerBase
{
    private readonly PetService _petService;
    private readonly ILogger<PetController> _logger;

    public PetController(PetService petService, ILogger<PetController> logger)
    {
        _petService = petService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<List<PetDto>>> GetPets(CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var pets = await _petService.GetUserPetsAsync(userId, ct);
        return Ok(pets);
    }

    [HttpPost("{petId}/activate")]
    public async Task<ActionResult<PetDto>> ActivatePet(Guid petId, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var pet = await _petService.ActivatePetAsync(userId, petId, ct);
        return Ok(pet);
    }

    [HttpPost("{petId}/feed")]
    public async Task<ActionResult<FeedResultDto>> FeedPet(Guid petId, [FromBody] FeedPetRequest req, CancellationToken ct)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var result = await _petService.FeedPetAsync(userId, petId, req.Treats, ct);
        return Ok(result);
    }
}
