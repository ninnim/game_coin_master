import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

void showGameToast(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      backgroundColor:
          isError
              ? AppColors.crimson
              : isSuccess
              ? AppColors.emerald
              : AppColors.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isError
                  ? AppColors.crimson
                  : isSuccess
                  ? AppColors.emerald
                  : AppColors.gold,
          width: 1,
        ),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
