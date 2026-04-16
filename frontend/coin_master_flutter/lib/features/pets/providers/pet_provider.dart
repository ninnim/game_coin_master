import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/pet_model.dart';

final petsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final data = await ApiClient.get<List<dynamic>>(ApiEndpoints.pets);
  return data
      .map((p) => PetModel.fromJson(p as Map<String, dynamic>))
      .toList();
});

class PetActionNotifier extends StateNotifier<AsyncValue<void>> {
  PetActionNotifier() : super(const AsyncValue.data(null));

  Future<bool> activatePet(String petId) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.post<dynamic>(ApiEndpoints.activatePet(petId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> feedPet(String petId) async {
    state = const AsyncValue.loading();
    try {
      await ApiClient.post<dynamic>(ApiEndpoints.feedPet(petId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final petActionProvider =
    StateNotifierProvider<PetActionNotifier, AsyncValue<void>>(
      (ref) => PetActionNotifier(),
    );
