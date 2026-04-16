using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("villages")]
public class Village
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("name")] public string Name { get; set; } = null!;
    [Column("theme")] public string Theme { get; set; } = null!;
    [Column("order_num")] public int OrderNum { get; set; }
    [Column("is_boom")] public bool IsBoom { get; set; } = false;
    [Column("background_image")] public string? BackgroundImage { get; set; }
    [Column("music_track")] public string? MusicTrack { get; set; }
    [Column("sky_color")] public string SkyColor { get; set; } = "#1565C0";
    [Column("total_build_cost")] public long TotalBuildCost { get; set; } = 0;
    [Column("description")] public string? Description { get; set; }
    public ICollection<Building> Buildings { get; set; } = new List<Building>();
}
