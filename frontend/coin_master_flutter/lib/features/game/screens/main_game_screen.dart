import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../providers/player_state_provider.dart';
import '../providers/spin_provider.dart';
import '../../../core/models/spin_result_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/toast_notification.dart';

class MainGameScreen extends ConsumerStatefulWidget {
  const MainGameScreen({super.key});

  @override
  ConsumerState<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends ConsumerState<MainGameScreen>
    with TickerProviderStateMixin {
  bool _isSpinning = false;
  SpinResultModel? _lastResult;
  String? _pendingAction;

  // Reel animation
  late AnimationController _reelMasterCtrl;
  final List<double> _reelOffsets = [0, 0, 0];
  final List<int> _reelFinalIndex = [0, 0, 0];
  List<bool> _reelStopped = [true, true, true];

  // Spin button animation
  late AnimationController _spinBtnCtrl;
  late Animation<double> _spinBtnScale;

  // Coin fly animation
  late AnimationController _coinFlyCtrl;

  // Symbol data
  static const List<_SlotSymbol> _symbols = [
    _SlotSymbol('🪙', 'Coins', Color(0xFFFFD700)),
    _SlotSymbol('⚔️', 'Attack', Color(0xFFD50000)),
    _SlotSymbol('🐷', 'Raid', Color(0xFFFF8A80)),
    _SlotSymbol('🛡️', 'Shield', Color(0xFF00BCD4)),
    _SlotSymbol('⚡', 'Energy', Color(0xFFFFD600)),
    _SlotSymbol('🎰', 'Jackpot', Color(0xFFFF6D00)),
  ];

  @override
  void initState() {
    super.initState();
    _reelMasterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(_updateReels);

    _spinBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _spinBtnScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _spinBtnCtrl, curve: Curves.easeInOut),
    );

