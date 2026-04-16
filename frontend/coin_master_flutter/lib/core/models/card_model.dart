class CardModel {
  final String id;
  final String name;
  final String rarity;
  final String? description;
  final String? imageUrl;
  final int quantity;
  final bool isOwned;

  const CardModel({
    required this.id,
    required this.name,
    required this.rarity,
    this.description,
    this.imageUrl,
    required this.quantity,
    required this.isOwned,
  });

  factory CardModel.fromJson(Map<String, dynamic> j) => CardModel(
    id: j['id'] ?? '',
    name: j['name'] ?? 'Card',
    rarity: j['rarity'] ?? 'common',
    description: j['description'],
    imageUrl: j['imageUrl'],
    quantity: j['quantity'] ?? 0,
    isOwned: j['isOwned'] ?? false,
  );
}

class CardSetModel {
  final String id;
  final String name;
  final String theme;
  final List<CardModel> cards;
  final int ownedCount;
  final int totalCount;
  final bool isComplete;

  const CardSetModel({
    required this.id,
    required this.name,
    required this.theme,
    required this.cards,
    required this.ownedCount,
    required this.totalCount,
    required this.isComplete,
  });

  factory CardSetModel.fromJson(Map<String, dynamic> j) => CardSetModel(
    id: j['id'] ?? '',
    name: j['name'] ?? 'Card Set',
    theme: j['theme'] ?? 'default',
    cards:
        (j['cards'] as List? ?? [])
            .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
            .toList(),
    ownedCount: j['ownedCount'] ?? 0,
    totalCount: j['totalCount'] ?? 12,
    isComplete: j['isComplete'] ?? false,
  );
}
