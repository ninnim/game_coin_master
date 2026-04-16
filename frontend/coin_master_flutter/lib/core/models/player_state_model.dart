import 'user_model.dart';
import 'village_model.dart';
import 'pet_model.dart';
import 'event_model.dart';
import 'attack_model.dart';

class PlayerStateModel {
  final UserModel user;
  final VillageModel currentVillage;
  final List<UserBuildingModel> buildings;
  final PetModel? activePet;
  final List<PetModel> allPets;
  final int pendingAttacks;
  final int pendingRaids;
  final int unreadNotifications;
  final List<EventModel> activeEvents;
  final List<RecentAttackModel> recentAttacks;

  const PlayerStateModel({
    required this.user,
    required this.currentVillage,
    required this.buildings,
    this.activePet,
    required this.allPets,
    required this.pendingAttacks,
    required this.pendingRaids,
    required this.unreadNotifications,
    required this.activeEvents,
    required this.recentAttacks,
  });

  factory PlayerStateModel.fromJson(Map<String, dynamic> j) =>
      PlayerStateModel(
        user: UserModel.fromJson(
          (j['user'] as Map<String, dynamic>?) ?? {},
        ),
        currentVillage: VillageModel.fromJson(
          (j['currentVillage'] as Map<String, dynamic>?) ?? {},
        ),
        buildings:
            (j['buildings'] as List? ?? [])
                .map(
                  (b) => UserBuildingModel.fromJson(
                    b as Map<String, dynamic>,
                  ),
                )
                .toList(),
        activePet:
            j['activePet'] != null
                ? PetModel.fromJson(j['activePet'] as Map<String, dynamic>)
                : null,
        allPets:
            (j['allPets'] as List? ?? [])
                .map((p) => PetModel.fromJson(p as Map<String, dynamic>))
                .toList(),
        pendingAttacks: j['pendingAttacks'] ?? 0,
        pendingRaids: j['pendingRaids'] ?? 0,
        unreadNotifications: j['unreadNotifications'] ?? 0,
        activeEvents:
            (j['activeEvents'] as List? ?? [])
                .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
                .toList(),
        recentAttacks:
            (j['recentAttacks'] as List? ?? [])
                .map(
                  (a) => RecentAttackModel.fromJson(
                    a as Map<String, dynamic>,
                  ),
                )
                .toList(),
      );
}
