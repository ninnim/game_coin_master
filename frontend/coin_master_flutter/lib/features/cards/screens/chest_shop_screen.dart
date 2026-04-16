import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/card_provider.dart';
import '../../../core/models/card_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/toast_notification.dart';

class ChestShopScreen extends ConsumerStatefulWidget {
  const ChestShopScreen({super.key});

  @override
  ConsumerState<ChestShopScreen> createState() => _ChestShopScreenState();
}

class _ChestShopScreenState extends ConsumerState<ChestShopScreen> {
  List<CardModel>? _openedCards;
  bool _isOpening = false;

  static const List<Map<String, dynamic>> _chestTypes = [
    {
      'type': 'wooden',
      'name': 'Wooden Chest',
      'emoji': '📦',
      'price': 200,
      'currency': 'coins',
      'cards': '2–3 Common',
      'color': 0xFF8D6E63,
      'description': 'Basic chest with common cards.',
    },
    {
      'type': 'golden',
      'name': 'Golden Chest',
      'emoji': '🎁',
      'price': 600,
      'currency': 'coins',
      'cards': '4–5 Rare+',
      'color': 0xFFFFD700,
      'description': 'Better chance at rare cards!',
    },
    {
      'type': 'magical',
      'name': 'Magical Chest',
      'emoji': '💎',
      'price': 10,
      'currency': 'gems',
      'cards': '6–8 Epic+',
      'color': 0xFFAB47BC,
      'description': 'Epic and legendary cards guaranteed!',
    },
  ];

  Future<void> _openChest(String chestType) async {
    setState(() {
      _isOpening = true;
      _openedCards = null;
    });
    final cards = await ref
        .read(openChestProvider.notifier)
        .openChest(chestType);
    setState(() {
      _isOpening = false;
      _openedCards = cards.isNotEmpty ? cards : null;
    });
    if (cards.isEmpty && mounted) {
      showGameToast(context, 'Not enough coins/gems!', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '🎁 Chest Shop',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderGlow),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a Chest', style: AppTextStyles.title),
            const SizedBox(height: 4),
            const Text(
              'Open chests to discover new cards!',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 20),
            // Chest cards
            ...(_chestTypes.map(
              (chest) => _ChestCard(
                chest: chest,
                isOpening: _isOpening,
                onOpen: () => _openChest(chest['type'] as String),
              ),
            )),
            // Opened cards display
            if (_openedCards != null) ...[
              const SizedBox(height: 24),
              const Text('Cards Received!', style: AppTextStyles.title),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
                children: _openedCards!
                    .map(
                      (card) => _RevealedCard(card: card),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Center(
                child: GlassButton(
                  label: 'Awesome!',
                  onTap: () => setState(() => _openedCards = null),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ChestCard extends StatelessWidget {
  final Map<String, dynamic> chest;
  final bool isOpening;
  final VoidCallback onOpen;

  const _ChestCard({
    required this.chest,
    required this.isOpening,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(chest['color'] as int);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderColor: color.withOpacity(0.6),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Chest icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Center(
                child: Text(
                  chest['emoji'] as String,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chest['name'] as String, style: AppTextStyles.subtitle),
                  Text(
                    chest['description'] as String,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${chest["cards"]} cards',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Buy button
            Column(
              children: [
                Text(
                  '${chest["price"]} ${chest["currency"]}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                GlassButton(
                  label: 'Open',
                  color: color,
                  isLoading: isOpening,
                  onTap: isOpening ? null : onOpen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealedCard extends StatefulWidget {
  final CardModel card;
  const _RevealedCard({required this.card});

  @override
  State<_RevealedCard> createState() => _RevealedCardState();
}

class _RevealedCardState extends State<_RevealedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _flip;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flip = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _revealed = true);
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.rarityColor(widget.card.rarity);
    final cardEmojis = ['⚔️', '🛡️', '🏰', '🐉', '👑', '⭐', '💎', '🔮', '🗡️', '🏹', '🦅', '🌙'];
    final emoji = cardEmojis[widget.card.name.length % cardEmojis.length];

    return AnimatedBuilder(
      animation: _flip,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _revealed ? AppColors.surface : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _revealed ? rarityColor : AppColors.borderGlow,
              width: _revealed ? 2 : 1,
            ),
            boxShadow: _revealed
                ? [BoxShadow(color: rarityColor.withOpacity(0.3), blurRadius: 12)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_revealed) ...[
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.card.name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  widget.card.rarity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: rarityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else
                const Center(
                  child: Text('🎴', style: TextStyle(fontSize: 32)),
                ),
            ],
          ),
        );
      },
    );
  }
}
