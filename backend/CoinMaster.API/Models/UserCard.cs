using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("user_cards")]
public class UserCard
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("card_id")] public Guid CardId { get; set; }
    [Column("quantity")] public int Quantity { get; set; } = 1;
    [Column("first_obtained_at")] public DateTime FirstObtainedAt { get; set; } = DateTime.UtcNow;
    public User User { get; set; } = null!;
    public Card Card { get; set; } = null!;
}
