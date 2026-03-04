import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/services/streak_service.dart';
import '../providers/streak_provider.dart';

class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStreakAsync = ref.watch(currentStreakProvider);
    final weeklyProgressAsync = ref.watch(weeklyProgressProvider);
    final badgesAsync = ref.watch(userBadgesProvider);

    final currentStreakValue = currentStreakAsync.when(
      data: (streak) => streak,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Streaks & Badges'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              premiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.flame, color: AppColors.error, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            '$currentStreakValue DAY STREAK',
                            style: AppTypography.numbers(24).copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      weeklyProgressAsync.when(
                        data: (weeklyProgress) {
                          // weeklyProgress is Mon..Sun (index 0..6)
                          // Display as S M T W T F S (Sun first)
                          final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (i) {
                              return _DayNode(
                                label: labels[i],
                                isActive: weeklyProgress[i],
                              );
                            }),
                          );
                        },
                        loading: () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((l) => _DayNode(label: l, isActive: false))
                              .toList(),
                        ),
                        error: (_, __) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((l) => _DayNode(label: l, isActive: false))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Achievement Badges',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              badgesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (badges) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      return _BadgeCard(progress: badges[index]);
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeProgress progress;

  const _BadgeCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final badge = progress.badge;
    final isEarned = progress.isEarned;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEarned ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEarned ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.medal,
            size: 40,
            color: isEarned ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: isEarned ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          if (!isEarned) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ] else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
          ]
        ],
      ),
    );
  }
}

class _DayNode extends StatelessWidget {
  final String label;
  final bool isActive;

  const _DayNode({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
