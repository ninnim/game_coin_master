using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("attacks")]
public class Attack
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("attacker_id")] public Guid AttackerId { get; set; }
    [Column("defender_id")] public Guid DefenderId { get; set; }
    [Column("building_id")] public Guid? BuildingId { get; set; }
    [Column("coins_stolen")] public long CoinsStolen { get; set; } = 0;
    [Column("was_blocked_by_shield")] public bool WasBlockedByShield { get; set; } = false;
    [Column("was_revenged")] public bool WasRevenged { get; set; } = false;
    [Column("revenge_deadline")] public DateTime? RevengeDeadline { get; set; }
    [Column("bet_multiplier")] public int BetMultiplier { get; set; } = 1;
    [Column("pet_bonus")] public decimal PetBonus { get; set; } = 0;
    [Column("created_at")] public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public User Attacker { get; set; } = null!;
    public User Defender { get; set; } = null!;
}
