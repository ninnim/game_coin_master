import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../providers/player_state_provider.dart';
import '../providers/spin_provider.dart';
import '../../../core/models/spin_result_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
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

  late List<AnimationController> _reelControllers;
  late List<Animation<double>> _reelAnimations;

  final List<String> _reelSymbols = ['🪙', '⚔️', '⛏️', '🛡️', '⚡', '⭐'];
  List<String> _displayedSlots = ['coin_small', 'coin_small', 'coin_small'];

  @override
  void initState() {
    super.initState();
    _reelControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + i * 400),
      ),
    );
    _reelAnimations =
        _reelControllers
            .map(
              (c) =>
                  CurvedAnimation(parent: c, curve: Curves.easeOut)
                      as Animation<double>,
            )
            .toList();
    _loadPlayerState();
  }

  @override
  void dispose() {
    for (final c in _reelControllers) {
      c.dispose();
    }
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

  String _symbolForSlot(String slot) {
    switch (slot) {
      case 'coin_small':
      case 'coin_medium':
      case 'coin_large':
        return '🪙';
      case 'attack':
        return '⚔️';
      case 'raid':
        return '⛏️';
      case 'shield':
        return '🛡️';
      case 'energy':
        return '⚡';
      case 'jackpot':
        return '⭐';
      default:
        return '🪙';
    }
  }

  Color _symbolColor(String slot) {
    switch (slot) {
      case 'attack':
        return AppColors.crimson;
      case 'raid':
        return const Color(0xFF8D6E63);
      case 'shield':
        return AppColors.cyan;
      case 'energy':
        return Colors.yellow;
      case 'jackpot':
        return AppColors.gold;
      default:
        return AppColors.gold;
    }
  }

  Future<void> _doSpin() async {
    if (_isSpinning) return;
    final betMultiplier = ref.read(betMultiplierProvider);
    setState(() {
      _isSpinning = true;
      _pendingAction = null;
    });

    for (final c in _reelControllers) {
      c.reset();
      c.forward();
    }

    final result = await ref.read(spinProvider.notifier).spin(betMultiplier);

    if (result == null) {
      setState(() => _isSpinning = false);
      if (mounted) {
        showGameToast(context, 'Not enough spins!', isError: true);
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1800));

    setState(() {
      _displayedSlots = [result.slot1, result.slot2, result.slot3];
      _lastResult = result;
      _pendingAction = result.specialAction;
      _isSpinning = false;
    });

    ref
        .read(gameStateProvider.notifier)
        .applySpinResult(result.currentCoins, result.spinsRemaining);

    if (!mounted) return;

    if (result.isJackpot) {
      final canVibrate = await Vibration.hasVibrator() ?? false;
      if (canVibrate) Vibration.vibrate(duration: 500);
      showGameToast(
        context,
        '🌟 JACKPOT! +${NumberFormat("#,###").format(result.coinsEarned)} coins!',
        isSuccess: true,
      );
    } else if (result.coinsEarned > 0) {
      showGameToast(
        context,
        '+${NumberFormat("#,###").format(result.coinsEarned)} coins!',
        isSuccess: true,
      );
    } else if (result.specialAction == 'shield') {
      ref.read(gameStateProvider.notifier).addShield();
      showGameToast(context, '🛡️ Shield activated!', isSuccess: true);
    } else if (result.specialAction == 'energy') {
      showGameToast(
        context,
        '⚡ +${result.spinsEarned} spins!',
        isSuccess: true,
      );
    } else if (result.specialAction == 'attack') {
      ref.read(gameStateProvider.notifier).setPendingAttack();
      showGameToast(context, '⚔️ Attack ready! Choose a target.');
    } else if (result.specialAction == 'raid') {
      ref.read(gameStateProvider.notifier).setPendingRaid();
      showGameToast(context, '⛏️ Raid ready! Choose a target.');
    }
  }

  Widget _buildReel(int index, String slot) {
    final symbol = _symbolForSlot(slot);
    final color = _symbolColor(slot);
    return Container(
      width: 90,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _isSpinning
                  ? AppColors.gold.withOpacity(0.5)
                  : color.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 12),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child:
            _isSpinning
                ? _buildSpinningReel(index)
                : Center(
                  child: Text(
                    symbol,
                    style: const TextStyle(fontSize: 40),
                  ).animate().scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: const Duration(milliseconds: 200),
                  ),
                ),
      ),
    );
  }

  Widget _buildSpinningReel(int index) {
    return AnimatedBuilder(
      animation: _reelAnimations[index],
      builder: (context, _) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 20,
          itemBuilder:
              (context, i) => SizedBox(
                height: 100 / 2,
                child: Center(
                  child: Text(
                    _reelSymbols[i % _reelSymbols.length],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
        );
      },
    );
  }

  Widget _buildHUD(int coins, int spins, int shields, int villageNum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.97),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderGlow, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Coins
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  NumberFormat('#,###').format(coins),
                  style: AppTextStyles.gold.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          // Village indicator
          Text(
            'Village $villageNum',
            style: AppTextStyles.caption,
          ),
          // Shields + Spins
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ...List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      Icons.shield,
                      size: 18,
                      color:
                          i < shields
                              ? AppColors.cyan
                              : AppColors.textSecondary.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.bolt, color: AppColors.gold, size: 16),
                Text(
                  '$spins',
                  style: AppTextStyles.gold.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVillagePreview(String skyColor) {
    Color sky;
    try {
      sky = Color(
        int.parse(skyColor.replaceFirst('#', 'FF'), radix: 16),
      );
    } catch (_) {
      sky = const Color(0xFF1565C0);
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky.withOpacity(0.8), AppColors.background],
        ),
      ),
      child: Stack(
        children: [
          // Ground strip
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade900, Colors.green.shade800],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
          ),
          // Village buildings (emoji placeholders)
          Positioned(
            bottom: 20,
            left: 30,
            child: const Text('🏠', style: TextStyle(fontSize: 36))
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: const Duration(seconds: 4)),
          ),
          Positioned(
            bottom: 20,
            left: 110,
            child: const Text('🏰', style: TextStyle(fontSize: 48)),
          ),
          Positioned(
            bottom: 20,
            right: 80,
            child: const Text('⛩️', style: TextStyle(fontSize: 36)),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: const Text('🏗️', style: TextStyle(fontSize: 32)),
          ),
          // Decorations
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGlow),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏰', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text(
                    'Your Village',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetSelector(int betMultiplier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('BET: ', style: AppTextStyles.caption),
          ...[1, 2, 3, 5, 10].map(
            (m) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () =>
                    ref.read(betMultiplierProvider.notifier).state = m,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        betMultiplier == m
                            ? AppColors.gold
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    '${m}x',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color:
                          betMultiplier == m
                              ? AppColors.background
                              : AppColors.gold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinButton(int spins) {
    final canSpin = !_isSpinning && spins > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: canSpin ? _doSpin : null,
          child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        !canSpin
                            ? [
                              Colors.grey.shade700,
                              Colors.grey.shade800,
                            ]
                            : [
                              AppColors.goldDark,
                              AppColors.gold,
                              AppColors.goldLight,
                              AppColors.gold,
                              AppColors.goldDark,
                            ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow:
                      canSpin
                          ? [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.6),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ]
                          : null,
                ),
                child: Center(
                  child:
                      _isSpinning
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.background,
                              strokeWidth: 3,
                            ),
                          )
                          : Text(
                            spins > 0 ? '⚡  SPIN  ⚡' : 'NO SPINS',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.background,
                              letterSpacing: 3,
                            ),
                          ),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: const Duration(seconds: 3),
                color: AppColors.goldLight,
              ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderGlow, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem('🏠', 'Home', '/game', true),
            _navItem('🃏', 'Cards', '/cards', false),
            _navItem('👥', 'Social', '/friends', false),
            _navItem('🏆', 'Events', '/events', false),
            _navItem('👤', 'Profile', '/profile', false),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    String emoji,
    String label,
    String route,
    bool active,
  ) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.gold : AppColors.textSecondary,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final playerState = ref.watch(playerStateProvider);
    final betMultiplier = ref.watch(betMultiplierProvider);
    final skyColor =
        playerState.valueOrNull?.currentVillage.skyColor ?? '#1565C0';
    final villageNum =
        playerState.valueOrNull?.currentVillage.orderNum ?? 1;
    final recentAttacks =
        playerState.valueOrNull?.recentAttacks ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _buildHUD(
              gameState.coins,
              gameState.spins,
              gameState.shields,
              villageNum,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Village background
                  _buildVillagePreview(skyColor),
                  const SizedBox(height: 16),
                  // Slot machine
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Title row
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Text(
                                '🎰 SLOT MACHINE',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Reels
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: List.generate(3, (i) {
                              return _buildReel(
                                i,
                                _displayedSlots[i],
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                          // Payline
                          Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.gold,
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Last result info
                          if (_lastResult != null)
                            Text(
                              _lastResult!.isJackpot
                                  ? '🌟 JACKPOT!'
                                  : _lastResult!.coinsEarned > 0
                                  ? '+${NumberFormat("#,###").format(_lastResult!.coinsEarned)} coins'
                                  : _lastResult!.specialAction != null
                                  ? '${_symbolForSlot(_lastResult!.specialAction!)} ${_lastResult!.specialAction!.toUpperCase()}'
                                  : 'No win',
                              style: TextStyle(
                                color:
                                    _lastResult!.isJackpot
                                        ? AppColors.gold
                                        : _lastResult!.coinsEarned > 0
                                        ? AppColors.emerald
                                        : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pending action banner
                  if (_pendingAction != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: GlassCard(
                        borderColor:
                            _pendingAction == 'attack'
                                ? AppColors.crimson
                                : AppColors.gold,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Text(
                              _pendingAction == 'attack' ? '⚔️' : '⛏️',
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _pendingAction == 'attack'
                                    ? 'Attack ready! Choose a target.'
                                    : 'Raid ready! Choose a target.',
                                style: AppTextStyles.body,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _pendingAction = null);
                                ref
                                    .read(gameStateProvider.notifier)
                                    .clearPendingAction();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _pendingAction == 'attack'
                                          ? AppColors.crimson
                                          : AppColors.gold,
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ),
                                ),
                                child: const Text(
                                  'USE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.background,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_pendingAction != null) const SizedBox(height: 12),
                  // Bet selector
                  _buildBetSelector(betMultiplier),
                  const SizedBox(height: 16),
                  // Spin button
                  _buildSpinButton(gameState.spins),
                  const SizedBox(height: 8),
                  Text(
                    '${gameState.spins} spins remaining',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 24),
                  // Recent attacks
                  if (recentAttacks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚔️ Recent Attacks',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: 8),
                            ...recentAttacks.take(3).map(
                              (a) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.shield,
                                      size: 14,
                                      color:
                                          a.wasBlocked
                                              ? AppColors.cyan
                                              : AppColors.crimson,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        a.wasBlocked
                                            ? '${a.attackerName} attacked — BLOCKED!'
                                            : '${a.attackerName} stole ${NumberFormat("#,###").format(a.coinsStolen)} coins',
                                        style: AppTextStyles.caption,
                                      ),
                                    ),
                                    if (a.canRevenge && !a.wasRevenged)
                                      GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.crimson,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            '⚔️ Revenge',
                                            style: TextStyle(
                                              color: AppColors.crimson,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
