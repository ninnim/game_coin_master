import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class CoinDisplay extends StatelessWidget {
  final int amount;
  final double fontSize;
  const CoinDisplay({super.key, required this.amount, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFF9A825)]),
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('\$', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)))),
        ),
        const SizedBox(width: 6),
        Text(NumberFormat('#,###').format(amount),
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: AppColors.textWhite,
                shadows: const [Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 2)])),
      ]),
    );
  }
}