    _coinFlyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _loadPlayerState();
  }

  @override
  void dispose() {
    _reelMasterCtrl.dispose();
    _spinBtnCtrl.dispose();
    _coinFlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerState() async {
    try {
      final ps = await ref.read(playerStateProvider.future);
      if (mounted) {
        ref.read(gameStateProvider.notifier).updateFromPlayerState(ps);
      }
    } catch (_) {}
  }

  void _updateReels() {
    final t = _reelMasterCtrl.value;
    setState(() {
      for (int i = 0; i < 3; i++) {
        final stopTime = 0.4 + i * 0.2; // reels stop at 0.4, 0.6, 0.8
        if (t < stopTime) {
          // Still spinning — rapid offset
          _reelOffsets[i] = (t * 30 + i * 3) % 1.0;
          _reelStopped[i] = false;
        } else {
          if (!_reelStopped[i]) {
            _reelStopped[i] = true;
          }
          _reelOffsets[i] = 0;
        }
      }
    });
  }

  int _symbolIndexForSlot(String slot) {
    switch (slot) {
      case 'coin_small':
      case 'coin_medium':
      case 'coin_large':
        return 0;
      case 'attack':
        return 1;
      case 'raid':
        return 2;
      case 'shield':
        return 3;
      case 'energy':
        return 4;
      case 'jackpot':
        return 5;
      default:
        return 0;
    }
  }

  Future<void> _doSpin() async {
    if (_isSpinning) return;
    final betMultiplier = ref.read(betMultiplierProvider);
    setState(() {
      _isSpinning = true;
      _pendingAction = null;
      _reelStopped = [false, false, false];
    });

    _reelMasterCtrl.reset();
    _reelMasterCtrl.forward();

    final result = await ref.read(spinProvider.notifier).spin(betMultiplier);

    if (result == null) {
      _reelMasterCtrl.stop();
      setState(() => _isSpinning = false);
      if (mounted) showGameToast(context, 'Not enough spins!', isError: true);
      return;
    }

    // Set the final symbols so when reels stop they show the right result
    _reelFinalIndex[0] = _symbolIndexForSlot(result.slot1);
    _reelFinalIndex[1] = _symbolIndexForSlot(result.slot2);
    _reelFinalIndex[2] = _symbolIndexForSlot(result.slot3);

    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 2500));

    setState(() {
      _lastResult = result;
      _pendingAction = result.specialAction;
      _isSpinning = false;
    });

    ref
        .read(gameStateProvider.notifier)
        .applySpinResult(result.currentCoins, result.spinsRemaining);

    if (!mounted) return;

    // Coin animation on win
    if (result.coinsEarned > 0) {
      _coinFlyCtrl.reset();
      _coinFlyCtrl.forward();
    }

    if (result.isJackpot) {
      final canVibrate = await Vibration.hasVibrator() ?? false;
      if (canVibrate) Vibration.vibrate(duration: 500);
      if (mounted) {
        showGameToast(
          context,
          'JACKPOT! +${NumberFormat("#,###").format(result.coinsEarned)} coins!',
          isSuccess: true,
        );
      }
    } else if (result.coinsEarned > 0) {
      showGameToast(
        context,
        '+${NumberFormat("#,###").format(result.coinsEarned)} coins!',
        isSuccess: true,
      );
    } else if (result.specialAction == 'shield') {
      ref.read(gameStateProvider.notifier).addShield();
      showGameToast(context, 'Shield activated!', isSuccess: true);
    } else if (result.specialAction == 'energy') {
      showGameToast(context, '+${result.spinsEarned} spins!', isSuccess: true);
    } else if (result.specialAction == 'attack') {
      ref.read(gameStateProvider.notifier).setPendingAttack();
      showGameToast(context, 'Attack ready! Choose a target.');
    } else if (result.specialAction == 'raid') {
      ref.read(gameStateProvider.notifier).setPendingRaid();
      showGameToast(context, 'Raid ready! Choose a target.');
    }
  }

  // ============== BUILD METHODS ==============

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final playerState = ref.watch(playerStateProvider);
    final betMultiplier = ref.watch(betMultiplierProvider);
    final villageName =
        playerState.valueOrNull?.currentVillage.name ?? 'Village';
    final villageNum =
        playerState.valueOrNull?.currentVillage.orderNum ?? 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // === TOP HUD ===
              _buildTopHUD(gameState.coins, gameState.spins, gameState.shields),
              // === SCROLLABLE CONTENT ===
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      // Character avatar row
                      _buildCharacterRow(),
                      // Village scene
                      _buildVillageScene(villageName, villageNum),
                      // Slot machine
                      _buildSlotMachine(betMultiplier, gameState.spins),
                      // Pending action
                      if (_pendingAction != null) _buildPendingAction(),
                      // Spin counter
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          '${NumberFormat("#,###").format(gameState.spins)} spins',
                          style: const TextStyle(
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // === TOP HUD BAR ===
  Widget _buildTopHUD(int coins, int spins, int shields) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Stars / level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⭐', style: TextStyle(fontSize: 14)),
                SizedBox(width: 2),
                Text('1',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Coin display
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coin icon
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFF9A825)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('\$',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5D4037))),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _formatCoins(coins),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // + button
                  const SizedBox(width: 4),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C853),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('+',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Shields
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: i < shields
                      ? const Color(0xFF00BCD4)
                      : const Color(0xFFBDBDBD),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 2),
                  ],
                ),
                child: const Center(
                  child: Text('🛡️', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Settings
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4A148C),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1),
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // === CHARACTER AVATAR ROW ===
  Widget _buildCharacterRow() {
    final avatars = [
      {'emoji': '🧙‍♂️', 'color': const Color(0xFF7B2FBE)},
      {'emoji': '🤴', 'color': const Color(0xFFFF6D00)},
      {'emoji': '👸', 'color': const Color(0xFFE91E63)},
      {'emoji': '🧝', 'color': const Color(0xFF00897B)},
      {'emoji': '🦸', 'color': const Color(0xFF1565C0)},
      {'emoji': '🧛', 'color': const Color(0xFFD50000)},
    ];
    return SizedBox(
      height: 62,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: avatars.length,
        itemBuilder: (context, i) {
          final a = avatars[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (a['color'] as Color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i == 0 ? AppColors.gold : Colors.white,
                      width: i == 0 ? 3 : 2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      a['emoji'] as String,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                if (i == 0)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C853),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // === VILLAGE SCENE ===
  Widget _buildVillageScene(String villageName, int villageNum) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFF81D4FA), Color(0xFF4CAF50)],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Clouds
          const Positioned(
            top: 12,
            left: 20,
            child: Text('☁️', style: TextStyle(fontSize: 28)),
          ),
          const Positioned(
            top: 8,
            right: 40,
            child: Text('☁️', style: TextStyle(fontSize: 22)),
          ),
          const Positioned(
            top: 30,
            right: 90,
            child: Text('☁️', style: TextStyle(fontSize: 18)),
          ),
          // Ground
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 55,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ),
          // Buildings
          const Positioned(
            bottom: 25,
            left: 20,
            child: Text('🏠', style: TextStyle(fontSize: 38)),
          ),
          const Positioned(
            bottom: 30,
            left: 90,
            child: Text('🏰', style: TextStyle(fontSize: 52)),
          ),
          const Positioned(
            bottom: 25,
            right: 60,
            child: Text('⛪', style: TextStyle(fontSize: 36)),
          ),
          const Positioned(
            bottom: 25,
            right: 10,
            child: Text('🏗️', style: TextStyle(fontSize: 32)),
          ),
          const Positioned(
            bottom: 22,
            left: 170,
            child: Text('🌳', style: TextStyle(fontSize: 28)),
          ),
          // Village label
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCC4A148C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Village $villageNum: $villageName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [
                      Shadow(color: Colors.black38, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Arrows
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === SLOT MACHINE ===
  Widget _buildSlotMachine(int betMultiplier, int spins) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBCAAA4), Color(0xFF8D6E63), Color(0xFF5D4037)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Coin display label
            if (_lastResult != null && _lastResult!.coinsEarned > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Text(
                  '${NumberFormat("#,###").format(_lastResult!.coinsEarned)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            // === 3 REELS ===
            SizedBox(
              height: 110,
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildAnimatedReel(i),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 10),
            // Bet selector row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bet down
                GestureDetector(
                  onTap: () {
                    final bets = [1, 2, 3, 5, 10];
                    final idx = bets.indexOf(betMultiplier);
                    if (idx > 0) {
                      ref.read(betMultiplierProvider.notifier).state =
                          bets[idx - 1];
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: const Icon(Icons.remove,
                        color: Colors.white, size: 20),
                  ),
                ),
                // Bet display
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: Text(
                    'BET x$betMultiplier',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                // Bet up
                GestureDetector(
                  onTap: () {
                    final bets = [1, 2, 3, 5, 10];
                    final idx = bets.indexOf(betMultiplier);
                    if (idx < bets.length - 1) {
                      ref.read(betMultiplierProvider.notifier).state =
                          bets[idx + 1];
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // === SPIN BUTTON ===
            _buildSpinButton(spins),
          ],
        ),
      ),
    );
  }

  // === ANIMATED REEL ===
  Widget _buildAnimatedReel(int reelIndex) {
    final isStopped = _reelStopped[reelIndex];
    final finalSymbol = _symbols[_reelFinalIndex[reelIndex]];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8D6E63), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: isStopped && _lastResult != null && _lastResult!.isJackpot
                ? AppColors.gold.withAlpha(150)
                : Colors.black12,
            blurRadius: isStopped && _lastResult != null && _lastResult!.isJackpot
                ? 12
                : 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isStopped && !_isSpinning
            ? Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.7, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Text(
                    finalSymbol.emoji,
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              )
            : _buildSpinningReelStrip(reelIndex),
      ),
    );
  }

  Widget _buildSpinningReelStrip(int reelIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final offset = _reelOffsets[reelIndex];
        return Stack(
          children: List.generate(4, (i) {
            final symbolIdx =
                (i + (offset * 20).floor() + reelIndex * 2) % _symbols.length;
            final yPos = (i * constraints.maxHeight / 2) -
                (offset * constraints.maxHeight * 2);
            return Positioned(
              top: yPos % (constraints.maxHeight * 2) -
                  constraints.maxHeight / 2,
              left: 0,
              right: 0,
              child: SizedBox(
                height: constraints.maxHeight,
                child: Center(
                  child: Text(
                    _symbols[symbolIdx].emoji,
                    style: const TextStyle(fontSize: 38),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // === SPIN BUTTON ===
  Widget _buildSpinButton(int spins) {
    final canSpin = !_isSpinning && spins > 0;
    return GestureDetector(
      onTapDown: canSpin ? (_) => _spinBtnCtrl.forward() : null,
      onTapUp: canSpin
          ? (_) {
              _spinBtnCtrl.reverse();
              _doSpin();
            }
          : null,
      onTapCancel: () => _spinBtnCtrl.reverse(),
      child: ScaleTransition(
        scale: _spinBtnScale,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: canSpin
                  ? const [Color(0xFFFF5252), Color(0xFFE53935), Color(0xFFB71C1C)]
                  : [Colors.grey.shade400, Colors.grey.shade600],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: canSpin ? const Color(0xFFFFD54F) : Colors.grey,
              width: 3,
            ),
            boxShadow: canSpin
                ? const [
                    BoxShadow(
                      color: Color(0x99E53935),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _isSpinning
                ? const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Text(
                    spins > 0 ? 'SPIN' : 'NO SPINS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: canSpin
                          ? const [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // === PENDING ACTION BANNER ===
  Widget _buildPendingAction() {
    final isAttack = _pendingAction == 'attack';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAttack ? AppColors.crimson : AppColors.gold,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Text(isAttack ? '⚔️' : '🐷', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAttack
                  ? 'Attack ready! Choose a target.'
                  : 'Raid ready! Choose a target.',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _pendingAction = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAttack
                      ? [const Color(0xFFFF5252), const Color(0xFFD50000)]
                      : [const Color(0xFFFFD54F), const Color(0xFFF9A825)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'GO!',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isAttack ? Colors.white : const Color(0xFF5D4037),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === BOTTOM NAVIGATION ===
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem('🎁', 'Rewards', '/events', false),
              _navItem('⚔️', 'Attack', '/friends', false),
              _navItem('🃏', 'Cards', '/cards', false),
              _navItem('🐾', 'Pets', '/pets', false),
              _navItem('🏆', 'Rank', '/leaderboard', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String emoji, String label, String route, bool active) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.gold.withAlpha(60)
                  : Colors.white.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppColors.gold : Colors.white38,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? AppColors.gold : Colors.white70,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // === HELPERS ===
  String _formatCoins(int coins) {
    if (coins >= 1000000000) {
      return '${(coins / 1000000000).toStringAsFixed(1)}B';
    } else if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M';
    } else if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,###').format(coins);
  }
}

class _SlotSymbol {
  final String emoji;
  final String name;
  final Color color;
  const _SlotSymbol(this.emoji, this.name, this.color);
}
