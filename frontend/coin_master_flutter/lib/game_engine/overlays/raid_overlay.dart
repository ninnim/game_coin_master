import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/glass_button.dart';
import '../../core/models/attack_model.dart';

class RaidOverlay extends StatefulWidget {
  final List<PlayerTargetModel> targets;
  final Function(PlayerTargetModel) onRaid;
  final VoidCallback onCancel;

  const RaidOverlay({
    super.key,
    required this.targets,
    required this.onRaid,
    required this.onCancel,
  });

  @override
  State<RaidOverlay> createState() => _RaidOverlayState();
}

class _RaidOverlayState extends State<RaidOverlay> {
  PlayerTargetModel? _selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        borderColor: const Color(0x808D6E63),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⛏️ Choose Raid Target', style: AppTextStyles.title),
            const SizedBox(height: 4),
            const Text(
              'Dig up coins from another village!',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            if (widget.targets.isEmpty)
              const Text('No targets available.', style: AppTextStyles.caption)
            else
              ...widget.targets.take(5).map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selected?.userId == t.userId
                            ? const Color(0x408D6E63)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selected?.userId == t.userId
                              ? const Color(0xFF8D6E63)
                              : AppColors.borderGlow,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0x308D6E63),
                            child: Text(
                              t.displayName.isNotEmpty
                                  ? t.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.displayName,
                                  style: AppTextStyles.body,
                                ),
                                Text(
                                  '🐷 ${NumberFormat("#,###").format(t.pigBankCoins)} in bank',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          if (_selected?.userId == t.userId)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF8D6E63),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Cancel',
                    isPrimary: false,
                    onTap: widget.onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    label: '⛏️ Raid!',
                    color: const Color(0xFF8D6E63),
                    onTap: _selected != null
                        ? () => widget.onRaid(_selected!)
                        : null,
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
