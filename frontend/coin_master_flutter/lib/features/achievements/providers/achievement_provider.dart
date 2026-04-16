import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/achievement_model.dart';

final achievementsProvider =
    FutureProvider.autoDispose<List<AchievementModel>>((ref) async {
      final data = await ApiClient.get<List<dynamic>>(
        ApiEndpoints.achievements,
      );
      return data
          .map((a) => AchievementModel.fromJson(a as Map<String, dynamic>))
          .toList();
    });

class ClaimAchievementNotifier extends StateNotifier<AsyncValue<void>> {
  ClaimAchievementNotifier() : super(const AsyncValue.data(null));

  Future<bool> claim(String achievementId) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.post<dynamic>(
        ApiEndpoints.claimAchievement(achievementId),
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final claimAchievementProvider =
    StateNotifierProvider<ClaimAchievementNotifier, AsyncValue<void>>(
      (ref) => ClaimAchievementNotifier(),
    );
