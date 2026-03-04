import 'package:flutter/material.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/prediction_result.dart';

class RiskSnapshotWidget extends StatelessWidget {
  /// When non-null, shows these ML predictions instead of placeholders.
  final List<HealthRiskPrediction>? predictions;

  const RiskSnapshotWidget({super.key, this.predictions});

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
  Widget build(BuildContext context) {
    final show = predictions != null && predictions!.isNotEmpty;
    final all = show ? predictions! : <HealthRiskPrediction>[];

    // Prefer specific conditions in this order so the dashboard
    // always surfaces Obesity, Diabetes, and Hypertension when
    // available from the model.
    List<HealthRiskPrediction> selected = [];
    List<String> desired = ['obesity', 'diabetes', 'hypertension'];
    for (final key in desired) {
      final match = all.firstWhere(
        (p) => p.condition.toLowerCase().contains(key),
        orElse: () => HealthRiskPrediction(
          condition: key[0].toUpperCase() + key.substring(1),
          level: 'MODERATE',
          score: 60,
          description: null,
        ),
      );
      selected.add(match);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Risk Assessment',
              style: AppTypography.textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label.length > 12 ? '${label.substring(0, 12)}…' : label,
                    style: AppTypography.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(LucideIcons.shieldAlert, size: 14, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              level,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
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
