class AchievementModel {
  final String id;
  final String key;
  final String title;
  final String description;
  final String category;
  final int targetValue;
  final int currentValue;
  final int rewardCoins;
  final int rewardSpins;
  final int rewardGems;
  final bool isUnlocked;
  final bool isClaimed;

  const AchievementModel({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.rewardCoins,
    required this.rewardSpins,
    required this.rewardGems,
    required this.isUnlocked,
    required this.isClaimed,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> j) =>
      AchievementModel(
        id: j['id'] ?? '',
        key: j['key'] ?? '',
        title: j['title'] ?? 'Achievement',
        description: j['description'] ?? '',
        category: j['category'] ?? 'general',
        targetValue: j['targetValue'] ?? 1,
        currentValue: j['currentValue'] ?? 0,
        rewardCoins: j['rewardCoins'] ?? 0,
        rewardSpins: j['rewardSpins'] ?? 0,
        rewardGems: j['rewardGems'] ?? 0,
        isUnlocked: j['isUnlocked'] ?? false,
        isClaimed: j['isClaimed'] ?? false,
      );

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0;
}
