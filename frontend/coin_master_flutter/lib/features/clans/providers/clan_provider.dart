import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/clan_model.dart';

final clansProvider = FutureProvider.autoDispose<List<ClanModel>>(
  (ref) async {
    final data = await ApiClient.get<List<dynamic>>(ApiEndpoints.clans);
    return data
        .map((c) => ClanModel.fromJson(c as Map<String, dynamic>))
        .toList();
  },
);

final myClanProvider = FutureProvider.autoDispose<ClanModel?>((ref) async {
  try {
    final data = await ApiClient.get<Map<String, dynamic>>(
      ApiEndpoints.myClan,
    );
    return ClanModel.fromJson(data);
  } catch (_) {
    return null;
  }
});

class ClanActionNotifier extends StateNotifier<AsyncValue<void>> {
  ClanActionNotifier() : super(const AsyncValue.data(null));

  Future<bool> joinClan(String clanId) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.post<dynamic>(ApiEndpoints.joinClan(clanId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createClan(String name, String? description) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.post<dynamic>(
        ApiEndpoints.clans,
        data: {'name': name, 'description': description},
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final clanActionProvider =
    StateNotifierProvider<ClanActionNotifier, AsyncValue<void>>(
      (ref) => ClanActionNotifier(),
    );
