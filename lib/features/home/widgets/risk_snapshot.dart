import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/prediction_result.dart';
import '../../health_risk/providers/predictions_provider.dart';

class RiskSnapshotWidget extends ConsumerWidget {
  const RiskSnapshotWidget({super.key});

  static Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'LOW':
        return AppColors.success;
      case 'MODERATE':
        return AppColors.warning;
      case 'HIGH':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPredictions = ref.watch(predictionsFutureProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Risk Assessment',
          style: AppTypography.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        asyncPredictions.when(
          loading: () => Container(
            width: double.infinity,
            decoration: premiumCardDecoration(),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Analyzing your health data…',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          error: (err, _) => Container(
            width: double.infinity,
            decoration: premiumCardDecoration(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load risk analysis.',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => ref.invalidate(predictionsFutureProvider),
                  child: Text(
                    'Tap to retry',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          data: (result) {
            final all = result?.predictions ?? [];
            if (all.isEmpty) {
              return Container(
                width: double.infinity,
                decoration: premiumCardDecoration(),
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No risk data available yet. Your profile data will be analyzed shortly.',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }

            // Show whichever conditions were returned by the ML model
            List<HealthRiskPrediction> selected = [];
            const desired = ['obesity', 'diabetes', 'hypertension'];
            for (final key in desired) {
              final match = all.where(
                (p) => p.condition.toLowerCase().contains(key),
              );
              if (match.isNotEmpty) selected.add(match.first);
            }
            if (selected.isEmpty) selected = all.take(3).toList();

            return Row(
              children: [
                for (var i = 0; i < selected.length; i++) ...[
                  Expanded(
                    child: _RiskChip(
                      label: selected[i].condition,
                      level: selected[i].level.toUpperCase(),
                      color: _levelColor(selected[i].level),
                      percent: selected[i].score.clamp(0.0, 100.0) / 100.0,
                    ),
                  ),
                  if (i != selected.length - 1) const SizedBox(width: 16),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RiskChip extends StatelessWidget {
  final String label;
  final String level;
  final Color color;
  final double percent;

  const _RiskChip({
    required this.label,
    required this.level,
    required this.color,
    this.percent = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 1.0);
    return Container(
      decoration: premiumCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.shieldAlert, size: 12, color: color),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                level,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
