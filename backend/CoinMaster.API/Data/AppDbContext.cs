using Microsoft.EntityFrameworkCore;
using CoinMaster.API.Models;

namespace CoinMaster.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Village> Villages => Set<Village>();
    public DbSet<Building> Buildings => Set<Building>();
    public DbSet<UserVillage> UserVillages => Set<UserVillage>();
    public DbSet<UserBuilding> UserBuildings => Set<UserBuilding>();
    public DbSet<SpinResult> SpinResults => Set<SpinResult>();
    public DbSet<Attack> Attacks => Set<Attack>();
    public DbSet<Raid> Raids => Set<Raid>();
    public DbSet<CardSet> CardSets => Set<CardSet>();
    public DbSet<Card> Cards => Set<Card>();
    public DbSet<UserCard> UserCards => Set<UserCard>();
    public DbSet<ChestType> ChestTypes => Set<ChestType>();
    public DbSet<Pet> Pets => Set<Pet>();
    public DbSet<UserPet> UserPets => Set<UserPet>();
    public DbSet<Friendship> Friendships => Set<Friendship>();
    public DbSet<Clan> Clans => Set<Clan>();
    public DbSet<ClanMember> ClanMembers => Set<ClanMember>();
    public DbSet<GameEvent> Events => Set<GameEvent>();
    public DbSet<UserEventProgress> UserEventProgresses => Set<UserEventProgress>();
    public DbSet<Achievement> Achievements => Set<Achievement>();
    public DbSet<UserAchievement> UserAchievements => Set<UserAchievement>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<TradeRequest> TradeRequests => Set<TradeRequest>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Composite unique indexes
        modelBuilder.Entity<UserVillage>().HasIndex(x => new { x.UserId, x.VillageId }).IsUnique();
        modelBuilder.Entity<UserBuilding>().HasIndex(x => new { x.UserId, x.BuildingId }).IsUnique();
        modelBuilder.Entity<UserCard>().HasIndex(x => new { x.UserId, x.CardId }).IsUnique();
        modelBuilder.Entity<UserPet>().HasIndex(x => new { x.UserId, x.PetId }).IsUnique();
        modelBuilder.Entity<Friendship>().HasIndex(x => new { x.UserId, x.FriendId }).IsUnique();
        modelBuilder.Entity<ClanMember>().HasIndex(x => new { x.ClanId, x.UserId }).IsUnique();
        modelBuilder.Entity<UserEventProgress>().HasIndex(x => new { x.UserId, x.EventId }).IsUnique();
        modelBuilder.Entity<UserAchievement>().HasIndex(x => new { x.UserId, x.AchievementId }).IsUnique();

        // Friendship self-referencing
        modelBuilder.Entity<Friendship>()
            .HasOne(f => f.User).WithMany().HasForeignKey(f => f.UserId).OnDelete(DeleteBehavior.Cascade);
        modelBuilder.Entity<Friendship>()
            .HasOne(f => f.Friend).WithMany().HasForeignKey(f => f.FriendId).OnDelete(DeleteBehavior.Restrict);

        // Attack self-referencing
        modelBuilder.Entity<Attack>()
            .HasOne(a => a.Attacker).WithMany().HasForeignKey(a => a.AttackerId).OnDelete(DeleteBehavior.Cascade);
        modelBuilder.Entity<Attack>()
            .HasOne(a => a.Defender).WithMany().HasForeignKey(a => a.DefenderId).OnDelete(DeleteBehavior.Restrict);

        // Raid self-referencing
        modelBuilder.Entity<Raid>()
            .HasOne(r => r.Raider).WithMany().HasForeignKey(r => r.RaiderId).OnDelete(DeleteBehavior.Cascade);
        modelBuilder.Entity<Raid>()
            .HasOne(r => r.Victim).WithMany().HasForeignKey(r => r.VictimId).OnDelete(DeleteBehavior.Restrict);

        // JSONB columns
        modelBuilder.Entity<ChestType>().Property(c => c.RarityWeightsJson).HasColumnName("rarity_weights").HasColumnType("jsonb");
        modelBuilder.Entity<GameEvent>().Property(e => e.RewardJson).HasColumnName("reward_json").HasColumnType("jsonb");
        modelBuilder.Entity<GameEvent>().Property(e => e.RulesJson).HasColumnName("rules_json").HasColumnType("jsonb");
        modelBuilder.Entity<Notification>().Property(n => n.DataJson).HasColumnName("data_json").HasColumnType("jsonb");

        // Array columns (PostgreSQL)
        modelBuilder.Entity<Building>().Property(b => b.UpgradeCosts).HasColumnType("bigint[]");
        modelBuilder.Entity<Raid>().Property(r => r.HolesPositions).HasColumnType("integer[]");

        // Clan leader
        modelBuilder.Entity<Clan>()
            .HasOne(c => c.Leader).WithMany().HasForeignKey(c => c.LeaderId).OnDelete(DeleteBehavior.Restrict);
    }
}
