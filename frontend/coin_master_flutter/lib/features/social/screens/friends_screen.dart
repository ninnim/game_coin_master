import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/social_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/toast_notification.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '👥 Friends',
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
            onPressed: () => context.push('/leaderboard'),
            child: const Text(
              'Leaderboard',
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by username or ID...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
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
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
              onSubmitted: (v) async {
                if (v.isNotEmpty) {
                  final success = await ref
                      .read(socialActionProvider.notifier)
                      .sendFriendRequest(v);
                  if (context.mounted) {
                    if (success) {
                      showGameToast(
                        context,
                        'Friend request sent!',
                        isSuccess: true,
                      );
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    } else {
                      showGameToast(
                        context,
                        'Failed to send request',
                        isError: true,
                      );
                    }
                  }
                }
              },
            ),
          ),
          // Friends list
          Expanded(
            child: friendsAsync.when(
              loading: () =>
                  const SkeletonList(itemCount: 6, itemHeight: 80),
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
                      'Failed to load friends',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(friendsProvider),
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
              data: (friends) {
                final filtered = _searchQuery.isEmpty
                    ? friends
                    : friends
                        .where(
                          (f) => f.displayName
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()),
                        )
                        .toList();

                if (friends.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'No Friends Yet',
                    message:
                        'Search for players above to add friends!',
                    actionLabel: 'Add Friends',
                    onAction: () => _searchCtrl.selection =
                        TextSelection.fromPosition(
                      const TextPosition(offset: 0),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No friends match that name.',
                      style: AppTextStyles.caption,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final friend = filtered[index];
                    return _FriendTile(
                      friend: friend,
                      onGiftSpin: () async {
                        final success = await ref
                            .read(socialActionProvider.notifier)
                            .giftSpin(friend.userId);
                        if (context.mounted) {
                          if (success) {
                            showGameToast(
                              context,
                              'Spin gifted to ${friend.displayName}!',
                              isSuccess: true,
                            );
                            ref.invalidate(friendsProvider);
                          } else {
                            showGameToast(
                              context,
                              'Failed to gift spin',
                              isError: true,
                            );
                          }
                        }
                      },
                      onAccept: friend.status == 'incoming'
                          ? () async {
                              await ref
                                  .read(socialActionProvider.notifier)
                                  .respondToRequest(
                                    friend.userId,
                                    true,
                                  );
                              if (context.mounted) {
                                ref.invalidate(friendsProvider);
                              }
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback onGiftSpin;
  final VoidCallback? onAccept;

  const _FriendTile({
    required this.friend,
    required this.onGiftSpin,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    friend.displayName.isNotEmpty
                        ? friend.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                // Online indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: friend.isOnline
                          ? AppColors.emerald
                          : AppColors.textSecondary,
                      shape: BoxShape.circle,
                      border: const Border.fromBorderSide(
                        BorderSide(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        friend.displayName,
                        style: AppTextStyles.subtitle,
                      ),
                      if (friend.status == 'pending') ...[
                        const SizedBox(width: 6),
                        _StatusBadge(
                          label: 'PENDING',
                          color: AppColors.gold,
                        ),
                      ],
                      if (friend.status == 'incoming') ...[
                        const SizedBox(width: 6),
                        _StatusBadge(
                          label: 'REQUESTED YOU',
                          color: AppColors.cyan,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Village ${friend.villageLevel}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            // Actions
            if (onAccept != null)
              GlassButton(
                label: 'Accept',
                color: AppColors.emerald,
                onTap: onAccept,
              )
            else
              GlassButton(
                label: friend.canGiftSpin ? '🎁 Gift' : 'Gifted',
                color: AppColors.gold,
                isPrimary: friend.canGiftSpin,
                onTap: friend.canGiftSpin ? onGiftSpin : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
