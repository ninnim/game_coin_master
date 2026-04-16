import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/village_provider.dart';
import '../../../core/models/village_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class VillageMapScreen extends ConsumerWidget {
  const VillageMapScreen({super.key});

  static const List<String> _villageEmojis = [
    '🏠', '🏰', '🗼', '⛩️', '🕌', '🏯', '🗽', '🏛️', '🛕', '🌆',
  ];

  static const List<String> _villageThemes = [
    'Grasslands', 'Medieval', 'Tower Kingdom', 'Eastern Shrine', 'Desert Oasis',
    'Feudal Japan', 'New World', 'Ancient Greece', 'Sacred Temple', 'Neon City',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villagesAsync = ref.watch(villagesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '🗺️ Village Map',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
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
      body: villagesAsync.when(
        loading: () => const SkeletonList(itemCount: 8, itemHeight: 100),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.crimson, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load villages', style: AppTextStyles.body),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(villagesProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                child: const Text('Retry', style: TextStyle(color: AppColors.background)),
              ),
            ],
          ),
        ),
        data: (villages) {
          if (villages.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.map,
              title: 'No Villages Found',
              message: 'Start your journey to unlock villages!',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: villages.length,
            itemBuilder: (context, index) {
              final village = villages[index];
              return _VillageCard(
                village: village,
                emoji: _villageEmojis[index % _villageEmojis.length],
                themeName: index < _villageThemes.length ? _villageThemes[index] : village.theme,
                onTap: () => context.push('/village', extra: village),
              );
            },
          );
        },
      ),
    );
  }
}

class _VillageCard extends StatelessWidget {
  final VillageModel village;
  final String emoji;
  final String themeName;
  final VoidCallback onTap;

  const _VillageCard({
    required this.village,
    required this.emoji,
    required this.themeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color skyColor;
    try {
      skyColor = Color(int.parse(village.skyColor.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      skyColor = const Color(0xFF1565C0);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        borderColor: village.isActive
            ? AppColors.gold
            : village.isCompleted
                ? AppColors.emerald
                : AppColors.borderGlow,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // Sky preview
            Container(
              width: 80,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [skyColor.withOpacity(0.8), AppColors.surface],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Village ${village.orderNum}',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(width: 8),
                        if (village.isActive)
                          _badge('CURRENT', AppColors.gold)
                        else if (village.isCompleted)
                          _badge('DONE', AppColors.emerald)
                        else if (village.isBoom)
                          _badge('BOOM!', AppColors.crimson),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      village.name,
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      themeName,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                village.isCompleted ? Icons.check_circle : Icons.lock,
                color: village.isCompleted ? AppColors.emerald : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
