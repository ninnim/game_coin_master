using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("achievements")]
public class Achievement
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("key")] public string Key { get; set; } = null!;
    [Column("title")] public string Title { get; set; } = null!;
    [Column("description")] public string Description { get; set; } = null!;
    [Column("icon_url")] public string? IconUrl { get; set; }
    [Column("category")] public string Category { get; set; } = null!;
    [Column("target_value")] public int TargetValue { get; set; } = 1;
    [Column("reward_coins")] public long RewardCoins { get; set; } = 0;
    [Column("reward_spins")] public int RewardSpins { get; set; } = 0;
    [Column("reward_gems")] public int RewardGems { get; set; } = 0;
    [Column("display_order")] public int DisplayOrder { get; set; } = 0;
}
