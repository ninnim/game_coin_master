class ClanModel {
  final String id;
  final String name;
  final String leaderName;
  final String? description;
  final int memberCount;
  final int totalPoints;
  final bool isPublic;

  const ClanModel({
    required this.id,
    required this.name,
    required this.leaderName,
    this.description,
    required this.memberCount,
    required this.totalPoints,
    required this.isPublic,
  });

  factory ClanModel.fromJson(Map<String, dynamic> j) => ClanModel(
    id: j['id'] ?? '',
    name: j['name'] ?? 'Clan',
    leaderName: j['leaderName'] ?? 'Unknown',
    description: j['description'],
    memberCount: j['memberCount'] ?? 1,
    totalPoints: j['totalPoints'] ?? 0,
    isPublic: j['isPublic'] ?? true,
  );
}

class ClanMemberModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final int contribution;

  const ClanMemberModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.contribution,
  });

  factory ClanMemberModel.fromJson(Map<String, dynamic> j) => ClanMemberModel(
    userId: j['userId'] ?? '',
    displayName: j['displayName'] ?? 'Member',
    avatarUrl: j['avatarUrl'],
    role: j['role'] ?? 'member',
    contribution: j['contribution'] ?? 0,
  );
}
