using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("user_villages")]
public class UserVillage
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("village_id")] public Guid VillageId { get; set; }
    [Column("is_completed")] public bool IsCompleted { get; set; } = false;
    [Column("is_active")] public bool IsActive { get; set; } = true;
    [Column("started_at")] public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    [Column("completed_at")] public DateTime? CompletedAt { get; set; }
    public User User { get; set; } = null!;
    public Village Village { get; set; } = null!;
}
