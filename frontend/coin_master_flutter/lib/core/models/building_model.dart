class BuildingModel {
  final String id;
  final String name;
  final String description;
  final int maxLevel;
  final String imageBase;

  const BuildingModel({
    required this.id,
    required this.name,
    required this.description,
    required this.maxLevel,
    required this.imageBase,
  });

  factory BuildingModel.fromJson(Map<String, dynamic> j) => BuildingModel(
    id: j['id'] ?? '',
    name: j['name'] ?? 'Building',
    description: j['description'] ?? '',
    maxLevel: j['maxLevel'] ?? 5,
    imageBase: j['imageBase'] ?? '',
  );
}
