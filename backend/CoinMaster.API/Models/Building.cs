using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("buildings")]
public class Building
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("village_id")] public Guid VillageId { get; set; }
    [Column("name")] public string Name { get; set; } = null!;
    [Column("image_base")] public string ImageBase { get; set; } = null!;
    [Column("position_x")] public decimal PositionX { get; set; }
    [Column("position_y")] public decimal PositionY { get; set; }
    [Column("upgrade_costs")] public long[] UpgradeCosts { get; set; } = [];
    [Column("description")] public string? Description { get; set; }
    [Column("building_order")] public int BuildingOrder { get; set; } = 0;
    public Village Village { get; set; } = null!;
}
