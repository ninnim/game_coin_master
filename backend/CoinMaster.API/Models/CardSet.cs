using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("card_sets")]
public class CardSet
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("name")] public string Name { get; set; } = null!;
    [Column("theme")] public string Theme { get; set; } = null!;
    [Column("image_url")] public string? ImageUrl { get; set; }
    [Column("reward_coins")] public long RewardCoins { get; set; } = 0;
    [Column("reward_spins")] public int RewardSpins { get; set; } = 0;
    [Column("reward_gems")] public int RewardGems { get; set; } = 0;
    public ICollection<Card> Cards { get; set; } = new List<Card>();
}
