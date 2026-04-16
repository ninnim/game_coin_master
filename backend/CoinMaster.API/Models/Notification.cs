using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("notifications")]
public class Notification
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("type")] public string Type { get; set; } = null!;
    [Column("title")] public string Title { get; set; } = null!;
    [Column("message")] public string Message { get; set; } = null!;
    [Column("data_json")] public string? DataJson { get; set; }
    [Column("is_read")] public bool IsRead { get; set; } = false;
    [Column("created_at")] public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public User User { get; set; } = null!;
}
