class SpinAnimationModel {
  final List<int> stopDelayMs;
  final bool isJackpot;
  final String symbolColor;

  const SpinAnimationModel({
    required this.stopDelayMs,
    required this.isJackpot,
    required this.symbolColor,
  });

  factory SpinAnimationModel.fromJson(Map<String, dynamic> j) =>
      SpinAnimationModel(
        stopDelayMs: List<int>.from(j['stopDelayMs'] ?? [800, 1200, 1600]),
        isJackpot: j['isJackpot'] ?? false,
        symbolColor: j['symbolColor'] ?? '#FFD700',
      );
}

class SpinResultModel {
  final String slot1;
  final String slot2;
  final String slot3;
  final String resultType;
  final int coinsEarned;
  final int spinsEarned;
  final int spinsRemaining;
  final int betMultiplier;
  final int currentCoins;
  final String? specialAction;
  final bool petBonusApplied;
  final SpinAnimationModel animation;

  const SpinResultModel({
    required this.slot1,
    required this.slot2,
    required this.slot3,
    required this.resultType,
    required this.coinsEarned,
    required this.spinsEarned,
    required this.spinsRemaining,
    required this.currentCoins,
    required this.betMultiplier,
    this.specialAction,
    required this.petBonusApplied,
    required this.animation,
  });

  factory SpinResultModel.fromJson(Map<String, dynamic> j) => SpinResultModel(
    slot1: j['slot1'] ?? 'coin_small',
    slot2: j['slot2'] ?? 'coin_small',
    slot3: j['slot3'] ?? 'coin_small',
    resultType: j['resultType'] ?? 'none',
    coinsEarned: j['coinsEarned'] ?? 0,
    spinsEarned: j['spinsEarned'] ?? 0,
    spinsRemaining: j['spinsRemaining'] ?? 0,
    currentCoins: j['currentCoins'] ?? 0,
    betMultiplier: j['betMultiplier'] ?? 1,
    specialAction: j['specialAction'],
    petBonusApplied: j['petBonusApplied'] ?? false,
    animation: SpinAnimationModel.fromJson(
      (j['animation'] as Map<String, dynamic>?) ?? {},
    ),
  );

  bool get isJackpot => slot1 == slot2 && slot2 == slot3;
}
