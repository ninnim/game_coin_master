import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../game/providers/player_state_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/toast_notification.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editingName = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final success = await ref
        .read(updateProfileProvider.notifier)
        .updateDisplayName(_nameCtrl.text.trim());
    if (context.mounted) {
      if (success) {
        showGameToast(context, 'Name updated!', isSuccess: true);
        setState(() => _editingName = false);
        ref.invalidate(playerStateProvider);
      } else {
        showGameToast(context, 'Failed to update name', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);
    ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '👤 Profile',
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
      body: playerState.when(
        loading: () => const SkeletonList(itemCount: 5, itemHeight: 80),
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
              const Text('Failed to load profile', style: AppTextStyles.body),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(playerStateProvider),
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
        data: (ps) {
          final user = ps.user;
          if (!_editingName) {
            _nameCtrl.text = user.displayName;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar + name
                GlassCard(
                  child: Column(
                    children: [
                      // Avatar circle
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.gold,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name (editable)
                      if (_editingName)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameCtrl,
                                autofocus: true,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter display name',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderGlow,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: AppColors.emerald,
                              ),
                              onPressed: _saveName,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.crimson,
                              ),
                              onPressed: () => setState(
                                () => _editingName = false,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.displayName,
                              style: AppTextStyles.title,
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(
                                () => _editingName = true,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 8),
                      // Village level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.goldDark, AppColors.gold],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🏰 Village ${user.villageLevel}',
                          style: const TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stats grid
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        emoji: '⭐',
                        label: 'Stars',
                        value: '${user.totalStars}',
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        emoji: '🪙',
                        label: 'Coins',
                        value: NumberFormat('#,###').format(user.coins),
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        emoji: '⚡',
                        label: 'Spins',
                        value: '${user.spins}',
                        color: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        emoji: '💎',
                        label: 'Gems',
                        value: '${user.gems}',
                        color: AppColors.purpleLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        emoji: '🛡️',
                        label: 'Shields',
                        value: '${user.shieldCount}/3',
                        color: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        emoji: '🐷',
                        label: 'Pig Bank',
                        value: NumberFormat('#,###').format(user.pigBankCoins),
                        color: const Color(0xFFE91E63),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Account actions
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Account', style: AppTextStyles.subtitle),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.map,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text(
                          'Village Map',
                          style: AppTextStyles.body,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () => context.push('/village-map'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.pets,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text('Pets', style: AppTextStyles.body),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () => context.push('/pets'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.groups,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text('Clans', style: AppTextStyles.body),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () => context.push('/clans'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.emoji_events,
                          color: AppColors.textSecondary,
                        ),
                        title: const Text(
                          'Achievements',
                          style: AppTextStyles.body,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () => context.push('/achievements'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Logout
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    label: 'Logout',
                    color: AppColors.crimson,
                    isPrimary: false,
                    icon: Icons.logout,
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
