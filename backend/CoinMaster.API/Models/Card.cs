using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("cards")]
public class Card
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("set_id")] public Guid SetId { get; set; }
    [Column("name")] public string Name { get; set; } = null!;
    [Column("description")] public string? Description { get; set; }
    [Column("rarity")] public string Rarity { get; set; } = null!;
    [Column("image_url")] public string? ImageUrl { get; set; }
    [Column("card_order")] public int CardOrder { get; set; } = 0;
    public CardSet CardSet { get; set; } = null!;
}
