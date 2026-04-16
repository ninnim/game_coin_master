using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("trade_requests")]
public class TradeRequest
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("sender_id")] public Guid SenderId { get; set; }
    [Column("receiver_id")] public Guid ReceiverId { get; set; }
    [Column("offered_card_id")] public Guid OfferedCardId { get; set; }
    [Column("requested_card_id")] public Guid RequestedCardId { get; set; }
    [Column("status")] public string Status { get; set; } = "pending";
    [Column("expires_at")] public DateTime ExpiresAt { get; set; } = DateTime.UtcNow.AddDays(2);
    [Column("created_at")] public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public User Sender { get; set; } = null!;
    public User Receiver { get; set; } = null!;
    public Card OfferedCard { get; set; } = null!;
    public Card RequestedCard { get; set; } = null!;
}
