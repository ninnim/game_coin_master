import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds — bright sky theme
  static const Color background = Color(0xFF87CEEB); // sky blue
  static const Color backgroundDark = Color(0xFF5BA3D9); // darker sky
  static const Color surface = Color(0xFFFFF8E1); // warm cream
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Primary game colors
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFF176);
  static const Color goldDark = Color(0xFFFF8F00);
  static const Color coinGold = Color(0xFFF5C842);

  // UI colors
  static const Color purple = Color(0xFF7B2FBE);
  static const Color purpleLight = Color(0xFFBB86FC);
  static const Color purpleDark = Color(0xFF4A148C);
  static const Color pink = Color(0xFFE91E63);
  static const Color orange = Color(0xFFFF6D00);
  static const Color teal = Color(0xFF00BFA5);

  // Status colors
  static const Color emerald = Color(0xFF00C853);
  static const Color crimson = Color(0xFFD50000);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color amber = Color(0xFFFFB300);

  // Spin button
  static const Color spinRed = Color(0xFFE53935);
  static const Color spinRedDark = Color(0xFFB71C1C);
  static const Color spinRedLight = Color(0xFFFF5252);

  // Slot machine
  static const Color slotBg = Color(0xFFFFF3E0);
  static const Color slotFrame = Color(0xFF8D6E63); // wood brown
  static const Color slotFrameLight = Color(0xFFBCAAA4);
  static const Color slotFrameDark = Color(0xFF5D4037);

  // Card / panel colors
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color cardShadow = Color(0x33000000);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGold = Color(0xFFFF8F00);

  // Rarity
  static const Color rarityCommon = Color(0xFF90A4AE);
  static const Color rarityRare = Color(0xFF42A5F5);
  static const Color rarityEpic = Color(0xFFAB47BC);
  static const Color rarityLegendary = Color(0xFFFF8F00);

  // Legacy compat
  static const Color borderGlow = Color(0xFFE0E0E0);

  // Bottom nav
  static const Color navBg = Color(0xFF4A148C); // deep purple
  static const Color navActive = Color(0xFFFFD700);
  static const Color navInactive = Color(0xFFCE93D8);

  static Color rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'rare': return rarityRare;
      case 'epic': return rarityEpic;
      case 'legendary': return rarityLegendary;
      default: return rarityCommon;
    }
  }
}
