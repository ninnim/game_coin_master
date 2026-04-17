import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../providers/player_state_provider.dart';
import '../providers/spin_provider.dart';
import '../../../core/models/spin_result_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../core/services/audio_manager.dart';
import '../widgets/three_d_slot_machine.dart';
import '../widgets/coin_master_widgets.dart';

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

  // ── Reel animation ──
  late AnimationController _reelMasterCtrl;
  final List<double> _reelScrollPos = [0.0, 0.0, 0.0];
  final List<int> _reelFinalIndex = [0, 0, 0];
  final List<bool> _reelStopped = [true, true, true];
  final List<double> _reelDecelStart = [0.0, 0.0, 0.0];
  final List<double> _reelDecelEnd = [0.0, 0.0, 0.0];
  bool _reelTargetsSet = false;

  // ── Win effect ──
  late AnimationController _winEffectCtrl;
  String _winType = '';
  int _winAmount = 0;

  // ── Spin button ──
  late AnimationController _spinBtnCtrl;
  late Animation<double> _spinBtnScale;

  // ── 3D slot machine (Three.js WebView) ──
  final GlobalKey<ThreeDSlotMachineState> _threeDKey =
      GlobalKey<ThreeDSlotMachineState>();
  final Set<int> _reelsStoppedSet = {};
  Completer<void>? _lastReelStoppedCompleter;

  // ── Constants ──
  static const double _reelVisibleHeight = 192.0;
  static const double _symbolCellH = _reelVisibleHeight / 3.0;

  static const List<int> _betTiers = [
    1, 2, 3, 5, 10, 25, 50, 100, 200, 500,
    1000, 2000, 5000, 10000, 25000, 50000, 100000,
  ];

  static const List<_SlotSymbol> _symbols = [
    _SlotSymbol('💰', 'Coins', Color(0xFFFFD700)),
    _SlotSymbol('⚔️', 'Attack', Color(0xFFFF1744)),
    _SlotSymbol('🐷', 'Raid', Color(0xFFFF6D00)),
    _SlotSymbol('🛡️', 'Shield', Color(0xFF00E5FF)),
    _SlotSymbol('⚡', 'Energy', Color(0xFFFFEA00)),
    _SlotSymbol('🎰', 'Bonus', Color(0xFFE040FB)),
  ];

  // ══════════════════════ LIFECYCLE ══════════════════════

  @override
  void initState() {
    super.initState();

    _reelMasterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..addListener(_updateReels);

    AudioManager.instance.init();

    _winEffectCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _winType = '');
      });

    _spinBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _spinBtnScale = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _spinBtnCtrl, curve: Curves.easeInOut),
    );

    _loadPlayerState();
  }

  @override
  void dispose() {
    _reelMasterCtrl.dispose();
    _winEffectCtrl.dispose();
    _spinBtnCtrl.dispose();
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

  // ══════════════════════ REEL ANIMATION ══════════════════════

  void _updateReels() {
    final t = _reelMasterCtrl.value;
    setState(() {
      for (int i = 0; i < 3; i++) {
        final speed = 22.0 + i * 5.0;

        if (!_reelTargetsSet) {
          // API hasn't returned — keep spinning
          _reelScrollPos[i] = t * speed + i * 2.3;
          _reelStopped[i] = false;
          continue;
        }

        final decelBegin = 0.38 + i * 0.14; // 0.38, 0.52, 0.66
        final decelEnd = decelBegin + 0.26; // 0.64, 0.78, 0.92

        if (t <= decelBegin) {
          // Full-speed phase
          _reelScrollPos[i] = t * speed + i * 2.3;
          _reelStopped[i] = false;
          // Pre-compute deceleration endpoints continuously
          _reelDecelStart[i] = _reelScrollPos[i];
          _computeDecelEnd(i);
        } else if (t <= decelEnd) {
          // Deceleration phase — ease-out to target
          final p = (t - decelBegin) / (decelEnd - decelBegin);
          final eased = Curves.easeOutCubic.transform(p);
          _reelScrollPos[i] = _reelDecelStart[i] +
              (_reelDecelEnd[i] - _reelDecelStart[i]) * eased;
          _reelStopped[i] = false;
        } else {
          // Stopped — play sound on first stop frame
          if (!_reelStopped[i]) {
            AudioManager.instance.playReelStop();
          }
          _reelScrollPos[i] = _reelDecelEnd[i];
          _reelStopped[i] = true;
        }
      }
    });
  }

  void _computeDecelEnd(int i) {
    final pos = _reelDecelStart[i];
    final n = _symbols.length.toDouble();
    final currentMod = pos % n;
    var extra = (_reelFinalIndex[i].toDouble() - currentMod) % n;
    if (extra < 3) extra += n; // ensure at least one more revolution
    _reelDecelEnd[i] = pos + extra;
  }

  // Callback from 3D scene when a reel finishes its deceleration
  void _onThreeDReelStopped(int reelIndex) {
    AudioManager.instance.playReelStop();
    _reelsStoppedSet.add(reelIndex);
    if (_reelsStoppedSet.length >= 3 &&
        _lastReelStoppedCompleter != null &&
        !_lastReelStoppedCompleter!.isCompleted) {
      _lastReelStoppedCompleter!.complete();
    }
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

  // ══════════════════════ SPIN LOGIC ══════════════════════

  Future<void> _doSpin() async {
    if (_isSpinning) return;
    final bet = ref.read(betMultiplierProvider);
    final gameState = ref.read(gameStateProvider);

    if (gameState.spins < bet) {
      // Not enough spins — flash effect, no toast
      setState(() {
        _winType = 'no_spins';
        _winAmount = 0;
      });
      _winEffectCtrl.reset();
      _winEffectCtrl.forward();
      return;
    }

    setState(() {
      _isSpinning = true;
      _pendingAction = null;
      _lastResult = null;
      _winType = '';
      _reelTargetsSet = false;
      _reelStopped[0] = false;
      _reelStopped[1] = false;
      _reelStopped[2] = false;
    });

    _reelMasterCtrl.reset();
    _reelMasterCtrl.forward();
    _reelsStoppedSet.clear();
    _lastReelStoppedCompleter = Completer<void>();
    _threeDKey.currentState?.startSpin(); // drive 3D reels
    AudioManager.instance.playSpinStart();

    // API call runs while reels spin
    final result = await ref.read(spinProvider.notifier).spin(bet);

    if (result == null) {
      _reelMasterCtrl.stop();
      setState(() => _isSpinning = false);
      return;
    }

    // Set target symbols — animation deceleration will land on these
    final s1 = _symbolIndexForSlot(result.slot1);
    final s2 = _symbolIndexForSlot(result.slot2);
    final s3 = _symbolIndexForSlot(result.slot3);
    _reelFinalIndex[0] = s1;
    _reelFinalIndex[1] = s2;
    _reelFinalIndex[2] = s3;

    // Drive 3D reels to land on the same symbols
    _threeDKey.currentState?.stopReels(s1, s2, s3);

    // If Flutter animation was slow and progressed too far, restart
    if (_reelMasterCtrl.value > 0.32) {
      final savedPos = List<double>.from(_reelScrollPos);
      _reelMasterCtrl.reset();
      for (int i = 0; i < 3; i++) {
        _reelScrollPos[i] = savedPos[i];
      }
      _reelMasterCtrl.forward();
    }
    _reelTargetsSet = true;

    // Wait for all 3 reels to stop — either via 3D callback or animation completion
    final remainingT = 1.0 - _reelMasterCtrl.value;
    final flutterWaitMs = (3800 * remainingT).toInt() + 250;
    final waitFuture = _lastReelStoppedCompleter?.future ?? Future<void>.value();
    await Future.any([
      waitFuture,
      Future<void>.delayed(Duration(milliseconds: flutterWaitMs)),
    ]);

    if (!mounted) return;

    setState(() {
      _lastResult = result;
      _pendingAction = result.specialAction;
      _isSpinning = false;
    });

    ref.read(gameStateProvider.notifier).applySpinResult(
          result.currentCoins, result.spinsRemaining);

    _showResultEffect(result);
  }

  void _showResultEffect(SpinResultModel result) {
    // Check specialAction FIRST so 3-attack / 3-raid / 3-shield jackpots
    // show the correct effect instead of a generic "JACKPOT!" overlay.
    if (result.specialAction == 'attack') {
      _winType = 'attack';
      _winAmount = result.coinsEarned;
      ref.read(gameStateProvider.notifier).setPendingAttack();
      AudioManager.instance.playAttack();
      if (result.isJackpot) {
        Vibration.hasVibrator().then((v) {
          if (v == true) Vibration.vibrate(duration: 500);
        });
      }
    } else if (result.specialAction == 'raid') {
      _winType = 'raid';
      _winAmount = result.coinsEarned;
      ref.read(gameStateProvider.notifier).setPendingRaid();
      AudioManager.instance.playRaid();
      if (result.isJackpot) {
        Vibration.hasVibrator().then((v) {
          if (v == true) Vibration.vibrate(duration: 500);
        });
      }
    } else if (result.specialAction == 'shield') {
      _winType = 'shield';
      _winAmount = 0;
      ref.read(gameStateProvider.notifier).addShield();
      AudioManager.instance.playShield();
    } else if (result.specialAction == 'energy') {
      _winType = 'energy';
      _winAmount = result.spinsEarned;
      AudioManager.instance.playEnergy();
    } else if (result.isJackpot) {
      _winType = 'jackpot';
      _winAmount = result.coinsEarned;
      AudioManager.instance.playJackpot();
      Vibration.hasVibrator().then((v) {
        if (v == true) Vibration.vibrate(duration: 500);
      });
    } else if (result.coinsEarned > 0) {
      _winType = 'coins';
      _winAmount = result.coinsEarned;
      AudioManager.instance.playCoinWin();
    } else {
      return;
    }

    setState(() {});
    _winEffectCtrl.reset();
    _winEffectCtrl.forward();
  }

  // ══════════════════════ BUILD ══════════════════════

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);
    final ps = ref.watch(playerStateProvider);
    final bet = ref.watch(betMultiplierProvider);
    final playerName = ps.valueOrNull?.user.displayName ?? 'Player';
    final gems = ps.valueOrNull?.user.gems ?? 0;
    final stars = ps.valueOrNull?.user.totalStars ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF81D4FA), // sky blue
              Color(0xFF4FC3F7),
              Color(0xFFB3E5FC),
              Color(0xFFFFF8E1), // cloudy cream at bottom
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopHUD(gs.coins, gems, stars, gs.shields),
              Expanded(
                child: Stack(
                  children: [
                    // Background clouds
                    _buildClouds(),

                    // Center column: logo + progress + 3D slot + boost + bet
                    Positioned.fill(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 68),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            CMLogoCard(
                              playerName: playerName,
                              coinAmount: _formatNumber(gs.coins),
                              winMultiplier: bet > 1 ? 'x$bet' : null,
                              onTap: () => context.push('/profile'),
                            ),
                            const SizedBox(height: 6),
                            _buildProgressBars(bet),
                            const SizedBox(height: 4),
                            _build3DSlotMachine(),
                            const SizedBox(height: 4),
                            CMPowerBoostBanner(multiplier: bet),
                            const SizedBox(height: 4),
                            _buildBetSelector(bet),
                            const SizedBox(height: 4),
                            _buildSpinCountPill(gs.spins),
                            if (_pendingAction != null) _buildPendingAction(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Left rail (vertically arranged timed buttons)
                    Positioned(
                      left: 4,
                      top: 4,
                      bottom: 12,
                      child: SingleChildScrollView(
                        child: _buildLeftRail(),
                      ),
                    ),

                    // Right rail
                    Positioned(
                      right: 4,
                      top: 4,
                      bottom: 12,
                      child: SingleChildScrollView(
                        child: _buildRightRail(),
                      ),
                    ),

                    // Win effect overlay (full-area)
                    if (_winType.isNotEmpty)
                      Positioned.fill(child: _buildWinEffectOverlay()),
                  ],
                ),
              ),
              // Bottom row: corner badge + pet + SPIN + bonus + corner badge
              _buildBottomRow(gs.spins, bet),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════ TOP HUD ══════════════════════

  Widget _buildTopHUD(int coins, int gems, int stars, int shields) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          CMCounterPill(
            leadingIcon: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF176), Color(0xFFF9A825)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x66000000), blurRadius: 2),
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
            value: _formatCoins(coins),
            background: const Color(0xFF6A1B9A),
            borderColor: const Color(0xFFFFD700),
            maxWidth: 140,
            onPlus: () => context.push('/chests'),
          ),
          const SizedBox(width: 4),
          CMCounterPill(
            leadingIcon: const Text('💎', style: TextStyle(fontSize: 16)),
            value: _formatCompact(gems),
            background: const Color(0xFFC2185B),
            borderColor: const Color(0xFFFFD700),
            maxWidth: 80,
            onPlus: () => context.push('/chests'),
          ),
          const Spacer(),
          // Star / total stars badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 3),
                Text(
                  _formatCompact(stars),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Shields X/5
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🛡️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 3),
                Text(
                  '$shields/3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Menu button
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFD50000)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ CLOUDS BACKGROUND ══════════════════════

  Widget _buildClouds() {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: 30, left: 80, child: Text('☁️', style: TextStyle(fontSize: 28))),
          Positioned(top: 260, left: 40, child: Text('☁️', style: TextStyle(fontSize: 20))),
          Positioned(bottom: 40, left: 60, child: Text('☁️', style: TextStyle(fontSize: 30))),
          Positioned(bottom: 80, right: 50, child: Text('☁️', style: TextStyle(fontSize: 24))),
          Positioned(top: 100, right: 60, child: Text('☁️', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  // ══════════════════════ PROGRESS BARS ══════════════════════

  Widget _buildProgressBars(int bet) {
    // Chest progress (deterministic demo values from current bet)
    final chestCurrent = (bet * 3).clamp(0, 40);
    // XP bar — scaled by current coins count to feel dynamic
    final xpTarget = 10000;
    final xpCurrent = ((ref.read(gameStateProvider).coins % xpTarget)).toInt();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CMProgressBar(
          leftIcon: '🎁',
          current: chestCurrent,
          max: 40,
          fillGradient: const [Color(0xFF4FC3F7), Color(0xFF0288D1)],
          background: const Color(0xFF4A148C),
          centerLabel: '$chestCurrent / 40',
        ),
        const SizedBox(height: 4),
        CMProgressBar(
          leftIcon: '🔥',
          current: xpCurrent,
          max: xpTarget,
          rightLabel: '20K',
          fillGradient: const [Color(0xFFFF8A65), Color(0xFFFF5252)],
          background: const Color(0xFF4A148C),
        ),
      ],
    );
  }

  // ══════════════════════ SPIN COUNT PILL ══════════════════════

  Widget _buildSpinCountPill(int spins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF00796B)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$spins/${spins > 180 ? spins : 180}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              shadows: [
                Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
          Text(
            '+${_formatNumber(spins)} spins',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ LEFT RAIL ══════════════════════

  Widget _buildLeftRail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CMRailIcon(emoji: '🎁', accent: const Color(0xFFFFB300),
            onTap: () => context.push('/chests')),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '👑', timer: '00:54:06', accent: const Color(0xFFFFD700)),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '✌️', timer: '00:54:06', accent: const Color(0xFFE91E63)),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '🎯', timer: '21:54:06', accent: const Color(0xFFFF6D00),
            onTap: () => context.push('/events')),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '🐷', timer: '21:54:06', accent: const Color(0xFFE91E63)),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '⬆️', badge: '2', accent: const Color(0xFFFFD700)),
      ],
    );
  }

  // ══════════════════════ RIGHT RAIL ══════════════════════

  Widget _buildRightRail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CMRailIcon(emoji: '🧪', accent: const Color(0xFF7B2FBE),
            onTap: () => context.push('/pets')),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '🗿', timer: '17:54:07', accent: const Color(0xFFFF8F00)),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '🧱', timer: '21:50:05', accent: const Color(0xFF8D6E63),
            onTap: () => context.push('/village')),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '🌿', badge: '5', timer: '45:54:05',
            accent: const Color(0xFF66BB6A)),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '🏰', accent: const Color(0xFF7B2FBE),
            onTap: () => context.push('/village-map')),
        const SizedBox(height: 8),
        CMRailIcon(emoji: '👥', badge: '1', accent: const Color(0xFFFFD700),
            onTap: () => context.push('/friends')),
      ],
    );
  }

  // ══════════════════════ BOTTOM ROW ══════════════════════

  Widget _buildBottomRow(int spins, int bet) {
    final canSpin = !_isSpinning && spins >= bet;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Corner: potion/inventory
          CMCornerBadge(
            emoji: '🧪',
            badge: 2,
            onTap: () => context.push('/pets'),
          ),
          const SizedBox(width: 4),
          // Pet character
          CMPetCharacter(
            emoji: '🦊',
            levelBadge: 'LV 1',
            onTap: () => context.push('/pets'),
          ),
          // SPIN button centered
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildSpinButtonCM(spins, bet, canSpin),
            ),
          ),
          // Bonus wheel
          const CMBonusWheel(),
          const SizedBox(width: 4),
          // Corner: clan/shield
          CMCornerBadge(
            emoji: '🛡️',
            badge: 7,
            accent: const Color(0xFF00E5FF),
            onTap: () => context.push('/clans'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ COIN MASTER-STYLE SPIN BUTTON ══════════════════════

  Widget _buildSpinButtonCM(int spins, int bet, bool canSpin) {
    return GestureDetector(
      onTapDown: canSpin
          ? (_) {
              _spinBtnCtrl.forward();
              AudioManager.instance.playButtonTap();
            }
          : null,
      onTapUp: canSpin
          ? (_) {
              _spinBtnCtrl.reverse();
              _doSpin();
            }
          : null,
      onTapCancel: () => _spinBtnCtrl.reverse(),
      child: ScaleTransition(
        scale: _spinBtnScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: canSpin
                      ? const [
                          Color(0xFFFF7043),
                          Color(0xFFE53935),
                          Color(0xFFB71C1C),
                        ]
                      : [Colors.grey.shade500, Colors.grey.shade700],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: canSpin ? const Color(0xFFFFD54F) : Colors.grey.shade600,
                  width: 3,
                ),
                boxShadow: canSpin
                    ? const [
                        BoxShadow(
                            color: Color(0x88B71C1C),
                            blurRadius: 14,
                            offset: Offset(0, 5)),
                        BoxShadow(
                            color: Color(0x44FFD700),
                            blurRadius: 10,
                            spreadRadius: 1),
                      ]
                    : null,
              ),
              child: Center(
                child: _isSpinning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                      )
                    : Text(
                        canSpin ? 'SPIN' : 'NO SPINS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                                color: Color(0xAA5D0000),
                                offset: Offset(2, 2),
                                blurRadius: 4),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Hold for AutoSpin',
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══ (LEGACY _buildTopHUD removed — replaced by Coin Master-style HUD above) ═══


  // ══════════════════════ VILLAGE SCENE (legacy) ══════════════════════

  // ignore: unused_element
  Widget _buildVillageScene(String villageName, int villageNum) {
    return GestureDetector(
      onTap: () => context.push('/village'),
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012) // 3D perspective
          ..rotateX(0.08), // slight tilt forward
        child: Container(
      height: 175,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFF81D4FA), Color(0xFF4CAF50)],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Clouds
          const Positioned(
              top: 12,
              left: 20,
              child: Text('☁️', style: TextStyle(fontSize: 28))),
          const Positioned(
              top: 8,
              right: 40,
              child: Text('☁️', style: TextStyle(fontSize: 22))),
          const Positioned(
              top: 30,
              right: 90,
              child: Text('☁️', style: TextStyle(fontSize: 18))),
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
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
            ),
          ),
          // Buildings
          const Positioned(
              bottom: 25,
              left: 20,
              child: Text('🏠', style: TextStyle(fontSize: 38))),
          const Positioned(
              bottom: 30,
              left: 90,
              child: Text('🏰', style: TextStyle(fontSize: 52))),
          const Positioned(
              bottom: 25,
              right: 60,
              child: Text('⛪', style: TextStyle(fontSize: 36))),
          const Positioned(
              bottom: 25,
              right: 10,
              child: Text('🏗️', style: TextStyle(fontSize: 32))),
          const Positioned(
              bottom: 22,
              left: 170,
              child: Text('🌳', style: TextStyle(fontSize: 28))),
          // Village label
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
          // Build badge
          Positioned(
            bottom: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFF9A825)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x44000000), blurRadius: 4),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔨', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text('BUILD',
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1,
                      )),
                ],
              ),
            ),
          ),
          // Navigation arrows
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
    ), // end Container
    ), // end Transform
    ); // end GestureDetector
  }

  // ══════════════════════ SLOT AREA (legacy — replaced by Coin Master layout) ══════════════════════

  // ignore: unused_element
  Widget _buildSlotArea(int bet, int spins) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              _build3DSlotMachine(),
              const SizedBox(height: 10),
              _buildBetSelector(bet),
              const SizedBox(height: 10),
              _buildSpinButton(spins, bet),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_formatNumber(spins)} spins',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          // Win effect overlay
          if (_winType.isNotEmpty) _buildWinEffectOverlay(),
        ],
      ),
    );
  }

  // ── Gold frame + dark interior ──
  // ── 3D slot machine (Three.js WebView) wrapped in a gold outer frame ──
  Widget _build3DSlotMachine() {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE082),
            Color(0xFFFFC107),
            Color(0xFFFF8F00),
            Color(0xFFFFC107),
            Color(0xFFFFE082),
          ],
          stops: [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6)),
          BoxShadow(
              color: Color(0x44FFD700), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ThreeDSlotMachine(
          key: _threeDKey,
          onReelStopped: _onThreeDReelStopped,
        ),
      ),
    );
  }

  // ── (Legacy) Flutter slot frame — kept for fallback reference ──
  // ignore: unused_element
  Widget _buildSlotFrame() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0008) // 3D perspective depth
        ..rotateX(-0.02), // very slight tilt back for depth
      child: Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE082),
            Color(0xFFFFC107),
            Color(0xFFFF8F00),
            Color(0xFFFFC107),
            Color(0xFFFFE082),
          ],
          stops: [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6)),
          BoxShadow(
              color: Color(0x44FFD700), blurRadius: 24, spreadRadius: 2),
          // 3D depth shadow
          BoxShadow(
              color: Color(0x55000000), blurRadius: 30, offset: Offset(0, 16), spreadRadius: -4),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1C0A40), Color(0xFF100828), Color(0xFF0A0518)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            // Title bar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0x00FFD700),
                    Color(0x66FFD700),
                    Color(0x00FFD700)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'SPIN EMPIRE',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: Color(0xAAFF8F00), blurRadius: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 3 Reels with pay-line indicators
            _buildReelRow(),
          ],
        ),
      ),
    ), // end Transform
    );
  }

  // ── Reel row with pay-line arrows ──
  Widget _buildReelRow() {
    return SizedBox(
      height: _reelVisibleHeight,
      child: Row(
        children: [
          // Left pay-line arrow
          _buildPayLineArrow(true),
          const SizedBox(width: 3),
          // 3 Reels
          Expanded(child: _buildReel(0)),
          const SizedBox(width: 5),
          Expanded(child: _buildReel(1)),
          const SizedBox(width: 5),
          Expanded(child: _buildReel(2)),
          const SizedBox(width: 3),
          // Right pay-line arrow
          _buildPayLineArrow(false),
        ],
      ),
    );
  }

  Widget _buildPayLineArrow(bool isLeft) {
    return SizedBox(
      width: 14,
      height: _reelVisibleHeight,
      child: Center(
        child: Container(
          width: 14,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
            ),
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(3) : const Radius.circular(8),
              right: isLeft ? const Radius.circular(8) : const Radius.circular(3),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x66FFD700), blurRadius: 6),
            ],
          ),
          child: Icon(
            isLeft ? Icons.play_arrow : Icons.play_arrow,
            size: 12,
            color: const Color(0xFF5D4037),
          ),
        ),
      ),
    );
  }

  // ══════════════════════ INDIVIDUAL REEL ══════════════════════

  Widget _buildReel(int idx) {
    final stopped = _reelStopped[idx] && !_isSpinning;
    final isJackpotReel =
        stopped && _lastResult != null && _lastResult!.isJackpot;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0520),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isJackpotReel
              ? const Color(0xFFFFD700)
              : const Color(0xFF3D1B6F),
          width: isJackpotReel ? 2.5 : 1.5,
        ),
        boxShadow: isJackpotReel
            ? const [BoxShadow(color: Color(0x99FFD700), blurRadius: 16)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          children: [
            // Symbol strip
            stopped ? _buildStoppedReel(idx) : _buildScrollingReel(idx),
            // Vignette gradient (depth effect)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0A0520).withAlpha(200),
                        Colors.transparent,
                        Colors.transparent,
                        const Color(0xFF0A0520).withAlpha(200),
                      ],
                      stops: const [0.0, 0.22, 0.78, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Center row highlight (pay line)
            Positioned(
              top: _symbolCellH - 1,
              left: 0,
              right: 0,
              child: Container(
                height: _symbolCellH + 2,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: const Color(0xFFFFD700).withAlpha(100),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Scrolling reel (during spin) ──
  Widget _buildScrollingReel(int idx) {
    final scroll = _reelScrollPos[idx];
    final baseIdx = scroll.floor();
    final frac = scroll - baseIdx.toDouble();
    final n = _symbols.length;

    return SizedBox(
      height: _reelVisibleHeight,
      child: Stack(
        children: List.generate(5, (row) {
          // row 0..4, center is row 2 when frac=0
          final offset = row - 2;
          final symIdx = ((baseIdx + offset) % n + n) % n;
          final y = (offset + 1 - frac) * _symbolCellH;
          final isCenter = (row == 2 && frac < 0.3) || (row == 1 && frac > 0.7);

          return Positioned(
            top: y,
            left: 0,
            right: 0,
            height: _symbolCellH,
            child: Center(
              child: Text(
                _symbols[symIdx].emoji,
                style: TextStyle(
                  fontSize: isCenter ? 42 : 34,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Stopped reel (shows result) ──
  Widget _buildStoppedReel(int idx) {
    final targetIdx = _reelFinalIndex[idx];
    final n = _symbols.length;

    return SizedBox(
      height: _reelVisibleHeight,
      child: Column(
        children: [
          // Top symbol (above result)
          SizedBox(
            height: _symbolCellH,
            child: Center(
              child: Opacity(
                opacity: 0.35,
                child: Text(
                  _symbols[(targetIdx - 1 + n) % n].emoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
          // Center symbol — THE RESULT
          SizedBox(
            height: _symbolCellH,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.3, end: 1.0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                builder: (ctx, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(
                  _symbols[targetIdx].emoji,
                  style: const TextStyle(fontSize: 46),
                ),
              ),
            ),
          ),
          // Bottom symbol (below result)
          SizedBox(
            height: _symbolCellH,
            child: Center(
              child: Opacity(
                opacity: 0.35,
                child: Text(
                  _symbols[(targetIdx + 1) % n].emoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ BET SELECTOR ══════════════════════

  Widget _buildBetSelector(int bet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrease bet
        GestureDetector(
          onTap: () {
            final idx = _betTiers.indexOf(bet);
            if (idx > 0) {
              ref.read(betMultiplierProvider.notifier).state =
                  _betTiers[idx - 1];
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: const Icon(Icons.remove, color: Colors.white, size: 22),
          ),
        ),
        // Bet display
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x44FFD700), blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BET',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              Text(
                _formatBet(bet),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        // Increase bet
        GestureDetector(
          onTap: () {
            final idx = _betTiers.indexOf(bet);
            if (idx < _betTiers.length - 1) {
              ref.read(betMultiplierProvider.notifier).state =
                  _betTiers[idx + 1];
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  // ══════════════════════ SPIN BUTTON (Green — Coin Master style) ══════════════════════

  Widget _buildSpinButton(int spins, int bet) {
    final canSpin = !_isSpinning && spins >= bet;
    return GestureDetector(
      onTapDown: canSpin
          ? (_) {
              _spinBtnCtrl.forward();
              AudioManager.instance.playButtonTap();
            }
          : null,
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
          height: 62,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: canSpin
                  ? const [
                      Color(0xFF66BB6A),
                      Color(0xFF43A047),
                      Color(0xFF2E7D32)
                    ]
                  : [Colors.grey.shade600, Colors.grey.shade700],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: canSpin ? const Color(0xFFFFD54F) : Colors.grey.shade500,
              width: 3,
            ),
            boxShadow: canSpin
                ? const [
                    BoxShadow(
                      color: Color(0x8843A047),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0x44FFD700),
                      blurRadius: 12,
                      spreadRadius: 1,
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
                    canSpin ? 'SPIN' : 'NO SPINS',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: canSpin
                          ? const [
                              Shadow(
                                  color: Color(0x882E7D32),
                                  offset: Offset(2, 2),
                                  blurRadius: 6),
                            ]
                          : null,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════ WIN EFFECT OVERLAY ══════════════════════

  Widget _buildWinEffectOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _winEffectCtrl,
        builder: (context, _) {
          final v = _winEffectCtrl.value;
          if (v == 0) return const SizedBox.shrink();

          // Scale: elastic bounce in, stay
          final scaleT = v < 0.25
              ? Curves.elasticOut.transform((v / 0.25).clamp(0.0, 1.0))
              : 1.0;
          // Opacity: full during show, fade out at end
          final opacity =
              v > 0.75 ? ((1.0 - v) / 0.25).clamp(0.0, 1.0) : 1.0;

          return IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scaleT.clamp(0.5, 1.5),
                child: _buildWinContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWinContent() {
    switch (_winType) {
      case 'jackpot':
        return _winPanel(
          icon: '🎰',
          iconSize: 56,
          title: 'JACKPOT!',
          titleColor: const Color(0xFFFFD700),
          subtitle: '+${_formatNumber(_winAmount)}',
          subtitleColor: Colors.white,
          glowColor: const Color(0xFFFFD700),
        );
      case 'coins':
        return _winPanel(
          icon: '💰',
          iconSize: 50,
          title: '+${_formatNumber(_winAmount)}',
          titleColor: const Color(0xFFFFD700),
          subtitle: '',
          subtitleColor: Colors.transparent,
          glowColor: const Color(0xFFFFAB00),
        );
      case 'attack':
        return _winPanel(
          icon: '⚔️',
          iconSize: 54,
          title: 'ATTACK!',
          titleColor: const Color(0xFFFF1744),
          subtitle: 'Choose a target',
          subtitleColor: Colors.white70,
          glowColor: const Color(0xFFFF1744),
        );
      case 'raid':
        return _winPanel(
          icon: '🐷',
          iconSize: 54,
          title: 'RAID!',
          titleColor: const Color(0xFFFF6D00),
          subtitle: 'Pick someone to raid',
          subtitleColor: Colors.white70,
          glowColor: const Color(0xFFFF6D00),
        );
      case 'shield':
        return _winPanel(
          icon: '🛡️',
          iconSize: 50,
          title: 'SHIELD!',
          titleColor: const Color(0xFF00E5FF),
          subtitle: 'Protected',
          subtitleColor: Colors.white70,
          glowColor: const Color(0xFF00E5FF),
        );
      case 'energy':
        return _winPanel(
          icon: '⚡',
          iconSize: 50,
          title: '+$_winAmount SPINS',
          titleColor: const Color(0xFFFFEA00),
          subtitle: '',
          subtitleColor: Colors.transparent,
          glowColor: const Color(0xFFFFEA00),
        );
      case 'no_spins':
        return _winPanel(
          icon: '😢',
          iconSize: 44,
          title: 'Not enough spins!',
          titleColor: const Color(0xFFFF5252),
          subtitle: '',
          subtitleColor: Colors.transparent,
          glowColor: const Color(0xFFFF5252),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _winPanel({
    required String icon,
    required double iconSize,
    required String title,
    required Color titleColor,
    required String subtitle,
    required Color subtitleColor,
    required Color glowColor,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xDD1A0A3E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: glowColor.withAlpha(180), width: 2),
          boxShadow: [
            BoxShadow(color: glowColor.withAlpha(120), blurRadius: 32, spreadRadius: 4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: iconSize)),
            if (title.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: glowColor.withAlpha(180), blurRadius: 16),
                    const Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 2),
                        blurRadius: 4),
                  ],
                ),
              ),
            ],
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════ PENDING ACTION ══════════════════════

  Widget _buildPendingAction() {
    final isAttack = _pendingAction == 'attack';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C0A40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAttack ? AppColors.crimson : AppColors.gold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isAttack ? AppColors.crimson : AppColors.gold).withAlpha(60),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(isAttack ? '⚔️' : '🐷',
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAttack
                  ? 'Attack ready! Choose a target.'
                  : 'Raid ready! Choose a target.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final action = _pendingAction;
              setState(() => _pendingAction = null);
              // Auto-navigate to attack/raid screen with random public target
              if (action == 'attack') {
                context.push('/attack');
              } else if (action == 'raid') {
                context.push('/raid');
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  color:
                      isAttack ? Colors.white : const Color(0xFF5D4037),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ BOTTOM NAV (legacy — kept for reference) ══════════════════════

  // ignore: unused_element
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B2FBE), Color(0xFF4A148C)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black38, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem('🎁', 'Rewards', '/events'),
              _navItem('⚔️', 'Attack', '/friends'),
              _navItem('🃏', 'Cards', '/cards'),
              _navItem('🐾', 'Pets', '/pets'),
              _navItem('🏆', 'Rank', '/leaderboard'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String emoji, String label, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ HELPERS ══════════════════════

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

  String _formatCompact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatNumber(int n) {
    return NumberFormat('#,###').format(n);
  }

  String _formatBet(int bet) {
    if (bet >= 1000) {
      final k = bet ~/ 1000;
      return 'x${k}K';
    }
    return 'x$bet';
  }
}

class _SlotSymbol {
  final String emoji;
  final String name;
  final Color color;
  const _SlotSymbol(this.emoji, this.name, this.color);
}
