class RaidModel {
  final String raidId;
  final String attackerName;
  final String defenderName;
  final int coinsStolen;
  final DateTime createdAt;

  const RaidModel({
    required this.raidId,
    required this.attackerName,
    required this.defenderName,
    required this.coinsStolen,
    required this.createdAt,
  });

  factory RaidModel.fromJson(Map<String, dynamic> j) => RaidModel(
    raidId: j['raidId'] ?? '',
    attackerName: j['attackerName'] ?? 'Unknown',
    defenderName: j['defenderName'] ?? 'Unknown',
    coinsStolen: j['coinsStolen'] ?? 0,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}
