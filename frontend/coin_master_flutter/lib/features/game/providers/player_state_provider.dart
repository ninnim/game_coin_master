import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/player_state_model.dart';

final playerStateProvider =
    FutureProvider.autoDispose<PlayerStateModel>((ref) async {
      final data = await ApiClient.get<Map<String, dynamic>>(
        ApiEndpoints.playerState,
      );
      return PlayerStateModel.fromJson(data);
    });

typedef GameStateRecord =
    ({
      int coins,
      int spins,
      int shields,
      int pendingAttacks,
      int pendingRaids,
    });

class GameStateNotifier extends StateNotifier<GameStateRecord> {
  GameStateNotifier()
    : super((
        coins: 0,
        spins: 50,
        shields: 0,
        pendingAttacks: 0,
        pendingRaids: 0,
      ));

  void updateFromPlayerState(PlayerStateModel ps) {
    state = (
      coins: ps.user.coins,
      spins: ps.user.spins,
      shields: ps.user.shieldCount,
      pendingAttacks: ps.pendingAttacks,
      pendingRaids: ps.pendingRaids,
    );
  }

  void applySpinResult(int newCoins, int newSpins) {
    state = (
      coins: newCoins,
      spins: newSpins,
      shields: state.shields,
      pendingAttacks: state.pendingAttacks,
      pendingRaids: state.pendingRaids,
    );
  }

  void addShield() {
    if (state.shields < 3) {
      state = (
        coins: state.coins,
        spins: state.spins,
        shields: state.shields + 1,
        pendingAttacks: state.pendingAttacks,
        pendingRaids: state.pendingRaids,
      );
    }
  }

  void clearPendingAction() {
    state = (
      coins: state.coins,
      spins: state.spins,
      shields: state.shields,
      pendingAttacks: 0,
      pendingRaids: 0,
    );
  }

  void setPendingAttack() {
    state = (
      coins: state.coins,
      spins: state.spins,
      shields: state.shields,
      pendingAttacks: state.pendingAttacks + 1,
      pendingRaids: state.pendingRaids,
    );
  }

  void setPendingRaid() {
    state = (
      coins: state.coins,
      spins: state.spins,
      shields: state.shields,
      pendingAttacks: state.pendingAttacks,
      pendingRaids: state.pendingRaids + 1,
    );
  }
}

final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameStateRecord>(
      (ref) => GameStateNotifier(),
    );
