class VillageModel {
  final String id;
  final String name;
  final String theme;
  final int orderNum;
  final bool isBoom;
  final bool isCompleted;
  final bool isActive;
  final String skyColor;
  final String? description;

  const VillageModel({
    required this.id,
    required this.name,
    required this.theme,
    required this.orderNum,
    required this.isBoom,
    required this.isCompleted,
    required this.isActive,
    required this.skyColor,
    this.description,
  });

  factory VillageModel.fromJson(Map<String, dynamic> j) => VillageModel(
    id: j['id'] ?? '',
    name: j['name'] ?? 'Village',
    theme: j['theme'] ?? 'default',
    orderNum: j['orderNum'] ?? 1,
    isBoom: j['isBoom'] ?? false,
    isCompleted: j['isCompleted'] ?? false,
    isActive: j['isActive'] ?? false,
    skyColor: j['skyColor'] ?? '#1565C0',
    description: j['description'],
  );
}

class UserBuildingModel {
  final String buildingId;
  final String buildingName;
  final String imageBase;
  final double positionX;
  final double positionY;
  final int upgradeLevel;
  final bool isDestroyed;
  final int nextUpgradeCost;
  final bool canAfford;

  const UserBuildingModel({
    required this.buildingId,
    required this.buildingName,
    required this.imageBase,
    required this.positionX,
    required this.positionY,
    required this.upgradeLevel,
    required this.isDestroyed,
    required this.nextUpgradeCost,
    required this.canAfford,
  });

  factory UserBuildingModel.fromJson(Map<String, dynamic> j) =>
      UserBuildingModel(
        buildingId: j['buildingId'] ?? '',
        buildingName: j['buildingName'] ?? 'Building',
        imageBase: j['imageBase'] ?? '',
        positionX: (j['positionX'] as num? ?? 0).toDouble(),
        positionY: (j['positionY'] as num? ?? 0).toDouble(),
        upgradeLevel: j['upgradeLevel'] ?? 0,
        isDestroyed: j['isDestroyed'] ?? false,
        nextUpgradeCost: j['nextUpgradeCost'] ?? 0,
        canAfford: j['canAfford'] ?? false,
      );
}
