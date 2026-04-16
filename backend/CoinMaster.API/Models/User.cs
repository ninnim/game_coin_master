using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CoinMaster.API.Models;

[Table("users")]
public class User
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("email")] public string Email { get; set; } = null!;
    [Column("password_hash")] public string PasswordHash { get; set; } = null!;
    [Column("display_name")] public string DisplayName { get; set; } = null!;
    [Column("avatar_url")] public string? AvatarUrl { get; set; }
    [Column("coins")] public long Coins { get; set; } = 500;
    [Column("spins")] public int Spins { get; set; } = 50;
    [Column("gems")] public int Gems { get; set; } = 10;
    [Column("village_level")] public int VillageLevel { get; set; } = 1;
    [Column("pig_bank_coins")] public long PigBankCoins { get; set; } = 0;
    [Column("shield_count")] public int ShieldCount { get; set; } = 0;
    [Column("total_stars")] public int TotalStars { get; set; } = 0;
    [Column("spin_refill_at")] public DateTime SpinRefillAt { get; set; } = DateTime.UtcNow;
    [Column("bet_multiplier")] public int BetMultiplier { get; set; } = 1;
    [Column("active_pet_id")] public Guid? ActivePetId { get; set; }
    [Column("last_login_at")] public DateTime? LastLoginAt { get; set; }
    [Column("login_streak")] public int LoginStreak { get; set; } = 0;
    [Column("weekly_spins_used")] public int WeeklySpinsUsed { get; set; } = 0;
    [Column("total_attacks")] public int TotalAttacks { get; set; } = 0;
    [Column("total_raids")] public int TotalRaids { get; set; } = 0;
    [Column("total_cards")] public int TotalCards { get; set; } = 0;
    [Column("is_banned")] public bool IsBanned { get; set; } = false;
    [Column("created_at")] public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<SpinResult> SpinResults { get; set; } = new List<SpinResult>();
    public ICollection<UserCard> UserCards { get; set; } = new List<UserCard>();
    public ICollection<UserPet> UserPets { get; set; } = new List<UserPet>();
    public ICollection<UserVillage> UserVillages { get; set; } = new List<UserVillage>();
    public ICollection<UserBuilding> UserBuildings { get; set; } = new List<UserBuilding>();
}
