import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/glass_button.dart';

class SpinResultOverlay extends StatelessWidget {
  final String resultType;
  final int coinsEarned;
  final int spinsEarned;
  final String? specialAction;
  final VoidCallback onDismiss;

  const SpinResultOverlay({
    super.key,
    required this.resultType,
    required this.coinsEarned,
    required this.spinsEarned,
    this.specialAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isJackpot = resultType == 'jackpot';

    return Center(
      child: GlassCard(
        borderColor: isJackpot ? AppColors.gold : AppColors.borderGlow,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isJackpot ? '🌟 JACKPOT! 🌟' : _resultEmoji(),
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              _resultTitle(),
              style: isJackpot
                  ? AppTextStyles.headline.copyWith(color: AppColors.gold)
                  : AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            if (coinsEarned > 0) ...[
              const SizedBox(height: 8),
              Text(
                '+${NumberFormat("#,###").format(coinsEarned)} coins',
                style: AppTextStyles.gold,
              ),
            ],
            if (spinsEarned > 0) ...[
              const SizedBox(height: 4),
              Text(
                '+$spinsEarned spins',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 20),
            GlassButton(label: 'Continue', onTap: onDismiss),
          ],
        ),
      ),
    );
  }

  String _resultEmoji() {
    switch (specialAction) {
      case 'attack': return '⚔️';
      case 'raid': return '⛏️';
      case 'shield': return '🛡️';
      case 'energy': return '⚡';
      default: return coinsEarned > 0 ? '🪙' : '😢';
    }
  }

  String _resultTitle() {
    switch (specialAction) {
      case 'attack': return 'Attack Ready!';
      case 'raid': return 'Raid Ready!';
      case 'shield': return 'Shield Activated!';
      case 'energy': return 'Energy Boost!';
      default: return coinsEarned > 0 ? 'Coins Earned!' : 'Better Luck Next Time';
    }
  }
}
