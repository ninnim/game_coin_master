namespace CoinMaster.API.Services;

public class GameSettings
{
    public int MaxSpins { get; set; } = 50;
    public int SpinRefillRate { get; set; } = 5;
    public int SpinRefillIntervalMinutes { get; set; } = 60;
    public int MaxShields { get; set; } = 3;
    public double AttackCoinStealPercent { get; set; } = 0.20;
    public double RaidCoinStealPercent { get; set; } = 0.33;
    public int PigBankFillRatePerSpin { get; set; } = 100;
    public int JackpotMultiplier { get; set; } = 50;
    public int SpinGiftCooldownHours { get; set; } = 24;
    public int RevengeWindowHours { get; set; } = 24;
    public int MaxDailyLoginStreak { get; set; } = 7;
}
