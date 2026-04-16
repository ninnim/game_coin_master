using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("user_event_progress")]
public class UserEventProgress
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("event_id")] public Guid EventId { get; set; }
    [Column("progress")] public int Progress { get; set; } = 0;
    [Column("is_claimed")] public bool IsClaimed { get; set; } = false;
    [Column("created_at")] public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public User User { get; set; } = null!;
    public GameEvent Event { get; set; } = null!;
}
