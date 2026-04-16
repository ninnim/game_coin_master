import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

void showGameToast(BuildContext context, String message, {bool isError = false, bool isSuccess = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      if (isSuccess) const Icon(Icons.check_circle, color: Colors.white, size: 20),
      if (isError) const Icon(Icons.error, color: Colors.white, size: 20),
      if (isSuccess || isError) const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    ]),
    backgroundColor: isError ? AppColors.crimson : isSuccess ? AppColors.emerald : AppColors.purple,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 2),
    elevation: 6,
  ));
}
