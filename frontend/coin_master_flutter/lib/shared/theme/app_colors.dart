import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A1A);
  static const Color surface = Color(0xFF1A1030);
  static const Color surfaceLight = Color(0xFF241840);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFF176);
  static const Color goldDark = Color(0xFFFF8F00);
  static const Color purple = Color(0xFF6A1B9A);
  static const Color purpleLight = Color(0xFFCE93D8);
  static const Color emerald = Color(0xFF00C853);
  static const Color crimson = Color(0xFFD50000);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color cardGlass = Color(0xB31A1030);
  static const Color borderGlow = Color(0x4DFFD700);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textGold = Color(0xFFFFD700);
  static const Color rarityCommon = Color(0xFF90A4AE);
  static const Color rarityRare = Color(0xFF42A5F5);
  static const Color rarityEpic = Color(0xFFAB47BC);
  static const Color rarityLegendary = Color(0xFFFF8F00);

  static Color rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'rare':
        return rarityRare;
      case 'epic':
        return rarityEpic;
      case 'legendary':
        return rarityLegendary;
      default:
        return rarityCommon;
    }
  }
}
