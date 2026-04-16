class AttackResultModel {
  final bool wasBlocked;
  final int coinsStolen;
  final String? buildingDestroyed;
  final String defenderName;
  final String attackId;

  const AttackResultModel({
    required this.wasBlocked,
    required this.coinsStolen,
    this.buildingDestroyed,
    required this.defenderName,
    required this.attackId,
  });

  factory AttackResultModel.fromJson(Map<String, dynamic> j) =>
      AttackResultModel(
        wasBlocked: j['wasBlocked'] ?? false,
        coinsStolen: j['coinsStolen'] ?? 0,
        buildingDestroyed: j['buildingDestroyed'],
        defenderName: j['defenderName'] ?? '',
        attackId: j['attackId'] ?? '',
      );
}

class RecentAttackModel {
  final String attackId;
  final String attackerName;
  final String? attackerAvatar;
  final int coinsStolen;
  final bool wasBlocked;
  final bool canRevenge;
  final bool wasRevenged;

  const RecentAttackModel({
    required this.attackId,
    required this.attackerName,
    this.attackerAvatar,
    required this.coinsStolen,
    required this.wasBlocked,
    required this.canRevenge,
    required this.wasRevenged,
  });

  factory RecentAttackModel.fromJson(Map<String, dynamic> j) =>
      RecentAttackModel(
        attackId: j['attackId'] ?? '',
        attackerName: j['attackerName'] ?? 'Unknown',
        attackerAvatar: j['attackerAvatar'],
        coinsStolen: j['coinsStolen'] ?? 0,
        wasBlocked: j['wasBlocked'] ?? false,
        canRevenge: j['canRevenge'] ?? false,
        wasRevenged: j['wasRevenged'] ?? false,
      );
}

class PlayerTargetModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int villageLevel;
  final int pigBankCoins;

  const PlayerTargetModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.villageLevel,
    required this.pigBankCoins,
  });

  factory PlayerTargetModel.fromJson(Map<String, dynamic> j) =>
      PlayerTargetModel(
        userId: j['userId'] ?? '',
        displayName: j['displayName'] ?? 'Player',
        avatarUrl: j['avatarUrl'],
        villageLevel: j['villageLevel'] ?? 1,
        pigBankCoins: j['pigBankCoins'] ?? 0,
      );
}

class RaidResultModel {
  final int coinsStolen;
  final String defenderName;
  final String raidId;

  const RaidResultModel({
    required this.coinsStolen,
    required this.defenderName,
    required this.raidId,
  });

  factory RaidResultModel.fromJson(Map<String, dynamic> j) => RaidResultModel(
    coinsStolen: j['coinsStolen'] ?? 0,
    defenderName: j['defenderName'] ?? '',
    raidId: j['raidId'] ?? '',
  );
}
