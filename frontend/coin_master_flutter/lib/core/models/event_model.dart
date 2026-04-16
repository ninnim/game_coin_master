class EventModel {
  final String id;
  final String type;
  final String title;
  final String? description;
  final String? bannerImage;
  final int userProgress;
  final bool isClaimed;

  const EventModel({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.bannerImage,
    required this.userProgress,
    required this.isClaimed,
  });

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
    id: j['id'] ?? '',
    type: j['type'] ?? 'generic',
    title: j['title'] ?? 'Event',
    description: j['description'],
    bannerImage: j['bannerImage'],
    userProgress: j['userProgress'] ?? 0,
    isClaimed: j['isClaimed'] ?? false,
  );
}
