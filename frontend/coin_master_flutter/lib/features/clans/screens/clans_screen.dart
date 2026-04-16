import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/clan_provider.dart';
import '../../../core/models/clan_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/toast_notification.dart';

class ClansScreen extends ConsumerStatefulWidget {
  const ClansScreen({super.key});

  @override
  ConsumerState<ClansScreen> createState() => _ClansScreenState();
}

class _ClansScreenState extends ConsumerState<ClansScreen> {
  bool _showCreateForm = false;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _createClan() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final success = await ref
        .read(clanActionProvider.notifier)
        .createClan(_nameCtrl.text.trim(), _descCtrl.text.trim());
    if (context.mounted) {
      if (success) {
        showGameToast(context, 'Clan created!', isSuccess: true);
        setState(() => _showCreateForm = false);
        ref.invalidate(myClanProvider);
        ref.invalidate(clansProvider);
      } else {
        showGameToast(context, 'Failed to create clan', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myClanAsync = ref.watch(myClanProvider);
    final clansAsync = ref.watch(clansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '⚔️ Clans',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/game'),
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
            // My clan section
            myClanAsync.when(
              loading: () => const LoadingSkeleton(height: 100),
              error: (_, __) => const SizedBox.shrink(),
              data: (myClan) {
                if (myClan != null) {
                  return _MyClanCard(clan: myClan);
                }
                return Column(
                  children: [
                    GlassCard(
                      borderColor: AppColors.gold.withOpacity(0.4),
                      child: Column(
                        children: [
                          const Text(
                            'You are not in a clan yet!',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Join an existing clan or create your own.',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          GlassButton(
                            label: _showCreateForm
                                ? 'Cancel'
                                : '+ Create Clan',
                            onTap: () => setState(
                              () => _showCreateForm = !_showCreateForm,
                            ),
                            isPrimary: !_showCreateForm,
                          ),
                        ],
                      ),
                    ),
                    if (_showCreateForm) ...[
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create New Clan',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameCtrl,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                              decoration: _inputDecoration(
                                'Clan Name',
                                Icons.flag,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _descCtrl,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              decoration: _inputDecoration(
                                'Description (optional)',
                                Icons.description,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: GlassButton(
                                label: 'Create Clan',
                                onTap: _createClan,
                                icon: Icons.add,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Public Clans', style: AppTextStyles.title),
            const SizedBox(height: 12),
            // Clans list
            clansAsync.when(
              loading: () => Column(
                children: List.generate(
                  5,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LoadingSkeleton(height: 90),
                  ),
                ),
              ),
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
                    const Text(
                      'Failed to load clans',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(clansProvider),
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
              data: (clans) {
                if (clans.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.groups,
                    title: 'No Clans Yet',
                    message: 'Be the first to create a clan!',
                    actionLabel: 'Create Clan',
                    onAction: () =>
                        setState(() => _showCreateForm = true),
                  );
                }
                return Column(
                  children: clans
                      .map(
                        (c) => _ClanTile(
                          clan: c,
                          onJoin: () async {
                            final success = await ref
                                .read(clanActionProvider.notifier)
                                .joinClan(c.id);
                            if (context.mounted) {
                              if (success) {
                                showGameToast(
                                  context,
                                  'Joined ${c.name}!',
                                  isSuccess: true,
                                );
                                ref.invalidate(myClanProvider);
                              } else {
                                showGameToast(
                                  context,
                                  'Failed to join clan',
                                  isError: true,
                                );
                              }
                            }
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGlow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        filled: true,
        fillColor: AppColors.surface,
      );
}

class _MyClanCard extends StatelessWidget {
  final ClanModel clan;

  const _MyClanCard({required this.clan});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.gold.withOpacity(0.6),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('⚔️', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(clan.name, style: AppTextStyles.subtitle),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: const Text(
                        'MY CLAN',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Leader: ${clan.leaderName}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  '${clan.memberCount} members • ${NumberFormat("#,###").format(clan.totalPoints)} pts',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClanTile extends StatelessWidget {
  final ClanModel clan;
  final VoidCallback onJoin;

  const _ClanTile({required this.clan, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🛡️', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clan.name, style: AppTextStyles.subtitle),
                  Text(
                    '${clan.memberCount} members • ${NumberFormat("#,###").format(clan.totalPoints)} pts',
                    style: AppTextStyles.caption,
                  ),
                  if (clan.description != null)
                    Text(
                      clan.description!,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            GlassButton(
              label: 'Join',
              color: AppColors.purple,
              onTap: onJoin,
            ),
          ],
        ),
      ),
    );
  }
}
