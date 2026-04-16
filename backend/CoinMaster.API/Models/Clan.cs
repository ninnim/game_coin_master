using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("clans")]
public class Clan
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("name")] public string Name { get; set; } = null!;
    [Column("leader_id")] public Guid LeaderId { get; set; }
    [Column("description")] public string? Description { get; set; }
    [Column("badge_image")] public string? BadgeImage { get; set; }
    [Column("is_public")] public bool IsPublic { get; set; } = true;
    [Column("total_points")] public long TotalPoints { get; set; } = 0;
    [Column("member_count")] public int MemberCount { get; set; } = 1;
    [Column("min_village_level")] public int MinVillageLevel { get; set; } = 1;
    [Column("created_at")] public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public User Leader { get; set; } = null!;
    public ICollection<ClanMember> Members { get; set; } = new List<ClanMember>();
}
