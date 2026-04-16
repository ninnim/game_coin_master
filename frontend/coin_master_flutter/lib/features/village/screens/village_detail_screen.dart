import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/village_provider.dart';
import '../../../core/models/village_model.dart';
import '../../../features/game/providers/player_state_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/toast_notification.dart';

class VillageDetailScreen extends ConsumerWidget {
  const VillageDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          playerState.valueOrNull?.currentVillage.name ?? 'Your Village',
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/game'),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderGlow),
        ),
      ),
      body: playerState.when(
        loading: () => const SkeletonList(itemCount: 6, itemHeight: 90),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.crimson,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text('Failed to load village', style: AppTextStyles.body),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(playerStateProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.background),
                ),
              ),
            ],
          ),
        ),
        data: (ps) {
          final village = ps.currentVillage;
          final buildings = ps.buildings;
          Color skyColor;
          try {
            skyColor = Color(
              int.parse(
                village.skyColor.replaceFirst('#', 'FF'),
                radix: 16,
              ),
            );
          } catch (_) {
            skyColor = const Color(0xFF1565C0);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Village header
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [skyColor.withOpacity(0.7), AppColors.background],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          village.name,
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        Text(
                          'Village ${village.orderNum} — ${village.theme}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                '${buildings.where((b) => b.upgradeLevel > 0 && !b.isDestroyed).length}/${buildings.length}',
                                style: AppTextStyles.gold,
                              ),
                              const Text(
                                'Built',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                '${buildings.where((b) => b.isDestroyed).length}',
                                style: const TextStyle(
                                  color: AppColors.crimson,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Text(
                                'Destroyed',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                '${ps.user.shieldCount}',
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Text(
                                'Shields',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Buildings list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buildings',
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: 12),
                      if (buildings.isEmpty)
                        const Center(
                          child: Text(
                            'No buildings in this village yet.',
                            style: AppTextStyles.caption,
                          ),
                        )
                      else
                        ...buildings.map(
                          (b) => _BuildingTile(
                            building: b,
                            coins: ps.user.coins,
                            onUpgrade: () async {
                              final success = await ref
                                  .read(upgradeBuildingProvider.notifier)
                                  .upgrade(b.buildingId);
                              if (context.mounted) {
                                if (success) {
                                  showGameToast(
                                    context,
                                    '${b.buildingName} upgraded!',
                                    isSuccess: true,
                                  );
                                  ref.invalidate(playerStateProvider);
                                } else {
                                  showGameToast(
                                    context,
                                    'Upgrade failed!',
                                    isError: true,
                                  );
                                }
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BuildingTile extends StatelessWidget {
  final UserBuildingModel building;
  final int coins;
  final VoidCallback onUpgrade;

  const _BuildingTile({
    required this.building,
    required this.coins,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final emojis = ['🏠', '🏰', '⛺', '🏗️', '🏛️'];
    final emoji = emojis[building.buildingName.length % emojis.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderColor: building.isDestroyed ? AppColors.crimson : AppColors.borderGlow,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: building.isDestroyed
                    ? AppColors.crimson.withOpacity(0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  building.isDestroyed ? '💥' : emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(building.buildingName, style: AppTextStyles.subtitle),
                  Text(
                    building.isDestroyed ? 'DESTROYED' : 'Level ${building.upgradeLevel}',
                    style: TextStyle(
                      color: building.isDestroyed ? AppColors.crimson : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!building.isDestroyed)
              GlassButton(
                label: '⬆️ ${building.nextUpgradeCost}',
                onTap: building.canAfford ? onUpgrade : null,
                color: building.canAfford ? AppColors.gold : AppColors.textSecondary,
                isPrimary: building.canAfford,
              ),
          ],
        ),
      ),
    );
  }
}
