import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/village_model.dart';

final villagesProvider = FutureProvider.autoDispose<List<VillageModel>>(
  (ref) async {
    final data = await ApiClient.get<List<dynamic>>(ApiEndpoints.villages);
    return data
        .map((v) => VillageModel.fromJson(v as Map<String, dynamic>))
        .toList();
  },
);

final currentVillageProvider =
    FutureProvider.autoDispose<VillageModel>((ref) async {
      final data = await ApiClient.get<Map<String, dynamic>>(
        ApiEndpoints.currentVillage,
      );
      return VillageModel.fromJson(data);
    });

class UpgradeBuildingNotifier extends StateNotifier<AsyncValue<void>> {
  UpgradeBuildingNotifier() : super(const AsyncValue.data(null));

  Future<bool> upgrade(String buildingId) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.post<dynamic>(
        ApiEndpoints.upgradeBuilding(buildingId),
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final upgradeBuildingProvider =
    StateNotifierProvider<UpgradeBuildingNotifier, AsyncValue<void>>(
      (ref) => UpgradeBuildingNotifier(),
    );
