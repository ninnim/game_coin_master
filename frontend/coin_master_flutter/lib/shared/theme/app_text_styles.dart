import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle headline = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const TextStyle title = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const TextStyle subtitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle body = TextStyle(fontSize: 14, color: AppColors.textPrimary);
  static const TextStyle caption = TextStyle(fontSize: 12, color: AppColors.textSecondary);
  static const TextStyle gold = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.goldDark);
  static const TextStyle goldLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.goldDark);
  static const TextStyle coinText = TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textWhite, shadows: [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2)]);
}
