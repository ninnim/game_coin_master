import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/spin_result_model.dart';

class SpinNotifier extends StateNotifier<AsyncValue<SpinResultModel?>> {
  SpinNotifier() : super(const AsyncValue.data(null));

  Future<SpinResultModel?> spin(int betMultiplier) async {
    state = const AsyncValue.loading();
    try {
      final data = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.spin,
        data: {'betMultiplier': betMultiplier},
      );
      final result = SpinResultModel.fromJson(data);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final spinProvider =
    StateNotifierProvider<SpinNotifier, AsyncValue<SpinResultModel?>>(
      (ref) => SpinNotifier(),
    );

final betMultiplierProvider = StateProvider<int>((ref) => 1);
