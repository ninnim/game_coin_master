using System.ComponentModel.DataAnnotations.Schema;

namespace CoinMaster.API.Models;

[Table("chest_types")]
public class ChestType
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("name")] public string Name { get; set; } = null!;
    [Column("price_coins")] public long PriceCoins { get; set; }
    [Column("card_count_min")] public int CardCountMin { get; set; } = 1;
    [Column("card_count_max")] public int CardCountMax { get; set; } = 3;
    [Column("rarity_weights")] public string RarityWeightsJson { get; set; } = "{}";
    [Column("image_url")] public string? ImageUrl { get; set; }
}
