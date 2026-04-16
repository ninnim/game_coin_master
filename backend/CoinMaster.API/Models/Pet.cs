using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("pets")]
public class Pet
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("name")] public string Name { get; set; } = null!;
    [Column("ability_type")] public string AbilityType { get; set; } = null!;
    [Column("ability_description")] public string AbilityDescription { get; set; } = null!;
    [Column("image_url")] public string? ImageUrl { get; set; }
    [Column("max_level")] public int MaxLevel { get; set; } = 20;
    [Column("treats_per_level")] public int TreatsPerLevel { get; set; } = 10;
    public ICollection<UserPet> UserPets { get; set; } = new List<UserPet>();
}
