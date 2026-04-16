import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/card_model.dart';

final cardSetsProvider = FutureProvider.autoDispose<List<CardSetModel>>(
  (ref) async {
    final data = await ApiClient.get<List<dynamic>>(ApiEndpoints.cards);
    return data
        .map((s) => CardSetModel.fromJson(s as Map<String, dynamic>))
        .toList();
  },
);

final chestsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ApiClient.get<List<dynamic>>(ApiEndpoints.chests);
});

class OpenChestNotifier extends StateNotifier<AsyncValue<List<CardModel>>> {
  OpenChestNotifier() : super(const AsyncValue.data([]));

  Future<List<CardModel>> openChest(String chestType) async {
    state = const AsyncValue.loading();
    try {
      final data = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.openChest,
        data: {'chestType': chestType},
      );
      final cards = (data['cards'] as List? ?? [])
          .map((c) => CardModel.fromJson(c as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(cards);
      return cards;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  void reset() => state = const AsyncValue.data([]);
}

final openChestProvider =
    StateNotifierProvider<OpenChestNotifier, AsyncValue<List<CardModel>>>(
      (ref) => OpenChestNotifier(),
    );
