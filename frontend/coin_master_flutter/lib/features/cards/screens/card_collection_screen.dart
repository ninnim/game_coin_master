import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/card_provider.dart';
import '../../../core/models/card_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class CardCollectionScreen extends ConsumerStatefulWidget {
  const CardCollectionScreen({super.key});

  @override
  ConsumerState<CardCollectionScreen> createState() =>
      _CardCollectionScreenState();
}

class _CardCollectionScreenState extends ConsumerState<CardCollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardSetsAsync = ref.watch(cardSetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '🃏 Card Collection',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/game'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/chests'),
            child: const Text(
              'Open Chests',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderGlow),
        ),
      ),
      body: cardSetsAsync.when(
        loading: () => const SkeletonList(itemCount: 4, itemHeight: 120),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.crimson,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text('Failed to load cards', style: AppTextStyles.body),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(cardSetsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.background),
                ),
              ),
            ],
          ),
        ),
        data: (sets) {
          if (sets.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.style,
              title: 'No Cards Yet',
              message: 'Open chests to start collecting cards!',
              actionLabel: 'Open Chests',
              onAction: () => context.push('/chests'),
            );
          }
          return DefaultTabController(
            length: sets.length,
            child: Column(
              children: [
                Container(
                  color: AppColors.surface,
                  child: TabBar(
                    isScrollable: true,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.gold,
                    tabs: sets
                        .map(
                          (s) => Tab(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s.name),
                                Text(
                                  '${s.ownedCount}/${s.totalCount}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: sets
                        .map((s) => _CardSetView(cardSet: s))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardSetView extends StatelessWidget {
  final CardSetModel cardSet;

  const _CardSetView({required this.cardSet});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cardSet.name, style: AppTextStyles.subtitle),
                    if (cardSet.isComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.emerald),
                        ),
                        child: const Text(
                          '✅ COMPLETE',
                          style: TextStyle(
                            color: AppColors.emerald,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: cardSet.totalCount > 0
                      ? cardSet.ownedCount / cardSet.totalCount
                      : 0,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cardSet.ownedCount} / ${cardSet.totalCount} cards',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
        // Cards grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: cardSet.cards.length,
            itemBuilder: (context, index) {
              final card = cardSet.cards[index];
              return _CardTile(card: card);
            },
          ),
        ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardModel card;

  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.rarityColor(card.rarity);
    final cardEmojis = ['⚔️', '🛡️', '🏰', '🐉', '👑', '⭐', '💎', '🔮', '🗡️', '🏹', '🦅', '🌙'];
    final emoji = cardEmojis[card.name.length % cardEmojis.length];

    return Container(
      decoration: BoxDecoration(
        color: card.isOwned ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card.isOwned ? rarityColor : AppColors.borderGlow.withOpacity(0.3),
          width: card.isOwned ? 2 : 1,
        ),
        boxShadow: card.isOwned
            ? [BoxShadow(color: rarityColor.withOpacity(0.2), blurRadius: 8)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Card image area
          Expanded(
            child: Center(
              child: card.isOwned
                  ? Text(emoji, style: const TextStyle(fontSize: 32))
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.borderGlow.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('?', style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                    ),
            ),
          ),
          // Card info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                Text(
                  card.isOwned ? card.name : '???',
                  style: TextStyle(
                    fontSize: 10,
                    color: card.isOwned ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (card.isOwned && card.quantity > 1)
                  Text(
                    'x${card.quantity}',
                    style: TextStyle(fontSize: 9, color: rarityColor),
                  ),
                // Rarity dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: card.isOwned ? rarityColor : AppColors.textSecondary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
