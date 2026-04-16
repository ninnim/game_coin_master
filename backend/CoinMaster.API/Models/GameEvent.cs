using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("events")]
public class GameEvent
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("type")] public string Type { get; set; } = null!;
    [Column("title")] public string Title { get; set; } = null!;
    [Column("description")] public string? Description { get; set; }
    [Column("banner_image")] public string? BannerImage { get; set; }
    [Column("starts_at")] public DateTime StartsAt { get; set; }
    [Column("ends_at")] public DateTime EndsAt { get; set; }
    [Column("reward_json")] public string RewardJson { get; set; } = "{}";
    [Column("rules_json")] public string? RulesJson { get; set; }
    [Column("is_active")] public bool IsActive { get; set; } = true;
}
