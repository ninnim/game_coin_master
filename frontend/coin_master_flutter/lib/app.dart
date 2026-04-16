import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'shared/theme/app_colors.dart';

class SpinEmpireApp extends ConsumerWidget {
  const SpinEmpireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Spin Empire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.purple,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.gold,
        ),
      ),
      routerConfig: router,
    );
  }
}
