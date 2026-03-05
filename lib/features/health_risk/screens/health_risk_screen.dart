import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/prediction_result.dart';
import '../providers/predictions_provider.dart';

class HealthRiskScreen extends ConsumerWidget {
  const HealthRiskScreen({super.key});

  static String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the dynamic predictions provider so risk levels
    // update automatically when profile, preferences, or
    // lifestyle data changes.
    final asyncResult = ref.watch(predictionsFutureProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Intelligence Analysis'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proprietary Risk Analysis',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Report generated on ${DateTime.now().day} ${_month(DateTime.now().month)} ${DateTime.now().year}',
                style: AppTypography.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              asyncResult.when(
                data: (result) {
                  final risks = _predictionsToRiskData(result?.predictions ?? []);
                  final hasRisks = risks.isNotEmpty;
                  final bmi = result?.bmiCategory;
                  final badge = result?.badgeStatus;
                  final cal = result?.calorieTarget;
                  
                  if (!hasRisks && (bmi == null || bmi.isEmpty)) {
                    return premiumCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Synchronization pending. Please finalize your profile metrics to initiate analytical processing.',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: [
                      ...risks.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _RiskCard(data: r),
                      )),
                      if (bmi != null && bmi.isNotEmpty) ...[
                        _MlInfoCard(title: 'Metabolic Classification', value: bmi, icon: LucideIcons.activity),
                      ],
                      if (badge != null && badge.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _MlInfoCard(title: 'Protocol Tier', value: badge, icon: LucideIcons.award),
                      ],
                      if (cal != null) ...[
                        const SizedBox(height: 16),
                        _MlInfoCard(
                          title: 'Caloric Equilibrium',
                          value: '${cal.round()} kcal',
                          icon: LucideIcons.flame,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => premiumCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 24),
                        const SizedBox(height: 12),
                        Text(
                          'Analytical Disruption',
                          style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The neural processor encountered an exception. Verify your connectivity and profile integrity.',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(predictionsFutureProvider),
                          icon: const Icon(LucideIcons.refreshCcw, size: 16),
                          label: const Text('Retry Analysis'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              premiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shieldAlert, color: AppColors.warning, size: 20),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'DISCLAIMER: This analysis is for informational purposes only. Consult medical professionals for clinical evaluation.',
                          style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10, letterSpacing: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  static List<_RiskData> _predictionsToRiskData(List<HealthRiskPrediction> predictions) {
    return predictions.map((p) {
      final level = p.level.toUpperCase();
      final title = p.condition.toUpperCase();
      final percent = p.score.clamp(0.0, 100.0).round();
      final description = p.description ?? 'Analysis based on biometric data stream.';
      return _RiskData(title, level, percent, description);
    }).toList();
  }
}

class _RiskData {
  final String title;
  final String level;
  final int percent;
  final String description;

  _RiskData(this.title, this.level, this.percent, this.description);
}

class _RiskCard extends StatelessWidget {
  final _RiskData data;

  const _RiskCard({required this.data});

  Color get _levelColor {
    switch (data.level) {
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
    return premiumCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: AppTypography.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Risk Vector Analysis',
                        style: AppTypography.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _levelColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    data.level,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: _levelColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: data.percent / 100,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: _levelColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Confidence Interval', style: AppTypography.textTheme.bodySmall),
                Text('${data.percent}%', style: AppTypography.numbers(14).copyWith(color: _levelColor)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data.description,
              style: AppTypography.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MlInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MlInfoCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return premiumCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
