import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';

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
    context.go(isAuth ? '/game' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7B2FBE), Color(0xFF4A148C), Color(0xFF311B92)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFF9A825)]),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF5D4037), width: 4),
                  boxShadow: const [BoxShadow(color: Color(0x66FFD700), blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Center(child: Text('🎰', style: TextStyle(fontSize: 48))),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), duration: const Duration(milliseconds: 1200)),
              const SizedBox(height: 24),
              const Text('SPIN', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Color(0xFFFFD700), letterSpacing: 10,
                  shadows: [Shadow(color: Colors.black54, offset: Offset(3, 3), blurRadius: 8)]))
                  .animate().fadeIn(duration: const Duration(milliseconds: 600)).slideY(begin: -0.3),
              const Text('EMPIRE', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8,
                  shadows: [Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 6)]))
                  .animate().fadeIn(delay: const Duration(milliseconds: 300), duration: const Duration(milliseconds: 600)).slideY(begin: 0.3),
              const SizedBox(height: 48),
              const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: Color(0xFFFFD700), strokeWidth: 3)),
            ],
          ),
        ),
      ),
    );
  }
}
