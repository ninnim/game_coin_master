using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("spin_results")]
public class SpinResult
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("slot1")] public string Slot1 { get; set; } = null!;
    [Column("slot2")] public string Slot2 { get; set; } = null!;
    [Column("slot3")] public string Slot3 { get; set; } = null!;
    [Column("result_type")] public string ResultType { get; set; } = null!;
    [Column("coins_earned")] public long CoinsEarned { get; set; } = 0;
    [Column("spins_earned")] public int SpinsEarned { get; set; } = 0;
    [Column("bet_multiplier")] public int BetMultiplier { get; set; } = 1;
    [Column("pet_bonus_applied")] public bool PetBonusApplied { get; set; } = false;
    [Column("created_at")] public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public User User { get; set; } = null!;
}
