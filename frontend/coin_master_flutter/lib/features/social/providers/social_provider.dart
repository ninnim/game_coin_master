import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class FriendModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int villageLevel;
  final bool isOnline;
  final bool canGiftSpin;
  final String status; // 'friend', 'pending', 'incoming'

  const FriendModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.villageLevel,
    required this.isOnline,
    required this.canGiftSpin,
    required this.status,
  });

  factory FriendModel.fromJson(Map<String, dynamic> j) => FriendModel(
    userId: j['userId'] ?? '',
    displayName: j['displayName'] ?? 'Player',
    avatarUrl: j['avatarUrl'],
    villageLevel: j['villageLevel'] ?? 1,
    isOnline: j['isOnline'] ?? false,
    canGiftSpin: j['canGiftSpin'] ?? false,
    status: j['status'] ?? 'friend',
  );
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int value;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.value,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) =>
      LeaderboardEntry(
        rank: j['rank'] ?? 0,
        userId: j['userId'] ?? '',
        displayName: j['displayName'] ?? 'Player',
        avatarUrl: j['avatarUrl'],
        value: j['value'] ?? 0,
        isCurrentUser: j['isCurrentUser'] ?? false,
      );
}

final friendsProvider = FutureProvider.autoDispose<List<FriendModel>>(
  (ref) async {
    final data = await ApiClient.get<List<dynamic>>(ApiEndpoints.friends);
    return data
        .map((f) => FriendModel.fromJson(f as Map<String, dynamic>))
        .toList();
  },
);

final leaderboardProvider =
    FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>(
      (ref, type) async {
        final data = await ApiClient.get<List<dynamic>>(
          ApiEndpoints.leaderboard,
          params: {'type': type},
        );
        return data
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );

class SocialActionNotifier extends StateNotifier<AsyncValue<void>> {
  SocialActionNotifier() : super(const AsyncValue.data(null));

  Future<bool> giftSpin(String userId) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.post<dynamic>(ApiEndpoints.giftSpin(userId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendFriendRequest(String userId) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.post<dynamic>(ApiEndpoints.friendRequest(userId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> respondToRequest(String userId, bool accept) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.post<dynamic>(
        ApiEndpoints.respondFriend(userId),
        data: {'accept': accept},
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final socialActionProvider =
    StateNotifierProvider<SocialActionNotifier, AsyncValue<void>>(
      (ref) => SocialActionNotifier(),
    );
