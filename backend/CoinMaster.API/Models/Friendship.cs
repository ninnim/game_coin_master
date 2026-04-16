using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("friendships")]
public class Friendship
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("friend_id")] public Guid FriendId { get; set; }
    [Column("status")] public string Status { get; set; } = "pending";
    [Column("spins_gifted_today")] public int SpinsGiftedToday { get; set; } = 0;
    [Column("spins_gifted_reset_at")] public DateTime SpinsGiftedResetAt { get; set; } = DateTime.UtcNow;
    [Column("created_at")] public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public User User { get; set; } = null!;
    public User Friend { get; set; } = null!;
}
