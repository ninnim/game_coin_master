import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final isAuth = await ref.read(authProvider.notifier).checkAuth();
    if (!mounted) return;
    if (isAuth) {
      context.go('/game');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Star field background
          ...List.generate(
            40,
            (i) => Positioned(
              left: (i * 37.3) % size.width,
              top: (i * 53.7) % size.height,
              child: Container(
                    width: i % 3 == 0 ? 3 : 2,
                    height: i % 3 == 0 ? 3 : 2,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(
                    delay: Duration(milliseconds: i * 80),
                    duration: const Duration(milliseconds: 800),
                  )
                  .then()
                  .fadeOut(duration: const Duration(milliseconds: 800)),
            ),
          ),
          // Logo center
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crown icon
                Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '👑',
                          style: TextStyle(fontSize: 48),
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 16),
                Text(
                      'SPIN',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                        letterSpacing: 10,
                        shadows: [
                          Shadow(
                            color: AppColors.gold.withOpacity(0.8),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: const Duration(seconds: 2),
                      color: AppColors.goldLight,
                    ),
                Text(
                  'EMPIRE',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purpleLight,
                    letterSpacing: 8,
                    shadows: [
                      Shadow(
                        color: AppColors.purple.withOpacity(0.8),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    strokeWidth: 2,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                const SizedBox(height: 16),
                Text(
                  'Loading your empire...',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
