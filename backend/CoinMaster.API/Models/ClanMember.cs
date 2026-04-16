using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("clan_members")]
public class ClanMember
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("clan_id")] public Guid ClanId { get; set; }
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("role")] public string Role { get; set; } = "member";
    [Column("points_contributed")] public long PointsContributed { get; set; } = 0;
    [Column("weekly_spins")] public int WeeklySpins { get; set; } = 0;
    [Column("joined_at")] public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    public Clan Clan { get; set; } = null!;
    public User User { get; set; } = null!;
}
