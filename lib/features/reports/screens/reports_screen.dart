import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(weekReportProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 1,
              labelStyle: AppTypography.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTypography.textTheme.titleSmall,
              tabs: const [Tab(text: 'Week View'), Tab(text: 'Month View')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _WeeklyTab(),
                _MonthlyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(weekReportProvider);
    return asyncData.when(
      data: (data) => _WeekContent(data: data),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load report data'),
            TextButton(
              onPressed: () => ref.invalidate(weekReportProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekContent extends ConsumerWidget {
  final WeekReportData data;

  const _WeekContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightData = data.weightData;
    final calorieData = data.calorieData;
    final maxY = weightData.isEmpty ? 80.0 : (weightData.reduce((a, b) => a > b ? a : b) + 5).clamp(40.0, 150.0);
    final minY = weightData.isEmpty ? 50.0 : (weightData.reduce((a, b) => a < b ? a : b) - 5).clamp(30.0, 100.0);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: '7-day Calories',
                value: '${calorieData.fold<int>(0, (s, v) => s + v)} cal',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: '7-day Steps',
                value: data.stepsData.isEmpty
                    ? '0'
                    : data.stepsData
                        .fold<int>(0, (s, v) => s + v)
                        .toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mass Evolution', style: AppTypography.textTheme.titleMedium),
            const Icon(LucideIcons.sparkles, size: 16, color: AppColors.textMuted),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(12, 32, 24, 12),
          decoration: premiumCardDecoration(),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.border.withOpacity(0.5),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][v.toInt() % 7],
                        style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: weightData
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text('Daily Caloric Profile', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 20),
        Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
          decoration: premiumCardDecoration(),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (calorieData.isEmpty ? 2500.0 : (calorieData.reduce((a, b) => a > b ? a : b).toDouble() + 200)).clamp(500.0, 4000.0),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 7,
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Day ${v.toInt() + 1}',
                        style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: calorieData
                  .asMap()
                  .entries
                  .map((e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.toDouble(),
                            color: e.value > 2166
                                ? AppColors.error.withOpacity(0.8)
                                : AppColors.primary,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Mean Intake',
                value: '${data.meanCalorie.toStringAsFixed(0)} cal',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Avg Sleep',
                value: '${data.sleepHours.toStringAsFixed(1)} h',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Avg Steps',
                value: data.stepsData.isEmpty
                    ? 'N/A'
                    : '${(data.stepsData.reduce((a, b) => a + b) / data.stepsData.length).toStringAsFixed(0)}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Avg Burned',
                value: data.burnedCalorieData.isEmpty
                    ? 'N/A'
                    : '${(data.burnedCalorieData.reduce((a, b) => a + b) / data.burnedCalorieData.length).toStringAsFixed(0)} cal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text('Nutrient Distribution', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 20),
        _buildNutrientBars(data),
        const SizedBox(height: 32),
        Text('Static Targets', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Recommended Daily Calories',
                value: '2100 kcal',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Recommended Daily Steps',
                value: '10,000',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Recommended Sleep',
                value: '7.5 h / night',
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

Widget _buildMetricCard({required String title, required String value}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: premiumCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(value, style: AppTypography.textTheme.titleLarge),
      ],
    ),
  );
}

Widget _buildNutrientBars(WeekReportData data) {
  final nutrients = {
    'Protein': data.totalProtein,
    'Carbs': data.totalCarbs,
    'Fat': data.totalFat,
  };
  final total = nutrients.values.reduce((a, b) => a + b);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: premiumCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nutrients.entries.map((e) {
        final percentage = total > 0 ? (e.value / total) * 100 : 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: AppTypography.textTheme.bodyMedium),
                  Text('${e.value.toStringAsFixed(0)}g', style: AppTypography.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.border.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  e.key == 'Protein' ? AppColors.primary : e.key == 'Carbs' ? AppColors.secondary : AppColors.accent,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(monthReportProvider);
    return report.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (data) {
        final weightData = data.weightData;
        final calorieData = data.calorieData;
        final minY = (weightData.isEmpty ? 68.0 : (weightData.reduce((a, b) => a < b ? a : b) - 2)).clamp(0.0, 200.0);
        final maxY = (weightData.isEmpty ? 72.0 : (weightData.reduce((a, b) => a > b ? a : b) + 2)).clamp(0.0, 200.0);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: '30-day Calories',
                    value:
                        '${calorieData.fold<int>(0, (s, v) => s + v)} cal',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: '30-day Steps',
                    value: data.stepsData.isEmpty
                        ? '0'
                        : data.stepsData
                            .fold<int>(0, (s, v) => s + v)
                            .toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Mass Evolution', style: AppTypography.textTheme.titleMedium),
            const SizedBox(height: 20),
            Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(0, 20, 20, 12),
              decoration: premiumCardDecoration(),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 7,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Day ${v.toInt() + 1}',
                            style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Daily Caloric Profile', style: AppTypography.textTheme.titleMedium),
            const SizedBox(height: 20),
            Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
              decoration: premiumCardDecoration(),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (calorieData.isEmpty ? 2500.0 : (calorieData.reduce((a, b) => a > b ? a : b).toDouble() + 200)).clamp(500.0, 4000.0),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Day ${v.toInt() + 1}',
                            style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: calorieData
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.toDouble(),
                                color: e.value > 2166
                                    ? AppColors.error.withOpacity(0.8)
                                    : AppColors.primary,
                                width: 8,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Mean Intake',
                    value: '${data.meanCalorie.toStringAsFixed(0)} cal',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg Sleep',
                    value: '${data.sleepHours.toStringAsFixed(1)} h',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg Steps',
                    value: data.stepsData.isEmpty
                        ? 'N/A'
                        : '${(data.stepsData.reduce((a, b) => a + b) / data.stepsData.length).toStringAsFixed(0)}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg Burned',
                    value: data.burnedCalorieData.isEmpty
                        ? 'N/A'
                        : '${(data.burnedCalorieData.reduce((a, b) => a + b) / data.burnedCalorieData.length).toStringAsFixed(0)} cal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Nutrient Distribution', style: AppTypography.textTheme.titleMedium),
            const SizedBox(height: 20),
            _buildMonthNutrientBars(data),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

Widget _buildMonthNutrientBars(MonthReportData data) {
  final nutrients = {
    'Protein': data.totalProtein,
    'Carbs': data.totalCarbs,
    'Fat': data.totalFat,
  };
  final total = nutrients.values.reduce((a, b) => a + b);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: premiumCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nutrients.entries.map((e) {
        final percentage = total > 0 ? (e.value / total) * 100 : 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: AppTypography.textTheme.bodyMedium),
                  Text('${e.value.toStringAsFixed(0)}g', style: AppTypography.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.border.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  e.key == 'Protein' ? AppColors.primary : e.key == 'Carbs' ? AppColors.secondary : AppColors.accent,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
