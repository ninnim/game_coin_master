import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attack_model.dart';
import '../../../core/services/audio_manager.dart';
import '../providers/attack_raid_provider.dart';
import '../providers/player_state_provider.dart';

/// Coin Master-style Raid screen.
/// Auto-fetches a random target, shows a 3x3 hole grid.
/// Player taps 3 holes (4 with Foxy pet), pig digs, reveals coins or empty.
class RaidScreen extends ConsumerStatefulWidget {
  const RaidScreen({super.key});
  @override
  ConsumerState<RaidScreen> createState() => _RaidScreenState();
}

class _RaidScreenState extends ConsumerState<RaidScreen>
    with TickerProviderStateMixin {
  String _phase = 'loading'; // loading → picking → digging → result
  PlayerTargetModel? _target;
  RaidFullResultModel? _result;

  final List<int> _selectedHoles = [];
  final Map<int, bool> _revealedHoles = {};
  final Map<int, int> _holeCoins = {};
  final int _maxHoles = 3;
  int _totalRevealed = 0;

  late AnimationController _digCtrl;
  late AnimationController _resultCtrl;
  int _currentDigHole = -1;

  @override
  void initState() {
    super.initState();
    _digCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _loadTarget();
  }

  @override
  void dispose() {
    _digCtrl.dispose();
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
        _phase = 'picking';
      });
    } catch (_) {
      if (mounted) context.go('/game');
    }
  }

  Future<void> _onHoleTap(int idx) async {
    if (_phase != 'picking') return;
    if (_selectedHoles.contains(idx)) return;
    if (_selectedHoles.length >= _maxHoles) return;

    _selectedHoles.add(idx);
    setState(() => _currentDigHole = idx);

    // Dig animation
    AudioManager.instance.playRaid();
    _digCtrl.reset();
    await _digCtrl.forward();

    // If we've selected all holes, execute the raid
    if (_selectedHoles.length >= _maxHoles) {
      setState(() => _phase = 'digging');
      await _executeRaid();
    } else {
      setState(() {
        _revealedHoles[idx] = true; // show "digging" state
      });
    }
  }

  Future<void> _executeRaid() async {
    if (_target == null) return;

    final result = await ref
        .read(raidProvider.notifier)
        .raid(_target!.userId, _selectedHoles);

    if (!mounted) return;

    if (result == null) {
      setState(() => _phase = 'result');
      return;
    }

    // Reveal holes one by one with animation
    for (final hole in result.holeResults) {
      _holeCoins[hole.position] = hole.coinsFound;
      setState(() {
        _revealedHoles[hole.position] = true;
        _currentDigHole = hole.position;
      });
      _digCtrl.reset();
      await _digCtrl.forward();
      if (hole.coinsFound > 0) {
        AudioManager.instance.playCoinWin();
        _totalRevealed += hole.coinsFound;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      _result = result;
      _phase = 'result';
    });

    _resultCtrl.forward();
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
            colors: [
              Color(0xFFFF8F00),
              Color(0xFFE65100),
              Color(0xFF4E342E),
              Color(0xFF1A0A3E),
            ],
            stops: [0.0, 0.25, 0.55, 0.85],
          ),
        ),
        child: SafeArea(
          child: _phase == 'loading'
              ? _buildLoading()
              : Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildInstructions(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildHoleGrid()),
                    if (_phase == 'result') _buildResult(),
                    _buildBottomButton(),
                    const SizedBox(height: 16),
                  ],
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
          Text('🐷', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('Finding someone to raid...',
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF6D00), Color(0xFFE65100)]),
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
                Text(
                    '🐷 ${NumberFormat('#,###').format(_target!.pigBankCoins)} coins',
                    style: const TextStyle(
                        color: Color(0xFFFFD54F), fontSize: 12)),
              ],
            ),
          ),
          const Text('🐷', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final remaining = _maxHoles - _selectedHoles.length;
    String text;
    if (_phase == 'picking') {
      text = remaining > 0
          ? 'Tap $remaining hole${remaining > 1 ? 's' : ''} to dig!'
          : 'Digging...';
    } else if (_phase == 'digging') {
      text = 'Digging...';
    } else {
      text = 'Raid complete!';
    }
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 18,
        letterSpacing: 1,
        shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
      ),
    );
  }

  // ── 3x3 Hole Grid ──
  Widget _buildHoleGrid() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateX(0.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          itemCount: 9,
          itemBuilder: (ctx, idx) => _buildHoleTile(idx),
        ),
      ),
    );
  }

  Widget _buildHoleTile(int idx) {
    final isSelected = _selectedHoles.contains(idx);
    final isRevealed = _revealedHoles[idx] == true;
    final coins = _holeCoins[idx] ?? -1;
    final isDigging = _currentDigHole == idx && _digCtrl.isAnimating;

    return GestureDetector(
      onTap: () => _onHoleTap(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isRevealed && coins >= 0
                ? (coins > 0
                    ? [const Color(0xFFFFD54F), const Color(0xFFF9A825)]
                    : [const Color(0xFF5D4037), const Color(0xFF3E2723)])
                : isSelected
                    ? [const Color(0xFF8D6E63), const Color(0xFF5D4037)]
                    : [const Color(0xFFA1887F), const Color(0xFF795548)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRevealed && coins > 0
                ? const Color(0xFFFFD700)
                : isSelected
                    ? const Color(0xFFBCAAA4)
                    : const Color(0xFF6D4C41),
            width: isRevealed && coins > 0 ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isRevealed && coins > 0
                  ? const Color(0x66FFD700)
                  : const Color(0x44000000),
              blurRadius: isRevealed && coins > 0 ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isDigging
              ? _buildDiggingAnimation()
              : isRevealed && coins >= 0
                  ? _buildRevealedContent(coins)
                  : _buildMound(isSelected),
        ),
      ),
    );
  }

  Widget _buildMound(bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(selected ? '⛏️' : '❓',
            style: TextStyle(fontSize: selected ? 32 : 28)),
        if (!selected)
          const Text('DIG',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDiggingAnimation() {
    return AnimatedBuilder(
      animation: _digCtrl,
      builder: (ctx, _) {
        final bounce = sin(_digCtrl.value * pi * 3) * 6;
        return Transform.translate(
          offset: Offset(0, bounce),
          child: const Text('🐷', style: TextStyle(fontSize: 38)),
        );
      },
    );
  }

  Widget _buildRevealedContent(int coins) {
    if (coins > 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💰', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 2),
          Text(
            _formatCompact(coins),
            style: const TextStyle(
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      );
    }
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('💨', style: TextStyle(fontSize: 28)),
        Text('Empty',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildResult() {
    final total = _result?.totalCoinsStolen ?? _totalRevealed;
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
          gradient: const LinearGradient(
              colors: [Color(0xFF4A148C), Color(0xFF1A0A3E)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x66FFD700), blurRadius: 16),
          ],
        ),
        child: Column(
          children: [
            const Text('RAID COMPLETE!',
                style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2)),
            const SizedBox(height: 6),
            Text(
              '+${NumberFormat('#,###').format(total)} coins!',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
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

  String _formatCompact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
