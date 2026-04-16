import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/village_provider.dart';
import '../../../core/models/village_model.dart';
import '../../../core/models/player_state_model.dart';
import '../../../features/game/providers/player_state_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../core/services/audio_manager.dart';

class VillageDetailScreen extends ConsumerStatefulWidget {
  const VillageDetailScreen({super.key});

  @override
  ConsumerState<VillageDetailScreen> createState() =>
      _VillageDetailScreenState();
}

class _VillageDetailScreenState extends ConsumerState<VillageDetailScreen> {
  UserBuildingModel? _selectedBuilding;
  bool _upgrading = false;

  // ── Building emoji lookup ──
  static const _emojiMap = <String, String>{
    'castle': '🏰',
    'house': '🏠',
    'church': '⛪',
    'tower': '🗼',
    'blacksmith': '⚒️',
    'farm': '🌾',
    'stable': '🐴',
    'tavern': '🍺',
    'wall': '🧱',
    'windmill': '🌀',
    'market': '🏪',
    'mine': '⛏️',
    'dock': '⚓',
    'temple': '🏛️',
    'barracks': '⚔️',
    'library': '📚',
    'fountain': '⛲',
    'gate': '🚪',
    'statue': '🗽',
    'garden': '🌳',
    'workshop': '🔧',
    'school': '🏫',
    'arena': '🏟️',
    'palace': '👑',
    'lab': '🔬',
    'shrine': '⛩️',
    'forge': '🔥',
    'prison': '🔒',
    'cannon': '💣',
    'portal': '🌀',
    'reactor': '⚡',
    'antenna': '📡',
    'dome': '🏗️',
    'capsule': '🚀',
    'obelisk': '🗿',
    'tree': '🌲',
    'hut': '🛖',
    'longhouse': '🏚️',
    'pyramid': '🔺',
    'sphinx': '🦁',
    'observatory': '🔭',
    'coral': '🪸',
    'igloo': '🏔️',
    'tent': '⛺',
    'crystal': '💎',
    'server': '🖥️',
  };

  String _emoji(String name, int level) {
    if (level == 0) return '🏗️';
    final key = name.toLowerCase().split(' ').first;
    return _emojiMap[key] ?? '🏠';
  }

  // ══════════════════════ BUILD ══════════════════════

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(playerStateProvider);

