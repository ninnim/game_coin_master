import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class CoinDisplay extends StatelessWidget {
  final int amount;
  final double fontSize;

  const CoinDisplay({super.key, required this.amount, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '\$',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.background,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          NumberFormat('#,###').format(amount),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}
