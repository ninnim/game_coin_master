using System.ComponentModel.DataAnnotations.Schema;
namespace CoinMaster.API.Models;

[Table("user_pets")]
public class UserPet
{
    [Column("id")] public Guid Id { get; set; } = Guid.NewGuid();
    [Column("user_id")] public Guid UserId { get; set; }
    [Column("pet_id")] public Guid PetId { get; set; }
    [Column("level")] public int Level { get; set; } = 1;
    [Column("xp")] public int Xp { get; set; } = 0;
    [Column("is_active")] public bool IsActive { get; set; } = false;
    [Column("treats_fed")] public int TreatsFed { get; set; } = 0;
    public User User { get; set; } = null!;
    public Pet Pet { get; set; } = null!;
}
