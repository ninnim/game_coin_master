using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("raids")]
public class Raid
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("raider_id")] public Guid RaiderId { get; set; }
    [Column("victim_id")] public Guid VictimId { get; set; }
    [Column("holes_dug")] public int HolesDug { get; set; } = 3;
    [Column("holes_positions")] public int[] HolesPositions { get; set; } = [];
    [Column("coins_stolen")] public long CoinsStolen { get; set; } = 0;
    [Column("bet_multiplier")] public int BetMultiplier { get; set; } = 1;
    [Column("pet_bonus_extra_hole")] public bool PetBonusExtraHole { get; set; } = false;
    [Column("created_at")] public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public User Raider { get; set; } = null!;
    public User Victim { get; set; } = null!;
}
