using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("user_achievements")]
public class UserAchievement
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("achievement_id")] public Guid AchievementId { get; set; }
    [Column("current_value")] public int CurrentValue { get; set; } = 0;
    [Column("is_unlocked")] public bool IsUnlocked { get; set; } = false;
    [Column("is_claimed")] public bool IsClaimed { get; set; } = false;
    [Column("unlocked_at")] public DateTime? UnlockedAt { get; set; }
    public User User { get; set; } = null!;
    public Achievement Achievement { get; set; } = null!;
}
