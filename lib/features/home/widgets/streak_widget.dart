import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../streaks/screens/streaks_screen.dart';
import '../services/streak_service.dart';

class StreakWidget extends ConsumerWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStreakAsync = ref.watch(currentStreakProvider);
    final streak = currentStreakAsync.valueOrNull ?? 0;
    final weeklyProgressAsync = ref.watch(weeklyProgressProvider);
    return Container(
      decoration: premiumCardDecoration(),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StreaksScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.flame, size: 24, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Weekly Progress',
                        style: AppTypography.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Text(
                    '$streak Day Streak',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              weeklyProgressAsync.when(
                data: (weeklyProgress) {
                  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final isActive = weeklyProgress[i];
                      return Column(
                        children: [
                          Container(
                            width: 40,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: isActive ? null : Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: Text(
                                days[i],
                                style: AppTypography.textTheme.titleSmall?.copyWith(
                                  color: isActive ? Colors.white : AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isActive)
                            const Icon(LucideIcons.check, size: 12, color: AppColors.success)
                          else
                            const SizedBox(height: 12),
                        ],
                      );
                    }),
                  );
                },
                loading: () => const SizedBox(height: 56),
                error: (_, __) => const SizedBox(height: 56),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
