import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/event_provider.dart';
import '../../../core/models/event_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/toast_notification.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  static const Map<String, Map<String, dynamic>> _eventIcons = {
    'attack_madness': {'emoji': '⚔️', 'color': 0xFFD50000},
    'raid_madness': {'emoji': '⛏️', 'color': 0xFF8D6E63},
    'viking': {'emoji': '⚓', 'color': 0xFF1565C0},
    'balloon_frenzy': {'emoji': '🎈', 'color': 0xFFE91E63},
    'gold_card': {'emoji': '🃏', 'color': 0xFFFFD700},
    'default': {'emoji': '🎉', 'color': 0xFF6A1B9A},
  };

  Map<String, dynamic> _getEventData(String type) {
    return _eventIcons[type] ?? _eventIcons['default']!;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(activeEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          '🎉 Events',
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
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        onRefresh: () async => ref.invalidate(activeEventsProvider),
        child: eventsAsync.when(
          loading: () => const SkeletonList(itemCount: 4, itemHeight: 160),
          error: (e, _) => ListView(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
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
                        'Failed to load events',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(activeEventsProvider),
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
              ),
            ],
          ),
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                children: const [
                  EmptyStateWidget(
                    icon: Icons.event_busy,
                    title: 'No Active Events',
                    message:
                        'Check back soon for new events and rewards!',
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final eventData = _getEventData(event.type);
                return _EventCard(
                  event: event,
                  emoji: eventData['emoji'] as String,
                  accentColor: Color(eventData['color'] as int),
                  onClaim: event.userProgress >= 100 && !event.isClaimed
                      ? () {
                          showGameToast(
                            context,
                            'Reward claimed for ${event.title}!',
                            isSuccess: true,
                          );
                        }
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final String emoji;
  final Color accentColor;
  final VoidCallback? onClaim;

  const _EventCard({
    required this.event,
    required this.emoji,
    required this.accentColor,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (event.userProgress / 100.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderColor: accentColor.withOpacity(0.5),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: AppTextStyles.subtitle),
                        if (event.description != null)
                          Text(
                            event.description!,
                            style: AppTextStyles.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (event.isClaimed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.emerald),
                      ),
                      child: const Text(
                        '✅ Claimed',
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: ${event.userProgress}%',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        event.userProgress >= 100
                            ? '🎁 Ready to claim!'
                            : '${(100 - event.userProgress)}% to go',
                        style: TextStyle(
                          color: event.userProgress >= 100
                              ? AppColors.emerald
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? AppColors.emerald : accentColor,
                    ),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            // Claim button
            if (onClaim != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    label: '🎁 Claim Reward',
                    color: AppColors.emerald,
                    onTap: onClaim,
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
