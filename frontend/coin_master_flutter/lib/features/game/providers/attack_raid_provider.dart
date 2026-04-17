import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/attack_model.dart';

// ── Fetch 5 random public targets ──
final targetsProvider =
    FutureProvider.autoDispose<List<PlayerTargetModel>>((ref) async {
  final data =
      await ApiClient.get<List<dynamic>>(ApiEndpoints.playerTargets);
  return data
      .map((t) => PlayerTargetModel.fromJson(t as Map<String, dynamic>))
      .toList();
});

// ── Execute attack ──
class AttackNotifier extends StateNotifier<AsyncValue<AttackResultModel?>> {
  AttackNotifier() : super(const AsyncValue.data(null));

  Future<AttackResultModel?> attack(String targetUserId) async {
    state = const AsyncValue.loading();
    try {
      final data = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.attack,
        data: {'targetUserId': targetUserId},
      );
      final result = AttackResultModel.fromJson(data);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final attackProvider =
    StateNotifierProvider<AttackNotifier, AsyncValue<AttackResultModel?>>(
  (ref) => AttackNotifier(),
);

// ── Execute raid ──
class RaidNotifier extends StateNotifier<AsyncValue<RaidFullResultModel?>> {
  RaidNotifier() : super(const AsyncValue.data(null));

  Future<RaidFullResultModel?> raid(
      String victimId, List<int> holePositions) async {
    state = const AsyncValue.loading();
    try {
      final data = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.raid,
        data: {'victimId': victimId, 'holePositions': holePositions},
      );
      final result = RaidFullResultModel.fromJson(data);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final raidProvider =
    StateNotifierProvider<RaidNotifier, AsyncValue<RaidFullResultModel?>>(
  (ref) => RaidNotifier(),
);

// ── Raid result with hole breakdown ──
class HoleResult {
  final int position;
  final int coinsFound;
  const HoleResult({required this.position, required this.coinsFound});

  factory HoleResult.fromJson(Map<String, dynamic> j) => HoleResult(
        position: j['position'] ?? 0,
        coinsFound: j['coinsFound'] ?? 0,
      );
}

class RaidFullResultModel {
  final int totalCoinsStolen;
  final List<HoleResult> holeResults;
  final bool petExtraHole;
  final String victimName;

  const RaidFullResultModel({
    required this.totalCoinsStolen,
    required this.holeResults,
    required this.petExtraHole,
    required this.victimName,
  });

  factory RaidFullResultModel.fromJson(Map<String, dynamic> j) =>
      RaidFullResultModel(
        totalCoinsStolen: j['totalCoinsStolen'] ?? 0,
        holeResults: (j['holeResults'] as List? ?? [])
            .map((h) => HoleResult.fromJson(h as Map<String, dynamic>))
            .toList(),
        petExtraHole: j['petExtraHole'] ?? false,
        victimName: j['victimName'] ?? 'Player',
      );
}
