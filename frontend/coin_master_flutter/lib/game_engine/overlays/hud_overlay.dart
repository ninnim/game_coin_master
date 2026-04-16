import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';

class HudOverlay extends StatelessWidget {
  final int coins;
  final int spins;
  final int shields;
  final int villageLevel;

  const HudOverlay({
    super.key,
    required this.coins,
    required this.spins,
    required this.shields,
    required this.villageLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.surface.withOpacity(0.9),
        child: Row(
          children: [
            // Coins
            _HudStat(
              emoji: '🪙',
              value: NumberFormat('#,###').format(coins),
              color: AppColors.gold,
            ),
            const Spacer(),
            // Village
            Text('V$villageLevel', style: AppTextStyles.caption),
            const Spacer(),
            // Shields
            ...List.generate(
              3,
              (i) => Icon(
                Icons.shield,
                size: 16,
                color: i < shields
                    ? AppColors.cyan
                    : AppColors.textSecondary.withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 8),
            // Spins
            _HudStat(
              emoji: '⚡',
              value: '$spins',
              color: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

class _HudStat extends StatelessWidget {
  final String emoji;
  final String value;
  final Color color;

  const _HudStat({
    required this.emoji,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
