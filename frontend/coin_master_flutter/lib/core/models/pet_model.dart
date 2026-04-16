class PetModel {
  final String petId;
  final String name;
  final String abilityType;
  final String abilityDescription;
  final String? imageUrl;
  final int level;
  final int xp;
  final int maxLevel;
  final bool isActive;
  final double abilityStrength;

  const PetModel({
    required this.petId,
    required this.name,
    required this.abilityType,
    required this.abilityDescription,
    this.imageUrl,
    required this.level,
    required this.xp,
    required this.maxLevel,
    required this.isActive,
    required this.abilityStrength,
  });

  factory PetModel.fromJson(Map<String, dynamic> j) => PetModel(
    petId: j['petId'] ?? '',
    name: j['name'] ?? 'Pet',
    abilityType: j['abilityType'] ?? 'none',
    abilityDescription: j['abilityDescription'] ?? '',
    imageUrl: j['imageUrl'],
    level: j['level'] ?? 1,
    xp: j['xp'] ?? 0,
    maxLevel: j['maxLevel'] ?? 20,
    isActive: j['isActive'] ?? false,
    abilityStrength: (j['abilityStrength'] as num? ?? 0).toDouble(),
  );
}
