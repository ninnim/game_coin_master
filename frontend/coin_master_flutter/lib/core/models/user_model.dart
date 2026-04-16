class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final int coins;
  final int spins;
  final int gems;
  final int villageLevel;
  final int shieldCount;
  final int totalStars;
  final int pigBankCoins;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.coins,
    required this.spins,
    required this.gems,
    required this.villageLevel,
    required this.shieldCount,
    required this.totalStars,
    required this.pigBankCoins,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] ?? '',
    email: j['email'] ?? '',
    displayName: j['displayName'] ?? 'Player',
    avatarUrl: j['avatarUrl'],
    coins: j['coins'] ?? 0,
    spins: j['spins'] ?? 50,
    gems: j['gems'] ?? 0,
    villageLevel: j['villageLevel'] ?? 1,
    shieldCount: j['shieldCount'] ?? 0,
    totalStars: j['totalStars'] ?? 0,
    pigBankCoins: j['pigBankCoins'] ?? 0,
  );
}
