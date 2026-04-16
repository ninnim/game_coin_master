import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/glass_button.dart';
import '../../core/models/attack_model.dart';

class AttackPickerOverlay extends StatelessWidget {
  final List<PlayerTargetModel> targets;
  final Function(PlayerTargetModel) onAttack;
  final VoidCallback onCancel;

  const AttackPickerOverlay({
    super.key,
    required this.targets,
    required this.onAttack,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        borderColor: AppColors.crimson.withOpacity(0.6),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚔️ Choose Target', style: AppTextStyles.title),
            const SizedBox(height: 4),
            const Text(
              'Who will you attack?',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            if (targets.isEmpty)
              const Text(
                'No targets available.',
                style: AppTextStyles.caption,
              )
            else
              ...targets.take(5).map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surface,
                        child: Text(
                          t.displayName.isNotEmpty
                              ? t.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.displayName, style: AppTextStyles.body),
                            Text(
                              'Village ${t.villageLevel}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      GlassButton(
                        label: 'Attack',
                        color: AppColors.crimson,
                        onTap: () => onAttack(t),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            GlassButton(
              label: 'Cancel',
              isPrimary: false,
              onTap: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}
