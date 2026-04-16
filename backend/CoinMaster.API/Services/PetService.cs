using CoinMaster.API.Data;
using CoinMaster.API.DTOs;
using CoinMaster.API.Models;
using Microsoft.EntityFrameworkCore;

namespace CoinMaster.API.Services;

public class PetService
{
    private readonly AppDbContext _db;
    private readonly ILogger<PetService> _logger;

    public PetService(AppDbContext db, ILogger<PetService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public decimal GetPetAbilityStrength(UserPet up, Pet pet)
    {
        return pet.AbilityType switch
        {
            "extra_hole" => up.Level >= 11 ? 1m : 0m,    // Foxy: extra hole if level >= 11
            "coin_boost" => up.Level * 0.10m,             // Tiger: 10% coin bonus per level
            "shield_chance" => up.Level * 0.05m,          // Rhino: 5% shield chance per level
            _ => 0m
        };
    }

    public async Task<List<PetDto>> GetUserPetsAsync(Guid userId, CancellationToken ct)
    {
        var userPets = await _db.UserPets
            .Include(up => up.Pet)
            .Where(up => up.UserId == userId)
            .ToListAsync(ct);

        return userPets.Select(up => new PetDto(
            PetId: up.PetId,
            Name: up.Pet.Name,
            AbilityType: up.Pet.AbilityType,
            AbilityDescription: up.Pet.AbilityDescription,
            ImageUrl: up.Pet.ImageUrl,
            Level: up.Level,
            Xp: up.Xp,
            TreatsFed: up.TreatsFed,
            IsActive: up.IsActive,
            MaxLevel: up.Pet.MaxLevel,
            AbilityStrength: GetPetAbilityStrength(up, up.Pet)
        )).ToList();
    }

    public async Task<PetDto> ActivatePetAsync(Guid userId, Guid petId, CancellationToken ct)
    {
        var allPets = await _db.UserPets
            .Include(up => up.Pet)
            .Where(up => up.UserId == userId)
            .ToListAsync(ct);

        var target = allPets.FirstOrDefault(up => up.PetId == petId)
            ?? throw new KeyNotFoundException("Pet not found in your collection.");

        // Deactivate all
        foreach (var p in allPets) p.IsActive = false;

        // Activate target
        target.IsActive = true;

        // Update user's active pet
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)!;
        user!.ActivePetId = petId;

        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("User {UserId} activated pet {PetId}", userId, petId);

        return new PetDto(
            PetId: target.PetId,
            Name: target.Pet.Name,
            AbilityType: target.Pet.AbilityType,
            AbilityDescription: target.Pet.AbilityDescription,
            ImageUrl: target.Pet.ImageUrl,
            Level: target.Level,
            Xp: target.Xp,
            TreatsFed: target.TreatsFed,
            IsActive: true,
            MaxLevel: target.Pet.MaxLevel,
            AbilityStrength: GetPetAbilityStrength(target, target.Pet)
        );
    }

    public async Task<FeedResultDto> FeedPetAsync(Guid userId, Guid petId, int treats, CancellationToken ct)
    {
        if (treats < 1 || treats > 100)
            throw new InvalidOperationException("Treats must be between 1 and 100.");

        var userPet = await _db.UserPets
            .Include(up => up.Pet)
            .FirstOrDefaultAsync(up => up.UserId == userId && up.PetId == petId, ct)
            ?? throw new KeyNotFoundException("Pet not found in your collection.");

        int oldLevel = userPet.Level;
        int xpGained = treats; // 1 treat = 1 XP

        if (userPet.Level >= userPet.Pet.MaxLevel)
            throw new InvalidOperationException("Pet is already at maximum level.");

        userPet.Xp += xpGained;
        userPet.TreatsFed += treats;

        // Level up logic: treatsPerLevel XP per level
        int xpPerLevel = userPet.Pet.TreatsPerLevel;
        bool leveledUp = false;

        while (userPet.Xp >= xpPerLevel && userPet.Level < userPet.Pet.MaxLevel)
        {
            userPet.Xp -= xpPerLevel;
            userPet.Level++;
            leveledUp = true;
        }

        await _db.SaveChangesAsync(ct);
        _logger.LogInformation("User {UserId} fed pet {PetId}, level {Old}->{New}", userId, petId, oldLevel, userPet.Level);

        return new FeedResultDto(
            NewLevel: userPet.Level,
            XpGained: xpGained,
            LeveledUp: leveledUp,
            AbilityStrength: GetPetAbilityStrength(userPet, userPet.Pet)
        );
    }

    public async Task InitializeUserPetsAsync(Guid userId, CancellationToken ct)
    {
        var pets = await _db.Pets.ToListAsync(ct);
        if (!pets.Any()) return;

        var existing = await _db.UserPets.Where(up => up.UserId == userId).Select(up => up.PetId).ToListAsync(ct);

        bool first = true;
        foreach (var pet in pets)
        {
            if (existing.Contains(pet.Id)) continue;

            _db.UserPets.Add(new UserPet
            {
                UserId = userId,
                PetId = pet.Id,
                Level = 1,
                Xp = 0,
                IsActive = first // first pet is active by default
            });
            first = false;
        }

        if (!existing.Any() && pets.Any())
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
            if (user != null) user.ActivePetId = pets[0].Id;
        }

        await _db.SaveChangesAsync(ct);
    }
}
