import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    return ApiClient.get<Map<String, dynamic>>(ApiEndpoints.profile);
  },
);

class UpdateProfileNotifier extends StateNotifier<AsyncValue<void>> {
  UpdateProfileNotifier() : super(const AsyncValue.data(null));

  Future<bool> updateDisplayName(String displayName) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.put<dynamic>(
        ApiEndpoints.profile,
        data: {'displayName': displayName},
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final updateProfileProvider =
    StateNotifierProvider<UpdateProfileNotifier, AsyncValue<void>>(
      (ref) => UpdateProfileNotifier(),
    );