    return Scaffold(
      body: ps.when(
        loading: () => _buildShell(
          child: const Center(
              child: CircularProgressIndicator(color: AppColors.gold)),
        ),
        error: (e, _) => _buildShell(child: _buildError()),
        data: (data) => _buildContent(data),
      ),
    );
  }

  Widget _buildShell({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1565C0), Color(0xFF0D0620)],
        ),
      ),
      child: SafeArea(child: child),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😢', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Failed to load village',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(playerStateProvider),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Retry',
                style: TextStyle(color: Color(0xFF5D4037))),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ MAIN CONTENT ══════════════════════

  Widget _buildContent(PlayerStateModel ps) {
    final village = ps.currentVillage;
    final buildings = ps.buildings;
    final completedBuildings =
        buildings.where((b) => b.upgradeLevel >= 4 && !b.isDestroyed).length;
    final totalStars = buildings.fold<int>(
        0, (sum, b) => sum + (b.isDestroyed ? 0 : b.upgradeLevel));
    final maxStars = buildings.length * 4;

    Color skyColor;
    try {
      skyColor = Color(
          int.parse(village.skyColor.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      skyColor = const Color(0xFF1565C0);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            skyColor,
            skyColor.withAlpha(180),
            const Color(0xFF4CAF50),
            const Color(0xFF2E7D32),
            const Color(0xFF1A0A3E),
          ],
          stops: const [0.0, 0.22, 0.35, 0.40, 0.60],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Clouds
            const Positioned(
                top: 50,
                left: 30,
                child: Text('☁️', style: TextStyle(fontSize: 30))),
            const Positioned(
                top: 38,
                right: 50,
                child: Text('☁️', style: TextStyle(fontSize: 22))),
            const Positioned(
                top: 65,
                left: 170,
                child: Text('☁️', style: TextStyle(fontSize: 18))),

            // Main layout
            Column(
              children: [
                _buildTopBar(village),
                const SizedBox(height: 6),
                _buildProgressBar(
                    totalStars, maxStars, completedBuildings, buildings.length),
                const SizedBox(height: 8),
                // Building grid
                Expanded(
                  child: _buildBuildingGrid(buildings, ps.user.coins),
                ),
              ],
            ),

            // Upgrade panel overlay
            if (_selectedBuilding != null)
              _buildUpgradePanel(ps.user.coins),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──
  Widget _buildTopBar(VillageModel village) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/game'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  village.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                  ),
                ),
                Text(
                  'Village ${village.orderNum} — ${village.theme}'
                  '${village.isBoom ? ' 💥 BOOM!' : ''}',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Village map button
          GestureDetector(
            onTap: () => context.push('/village-map'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🗺️', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text('Map',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──
  Widget _buildProgressBar(
      int current, int max, int completed, int total) {
    final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed/$total buildings complete',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '⭐ $current/$max',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              borderRadius: BorderRadius.circular(5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFF9A825)],
                      ),
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

  // ══════════════════════ BUILDING GRID ══════════════════════

  Widget _buildBuildingGrid(List<UserBuildingModel> buildings, int coins) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: buildings.length,
        itemBuilder: (ctx, i) => _buildBuildingTile(buildings[i]),
      ),
    );
  }

  Widget _buildBuildingTile(UserBuildingModel b) {
    final isComplete = b.upgradeLevel >= 4;
    final isDestroyed = b.isDestroyed;
    final isSelected = _selectedBuilding?.buildingId == b.buildingId;
    final emoji = _emoji(b.buildingName, b.upgradeLevel);

    return GestureDetector(
      onTap: () => setState(() {
        _selectedBuilding =
            _selectedBuilding?.buildingId == b.buildingId ? null : b;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDestroyed
              ? const Color(0x33FF1744)
              : isSelected
                  ? const Color(0x44FFD700)
                  : const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestroyed
                ? const Color(0xFFFF1744)
                : isComplete
                    ? const Color(0xFFFFD700)
                    : isSelected
                        ? const Color(0xFFFFD54F)
                        : Colors.white24,
            width: (isComplete || isSelected) ? 2.5 : 1.5,
          ),
          boxShadow: isComplete
              ? const [
                  BoxShadow(color: Color(0x44FFD700), blurRadius: 12)
                ]
              : isSelected
                  ? const [
                      BoxShadow(color: Color(0x33FFD700), blurRadius: 8)
                    ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Building emoji
            Text(
              isDestroyed ? '💥' : emoji,
              style: TextStyle(fontSize: isComplete ? 42 : 36),
            ),
            const SizedBox(height: 4),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                b.buildingName,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color:
                      isDestroyed ? const Color(0xFFFF8A80) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Level dots (4 dots for 4 levels)
            if (!isDestroyed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (lvl) {
                  final filled = lvl < b.upgradeLevel;
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: filled
                          ? const Color(0xFFFFD700)
                          : Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: filled
                            ? const Color(0xFFFF8F00)
                            : Colors.white12,
                        width: 1,
                      ),
                    ),
                  );
                }),
              )
            else
              const Text(
                'DESTROYED',
                style: TextStyle(
                  color: Color(0xFFFF1744),
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════ UPGRADE PANEL ══════════════════════

  Widget _buildUpgradePanel(int coins) {
    final b = _selectedBuilding!;
    final isComplete = b.upgradeLevel >= 4;
    final isDestroyed = b.isDestroyed;
    final canAfford = b.canAfford && !isComplete && !isDestroyed;
    final emoji = _emoji(b.buildingName, b.upgradeLevel);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {}, // absorb taps so grid doesn't deselect
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1C0A40), Color(0xFF0D0620)],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
                color: const Color(0xFFFFD700).withAlpha(120), width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 20,
                  offset: Offset(0, -8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Building info
              Row(
                children: [
                  Text(isDestroyed ? '💥' : emoji,
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.buildingName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (isDestroyed)
                          const Text('💥 Destroyed by attack',
                              style: TextStyle(
                                  color: Color(0xFFFF8A80), fontSize: 13))
                        else if (isComplete)
                          const Text('⭐ Fully upgraded!',
                              style: TextStyle(
                                  color: Color(0xFFFFD54F), fontSize: 13))
                        else
                          Text(
                            'Level ${b.upgradeLevel} → ${b.upgradeLevel + 1}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // Upgrade section
              if (!isComplete && !isDestroyed) ...[
                const SizedBox(height: 14),
                // Cost
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upgrade cost:',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Row(
                        children: [
                          const Text('💰 ',
                              style: TextStyle(fontSize: 16)),
                          Text(
                            NumberFormat('#,###').format(b.nextUpgradeCost),
                            style: TextStyle(
                              color: canAfford
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFFF5252),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your coins: ${NumberFormat('#,###').format(coins)}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 12),
                // Upgrade button
                GestureDetector(
                  onTap: canAfford && !_upgrading ? _doUpgrade : null,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: canAfford
                            ? const [
                                Color(0xFFFFD54F),
                                Color(0xFFF9A825),
                                Color(0xFFFF8F00)
                              ]
                            : [Colors.grey.shade700, Colors.grey.shade800],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: canAfford
                            ? const Color(0xFFFFE082)
                            : Colors.grey.shade600,
                        width: 2,
                      ),
                      boxShadow: canAfford
                          ? const [
                              BoxShadow(
                                  color: Color(0x66FFD700), blurRadius: 16)
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _upgrading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Color(0xFF5D4037), strokeWidth: 3))
                          : Text(
                              canAfford ? 'UPGRADE' : 'NOT ENOUGH COINS',
                              style: TextStyle(
                                color: canAfford
                                    ? const Color(0xFF5D4037)
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _selectedBuilding = null),
                child: const Text('Close',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════ UPGRADE ACTION ══════════════════════

  Future<void> _doUpgrade() async {
    if (_upgrading || _selectedBuilding == null) return;
    setState(() => _upgrading = true);

    final success = await ref
        .read(upgradeBuildingProvider.notifier)
        .upgrade(_selectedBuilding!.buildingId);

    if (!mounted) return;

    if (success) {
      AudioManager.instance.playBuildUpgrade();

      // Check if village was just completed (all buildings at level 4)
      final freshState = await ref.refresh(playerStateProvider.future);
      final allDone = freshState.buildings
          .every((b) => b.upgradeLevel >= 4 && !b.isDestroyed);
      if (allDone) {
        AudioManager.instance.playVillageComplete();
        if (mounted) _showVillageCompleteDialog(freshState.currentVillage.name);
      }

      setState(() {
        _selectedBuilding = null;
        _upgrading = false;
      });
    } else {
      setState(() => _upgrading = false);
    }
  }

  void _showVillageCompleteDialog(String villageName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C0A40), Color(0xFF0D0620)],
            ),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: const Color(0xFFFFD700), width: 3),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66FFD700),
                  blurRadius: 30,
                  spreadRadius: 5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text(
                'VILLAGE COMPLETE!',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                villageName,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Moving to next village...',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.invalidate(playerStateProvider);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF66BB6A),
                        Color(0xFF43A047)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFFFFD54F), width: 2),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
