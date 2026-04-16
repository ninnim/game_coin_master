import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/social_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _types = ['coins', 'village', 'cards'];
  final List<String> _labels = ['Coins', 'Village', 'Cards'];
  final List<String> _emojis = ['🪙', '🏰', '🃏'];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '🏆 Leaderboard',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.gold,
          tabs: List.generate(
            3,
            (i) => Tab(text: '${_emojis[i]} ${_labels[i]}'),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _types
            .map((type) => _LeaderboardTab(type: type))
            .toList(),
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final String type;

  const _LeaderboardTab({required this.type});

  String _formatValue(int value, String type) {
    if (type == 'coins') return NumberFormat('#,###').format(value);
    return value.toString();
  }

  String _valueSuffix(String type) {
    switch (type) {
      case 'village': return ' village';
      case 'cards': return ' cards';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider(type));

    return leaderboardAsync.when(
      loading: () => const SkeletonList(itemCount: 10, itemHeight: 70),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.crimson, size: 48),
            const SizedBox(height: 12),
            const Text('Failed to load leaderboard', style: AppTextStyles.body),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(leaderboardProvider(type)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              child: const Text('Retry', style: TextStyle(color: AppColors.background)),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.leaderboard,
            title: 'No Rankings Yet',
            message: 'Start playing to appear on the leaderboard!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _LeaderboardTile(
              entry: entry,
              valueSuffix: _valueSuffix(type),
              formatValue: (v) => _formatValue(v, type),
            );
          },
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final String valueSuffix;
  final String Function(int) formatValue;

  const _LeaderboardTile({
    required this.entry,
    required this.valueSuffix,
    required this.formatValue,
  });

  Widget _rankWidget(int rank) {
    if (rank == 1) return const Text('🥇', style: TextStyle(fontSize: 24));
    if (rank == 2) return const Text('🥈', style: TextStyle(fontSize: 24));
    if (rank == 3) return const Text('🥉', style: TextStyle(fontSize: 24));
    return SizedBox(
      width: 32,
      child: Text(
        '#$rank',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderColor: entry.isCurrentUser
            ? AppColors.gold
            : entry.rank <= 3
                ? AppColors.gold.withOpacity(0.3)
                : AppColors.borderGlow,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 40, child: Center(child: _rankWidget(entry.rank))),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: entry.isCurrentUser
                  ? AppColors.gold.withOpacity(0.2)
                  : AppColors.surface,
              child: Text(
                entry.displayName.isNotEmpty
                    ? entry.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: entry.isCurrentUser ? AppColors.gold : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${entry.displayName}${entry.isCurrentUser ? " (You)" : ""}',
                style: TextStyle(
                  color: entry.isCurrentUser ? AppColors.gold : AppColors.textPrimary,
                  fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '${formatValue(entry.value)}$valueSuffix',
              style: TextStyle(
                color: entry.rank <= 3 ? AppColors.gold : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
