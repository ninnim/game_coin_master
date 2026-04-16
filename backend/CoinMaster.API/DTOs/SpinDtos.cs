namespace CoinMaster.API.DTOs;

public record SpinRequest(int BetMultiplier = 1);
public record SpinResultDto(
    string Slot1, string Slot2, string Slot3,
    string ResultType,
    long CoinsEarned, int SpinsEarned,
    int SpinsRemaining, long CurrentCoins,
    int BetMultiplier,
    string? SpecialAction,
    bool PetBonusApplied,
    SpinAnimationDto Animation
);
public record SpinAnimationDto(int[] StopDelayMs, bool IsJackpot, string SymbolColor);
public record SetBetRequest(int Multiplier);
