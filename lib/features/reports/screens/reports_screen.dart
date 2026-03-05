import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/reports_provider.dart';
import '../services/report_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(performanceReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(performanceReportProvider),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load report data',
                  style: AppTypography.textTheme.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(performanceReportProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) => _PerformanceContent(data: data),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content — single scrollable page
// ---------------------------------------------------------------------------

class _PerformanceContent extends ConsumerWidget {
  final PerformanceReportData data;
  const _PerformanceContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Date & summary ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: premiumCardDecoration(),
          child: Row(
            children: [
              const Icon(LucideIcons.calendar,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Text('Report Date: ${data.reportDate}',
                  style: AppTypography.textTheme.titleSmall),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _capitalize(data.activityLevel),
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Performance Scores ──
        Text('Performance Scores',
            style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 16),
        _buildScoreGauges(data),
        const SizedBox(height: 24),

        // ── Nutrition Breakdown ──
        Text('Nutrition Breakdown',
            style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _MetricCard(
                    title: 'Meals Eaten',
                    value: '${data.mealsEaten} / ${data.totalMeals}')),
            const SizedBox(width: 12),
            Expanded(
                child: _MetricCard(
                    title: 'Avg Calories',
                    value: '${data.avgCalories.toStringAsFixed(0)} cal')),
          ],
        ),
        const SizedBox(height: 12),
        _buildNutrientBars(data),
        const SizedBox(height: 24),

        // ── Activity & Workout ──
        Text('Activity & Workouts',
            style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _MetricCard(
                    title: 'Workout Status',
                    value:
                        '${data.workoutCompletionPct.round()}%')),
            const SizedBox(width: 12),
            Expanded(
                child: _MetricCard(
                    title: 'Weight',
                    value: '${data.currentWeight.toStringAsFixed(1)} kg')),
          ],
        ),
        const SizedBox(height: 24),

        // ── Sleep & Hydration ──
        Text('Sleep & Hydration',
            style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _MetricCard(
                    title: 'Sleep Target',
                    value: '${data.targetSleep.toStringAsFixed(1)} h')),
            const SizedBox(width: 12),
            Expanded(
                child: _MetricCard(
                    title: 'Water Target',
                    value: '${data.targetWater.toStringAsFixed(1)} L')),
          ],
        ),
        const SizedBox(height: 32),

        // ── Download ──
        _DownloadButton(
          label: 'Download Performance Report',
          onDownload: () => _downloadPdf(context, ref, data),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  static Future<void> _downloadPdf(
      BuildContext context, WidgetRef ref, PerformanceReportData data) async {
    final profile = ref.read(profileFutureProvider).valueOrNull;
    final userName = profile?.fullName ?? 'User';
    try {
      final file = await ReportService.instance
          .generatePerformanceReport(data: data, userName: userName);
      await OpenFile.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate report: $e')),
        );
      }
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ---------------------------------------------------------------------------
// Metric Card
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: premiumCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.textTheme.bodySmall),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nutrient bars
// ---------------------------------------------------------------------------

Widget _buildNutrientBars(PerformanceReportData data) {
  final nutrients = {
    'Protein': data.totalProtein,
    'Carbs': data.totalCarbs,
    'Fat': data.totalFat,
  };
  final total = nutrients.values.fold<double>(0, (a, b) => a + b);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: premiumCardDecoration(),
    child: Column(
      children: nutrients.entries.map((e) {
        final pct = total > 0 ? e.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: AppTypography.textTheme.bodyMedium),
                  Text('${e.value.toStringAsFixed(0)}g',
                      style: AppTypography.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.border.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  e.key == 'Protein'
                      ? AppColors.primary
                      : e.key == 'Carbs'
                          ? AppColors.secondary
                          : AppColors.accent,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Score Gauges
// ---------------------------------------------------------------------------

Widget _buildScoreGauges(PerformanceReportData data) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: premiumCardDecoration(),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ScoreGauge(
                label: 'Nutrition\nAdherence',
                score: data.nutritionScore,
                color: AppColors.primary,
                icon: LucideIcons.flame,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScoreGauge(
                label: 'Physical\nActivity',
                score: data.activityScore,
                color: AppColors.info,
                icon: LucideIcons.activity,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ScoreGauge(
                label: 'Sleep\nQuality',
                score: data.sleepScore,
                color: AppColors.warning,
                icon: LucideIcons.moon,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScoreGauge(
                label: 'Hydration\nConsistency',
                score: data.hydrationScore,
                color: const Color(0xFF42C6FF),
                icon: LucideIcons.droplets,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ScoreGauge extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final IconData icon;

  const _ScoreGauge({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score / 100).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _ArcPainter(
                    progress: pct,
                    trackColor: AppColors.border.withOpacity(0.3),
                    progressColor: color,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(height: 4),
                  Text(
                    '${score.round()}%',
                    style: AppTypography.numbers(16).copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Download button
// ---------------------------------------------------------------------------

class _DownloadButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onDownload;

  const _DownloadButton({required this.label, required this.onDownload});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                try {
                  await widget.onDownload();
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : const Icon(LucideIcons.download, size: 16),
        label: Text(widget.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arc painter
// ---------------------------------------------------------------------------

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _ArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(6);
    final p = progress.clamp(0.0, 1.0);
    // Full circle when 100%, otherwise 270° arc
    final bool isFull = p >= 1.0;
    final double startAngle = isFull ? -math.pi / 2 : -math.pi * 0.75;
    final double totalSweep = isFull ? math.pi * 2 : math.pi * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, totalSweep, false, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, totalSweep * p, false, progressPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
