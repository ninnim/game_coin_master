import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/achievement_provider.dart';
import '../../../core/models/achievement_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/toast_notification.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _categories = ['all', 'spin', 'attack', 'raid', 'village', 'social'];
  static const _categoryLabels = ['All', 'Spin', 'Attack', 'Raid', 'Village', 'Social'];
  static const _categoryEmojis = ['⭐', '🎰', '⚔️', '⛏️', '🏰', '👥'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '🏆 Achievements',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/game'),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.gold,
          tabs: List.generate(
            _categories.length,
            (i) => Tab(
              text: '${_categoryEmojis[i]} ${_categoryLabels[i]}',
            ),
          ),
        ),
      ),
      body: achievementsAsync.when(
        loading: () => const SkeletonList(itemCount: 6, itemHeight: 100),
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
              const Text(
                'Failed to load achievements',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(achievementsProvider),
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
        data: (achievements) {
          if (achievements.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.emoji_events,
              title: 'No Achievements Yet',
              message: 'Play the game to unlock achievements and earn rewards!',
            );
          }

          return TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final filtered = category == 'all'
                  ? achievements
                  : achievements
                      .where((a) => a.category.toLowerCase() == category)
                      .toList();

              if (filtered.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.emoji_events_outlined,
                  title: 'No ${category.capitalize()} Achievements',
                  message:
                      'Keep playing to unlock ${category} achievements!',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final ach = filtered[index];
                  return _AchievementTile(
                    achievement: ach,
                    onClaim: ach.isUnlocked && !ach.isClaimed
                        ? () async {
                            final success = await ref
                                .read(claimAchievementProvider.notifier)
                                .claim(ach.id);
                            if (context.mounted) {
                              if (success) {
                                showGameToast(
                                  context,
                                  'Reward claimed: ${ach.title}!',
                                  isSuccess: true,
                                );
                                ref.invalidate(achievementsProvider);
                              } else {
                                showGameToast(
                                  context,
                                  'Failed to claim reward',
                                  isError: true,
                                );
                              }
                            }
                          }
                        : null,
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class _AchievementTile extends StatelessWidget {
  final AchievementModel achievement;
  final VoidCallback? onClaim;

  const _AchievementTile({required this.achievement, this.onClaim});

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'spin': return '🎰';
      case 'attack': return '⚔️';
      case 'raid': return '⛏️';
      case 'village': return '🏰';
      case 'social': return '👥';
      default: return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = achievement.progress;
    Color borderColor;
    if (achievement.isClaimed) {
      borderColor = AppColors.emerald;
    } else if (achievement.isUnlocked) {
      borderColor = AppColors.gold;
    } else {
      borderColor = AppColors.borderGlow;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderColor: borderColor,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: achievement.isClaimed
                    ? AppColors.emerald.withOpacity(0.2)
                    : achievement.isUnlocked
                        ? AppColors.gold.withOpacity(0.2)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  achievement.isClaimed
                      ? '✅'
                      : _categoryEmoji(achievement.category),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.title, style: AppTextStyles.subtitle),
                  Text(
                    achievement.description,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achievement.isClaimed
                          ? AppColors.emerald
                          : achievement.isUnlocked
                              ? AppColors.gold
                              : AppColors.purpleLight,
                    ),
                    minHeight: 5,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${achievement.currentValue}/${achievement.targetValue}',
                        style: AppTextStyles.caption,
                      ),
                      // Rewards preview
                      Row(
                        children: [
                          if (achievement.rewardCoins > 0)
                            _RewardChip(
                              '🪙 ${NumberFormat("#,###").format(achievement.rewardCoins)}',
                              AppColors.gold,
                            ),
                          if (achievement.rewardSpins > 0)
                            _RewardChip(
                              '⚡ ${achievement.rewardSpins}',
                              AppColors.cyan,
                            ),
                          if (achievement.rewardGems > 0)
                            _RewardChip(
                              '💎 ${achievement.rewardGems}',
                              AppColors.purpleLight,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Claim button
            if (onClaim != null) ...[
              const SizedBox(width: 8),
              GlassButton(
                label: 'Claim',
                color: AppColors.gold,
                onTap: onClaim,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RewardChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
