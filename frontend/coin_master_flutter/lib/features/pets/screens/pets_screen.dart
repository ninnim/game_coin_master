import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/pet_provider.dart';
import '../../../core/models/pet_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/toast_notification.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  String _petEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('foxy') || lower.contains('fox')) return '🦊';
    if (lower.contains('tiger')) return '🐯';
    if (lower.contains('rhino')) return '🦏';
    return '🐾';
  }

  Color _petColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('foxy') || lower.contains('fox')) {
      return const Color(0xFFFF6D00);
    }
    if (lower.contains('tiger')) return const Color(0xFFFF8F00);
    if (lower.contains('rhino')) return const Color(0xFF78909C);
    return AppColors.gold;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '🐾 Pets',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderGlow),
        ),
      ),
      body: petsAsync.when(
        loading: () => const SkeletonList(itemCount: 3, itemHeight: 160),
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
              const Text('Failed to load pets', style: AppTextStyles.body),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(petsProvider),
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
        data: (pets) {
          if (pets.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.pets,
              title: 'No Pets Yet',
              message: 'Complete achievements to unlock pets!',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _PetCard(
                pet: pet,
                emoji: _petEmoji(pet.name),
                petColor: _petColor(pet.name),
                onActivate: () async {
                  final success = await ref
                      .read(petActionProvider.notifier)
                      .activatePet(pet.petId);
                  if (context.mounted) {
                    if (success) {
                      showGameToast(
                        context,
                        '${pet.name} is now active!',
                        isSuccess: true,
                      );
                      ref.invalidate(petsProvider);
                    } else {
                      showGameToast(
                        context,
                        'Failed to activate pet',
                        isError: true,
                      );
                    }
                  }
                },
                onFeed: () async {
                  final success = await ref
                      .read(petActionProvider.notifier)
                      .feedPet(pet.petId);
                  if (context.mounted) {
                    if (success) {
                      showGameToast(
                        context,
                        '${pet.name} was fed! +XP',
                        isSuccess: true,
                      );
                      ref.invalidate(petsProvider);
                    } else {
                      showGameToast(
                        context,
                        'Failed to feed pet',
                        isError: true,
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  final String emoji;
  final Color petColor;
  final VoidCallback onActivate;
  final VoidCallback onFeed;

  const _PetCard({
    required this.pet,
    required this.emoji,
    required this.petColor,
    required this.onActivate,
    required this.onFeed,
  });

  @override
  Widget build(BuildContext context) {
    final xpFraction =
        pet.maxLevel > 0 ? (pet.xp % 100) / 100.0 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderColor: pet.isActive ? petColor : AppColors.borderGlow,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Pet icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: petColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: petColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 38),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(pet.name, style: AppTextStyles.subtitle),
                          const SizedBox(width: 8),
                          if (pet.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.emerald,
                                ),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: AppColors.emerald,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Level ${pet.level} / ${pet.maxLevel}',
                        style: TextStyle(
                          color: petColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pet.abilityDescription,
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // XP bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'XP: ${pet.xp % 100}/100',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      pet.abilityType.toUpperCase(),
                      style: TextStyle(
                        color: petColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: xpFraction,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(petColor),
                  minHeight: 6,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: pet.isActive ? '✅ Active' : '⚡ Activate',
                    color: petColor,
                    isPrimary: !pet.isActive,
                    onTap: pet.isActive ? null : onActivate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    label: '🍖 Feed',
                    color: AppColors.gold,
                    isPrimary: false,
                    onTap: onFeed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
