import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attack_model.dart';
import '../../../core/services/audio_manager.dart';
import '../providers/attack_raid_provider.dart';
import '../providers/player_state_provider.dart';

/// Coin Master-style Attack screen.
/// Auto-fetches a random public target, shows their village in 3D perspective,
/// plays a hammer/UFO smash animation, and reveals the result.
class AttackScreen extends ConsumerStatefulWidget {
  const AttackScreen({super.key});
  @override
  ConsumerState<AttackScreen> createState() => _AttackScreenState();
}

class _AttackScreenState extends ConsumerState<AttackScreen>
    with TickerProviderStateMixin {
  // Phases: loading → ready → attacking → result
  String _phase = 'loading';
  PlayerTargetModel? _target;
  AttackResultModel? _result;

  late AnimationController _hammerCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _resultCtrl;
  late Animation<double> _hammerY;
  late Animation<double> _hammerRotation;

  final _buildings = ['🏠', '🏰', '⛪', '🗼', '🏛️', '🏪', '🌳', '🏗️', '⛺'];
  int _destroyedIdx = -1;

  @override
  void initState() {
    super.initState();
    _hammerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _hammerY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -200.0, end: 0.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -30.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -30.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _hammerCtrl, curve: Curves.easeIn));
    _hammerRotation = Tween(begin: -0.3, end: 0.0)
        .animate(CurvedAnimation(parent: _hammerCtrl, curve: Curves.easeOut));

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _loadTarget();
  }

  @override
  void dispose() {
    _hammerCtrl.dispose();
    _shakeCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTarget() async {
    try {
      final targets = await ref.read(targetsProvider.future);
      if (targets.isEmpty) {
        if (mounted) context.go('/game');
        return;
      }
      final rng = Random();
      setState(() {
        _target = targets[rng.nextInt(targets.length)];
        _destroyedIdx = rng.nextInt(_buildings.length);
        _phase = 'ready';
      });
      // Auto-start attack after brief delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _executeAttack();
    } catch (_) {
      if (mounted) context.go('/game');
    }
  }

  Future<void> _executeAttack() async {
    if (_target == null) return;
    setState(() => _phase = 'attacking');
    AudioManager.instance.playAttack();

    // Start hammer animation
    await _hammerCtrl.forward();

    // Screen shake on impact
    _shakeCtrl.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 400));
    _shakeCtrl.stop();
    _shakeCtrl.reset();

    // Call API
    final result =
        await ref.read(attackProvider.notifier).attack(_target!.userId);

    if (!mounted) return;

    setState(() {
      _result = result;
      _phase = 'result';
    });

    if (result != null && !result.wasBlocked) {
      AudioManager.instance.playCoinWin();
    } else {
      AudioManager.instance.playShield();
    }

    _resultCtrl.forward();
    // Refresh player state for updated coins
    ref.invalidate(playerStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1), Color(0xFF1A0A3E)],
          ),
        ),
        child: SafeArea(
          child: _phase == 'loading'
              ? _buildLoading()
              : AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (ctx, child) {
                    final dx = _shakeCtrl.isAnimating
                        ? sin(_shakeCtrl.value * pi * 6) * 8
                        : 0.0;
                    return Transform.translate(
                        offset: Offset(dx, 0), child: child);
                  },
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 8),
                      Expanded(child: _buildVillage3D()),
                      if (_phase == 'result') _buildResult(),
                      _buildBottomButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚔️', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('Finding target...',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          CircularProgressIndicator(color: Color(0xFFFFD700)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (_target == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Target avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFD50000)]),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: Center(
              child: Text(
                _target!.displayName.isNotEmpty
                    ? _target!.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_target!.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                Text('Village ${_target!.villageLevel}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Text('⚔️', style: TextStyle(fontSize: 32)),
        ],
      ),
    );
  }

  // ── 3D Village with perspective ──
  Widget _buildVillage3D() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002) // perspective
        ..rotateX(0.3), // tilt forward
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF81D4FA), Color(0xFF4CAF50), Color(0xFF2E7D32)],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66000000),
                blurRadius: 20,
                offset: Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Clouds
              const Positioned(
                  top: 20, left: 30, child: Text('☁️', style: TextStyle(fontSize: 24))),
              const Positioned(
                  top: 12, right: 40, child: Text('☁️', style: TextStyle(fontSize: 18))),
              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF388E3C)]),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                ),
              ),
              // Buildings in grid
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: _buildBuildingRow(),
              ),
              // Hammer animation
              if (_phase == 'attacking' || _phase == 'result')
                AnimatedBuilder(
                  animation: _hammerCtrl,
                  builder: (ctx, _) {
                    return Positioned(
                      top: 20 + (_hammerY.value + 200) * 0.5,
                      left: 0,
                      right: 0,
                      child: Transform.rotate(
                        angle: _hammerRotation.value,
                        child: const Center(
                          child:
                              Text('🔨', style: TextStyle(fontSize: 56)),
                        ),
                      ),
                    );
                  },
                ),
              // Explosion on destroyed building
              if (_phase == 'result' && _result != null && !_result!.wasBlocked)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text('💥',
                        style: TextStyle(
                            fontSize: 52,
                            shadows: [
                              Shadow(
                                  color: Colors.orange.withAlpha(200),
                                  blurRadius: 20)
                            ])),
                  ),
                ),
              // Shield block effect
              if (_phase == 'result' && _result != null && _result!.wasBlocked)
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🛡️',
                            style: TextStyle(
                                fontSize: 64,
                                shadows: [
                                  Shadow(
                                      color: Colors.cyan.withAlpha(200),
                                      blurRadius: 24)
                                ])),
                        const SizedBox(height: 4),
                        const Text('BLOCKED!',
                            style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: List.generate(_buildings.length, (i) {
        final destroyed =
            _phase == 'result' && i == _destroyedIdx && _result != null && !_result!.wasBlocked;
        return Opacity(
          opacity: destroyed ? 0.3 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                destroyed ? '💥' : _buildings[i],
                style: TextStyle(fontSize: i == 1 ? 40 : 32),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _resultCtrl,
      builder: (ctx, child) {
        final scale =
            Curves.elasticOut.transform(_resultCtrl.value.clamp(0.0, 1.0));
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            _result!.wasBlocked
                ? const Color(0xFF006064)
                : const Color(0xFF4A148C),
            _result!.wasBlocked
                ? const Color(0xFF004D40)
                : const Color(0xFF1A0A3E),
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _result!.wasBlocked
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFFFFD700),
              width: 2),
          boxShadow: [
            BoxShadow(
              color: (_result!.wasBlocked
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFFFFD700))
                  .withAlpha(80),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              _result!.wasBlocked ? 'BLOCKED BY SHIELD!' : 'ATTACK SUCCESS!',
              style: TextStyle(
                color: _result!.wasBlocked
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFFFFD700),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            if (!_result!.wasBlocked) ...[
              const SizedBox(height: 6),
              Text(
                '+${NumberFormat('#,###').format(_result!.coinsStolen)} coins stolen!',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              if (_result!.buildingDestroyed != null)
                Text(
                  '${_result!.buildingDestroyed} destroyed!',
                  style: const TextStyle(
                      color: Color(0xFFFF8A80), fontSize: 13),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    if (_phase != 'result') return const SizedBox(height: 60);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: GestureDetector(
        onTap: () => context.go('/game'),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
            borderRadius: BorderRadius.circular(27),
            border:
                Border.all(color: const Color(0xFFFFD54F), width: 2.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x6643A047),
                  blurRadius: 14,
                  offset: Offset(0, 4)),
            ],
          ),
          child: const Center(
            child: Text('CONTINUE',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 3)),
          ),
        ),
      ),
    );
  }
}
