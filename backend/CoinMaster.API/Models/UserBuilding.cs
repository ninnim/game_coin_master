using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("user_buildings")]
public class UserBuilding
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("building_id")] public Guid BuildingId { get; set; }
    [Column("upgrade_level")] public int UpgradeLevel { get; set; } = 0;
    [Column("is_destroyed")] public bool IsDestroyed { get; set; } = false;
    [Column("destroyed_by")] public Guid? DestroyedBy { get; set; }
    [Column("destroyed_at")] public DateTime? DestroyedAt { get; set; }
    [Column("coins_spent")] public long CoinsSpent { get; set; } = 0;
    public User User { get; set; } = null!;
    public Building Building { get; set; } = null!;
}
