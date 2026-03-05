import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/meal.dart';
import '../../auth/providers/auth_provider.dart';
import '../../health_risk/providers/predictions_provider.dart';
import '../providers/meal_provider.dart';
import 'meal_detail_screen.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _today = DateTime.now().toIso8601String().split('T').first;
  String _selectedDateForDaily = DateTime.now().toIso8601String().split('T').first;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDateForDaily = _today;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Daily tab shows meals for selected date from same JSON source as Weekly:
    // e.g. March 3 in Weekly shows oats & chicken → Daily for March 3 shows same.
    final weeklyPlanAsync = ref.watch(weeklyMealPlanProvider);
    final mealForSelectedDate = ref.watch(mealPlanProvider(_selectedDateForDaily));
    final profile = ref.watch(profileProvider).valueOrNull;
    final predictions = ref.watch(predictionsFutureProvider).valueOrNull;
    final targetCal = predictions?.calorieTarget?.round() ??
        profile?.tdee?.round() ??
        2166;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nutritional Strategy'),
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
              tabs: const [
                Tab(text: 'Daily'),
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DailyTabContent(
                  selectedDate: _selectedDateForDaily,
                  today: _today,
                  targetCal: targetCal,
                  weeklyPlanAsync: weeklyPlanAsync,
                  mealForSelectedDate: mealForSelectedDate,
                ),
                const _WeeklyMealView(),
                const _MonthlyMealView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Daily tab: same meals as Weekly for the selected date (JSON as single source).
class _DailyTabContent extends ConsumerWidget {
  final String selectedDate;
  final String today;
  final int targetCal;
  final AsyncValue<Map<String, List<Meal>>> weeklyPlanAsync;
  final AsyncValue<List<Meal>> mealForSelectedDate; // same JSON source via getMealPlan(date)

  const _DailyTabContent({
    required this.selectedDate,
    required this.today,
    required this.targetCal,
    required this.weeklyPlanAsync,
    required this.mealForSelectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return weeklyPlanAsync.when(
      data: (planMap) {
        // Use same plan as Weekly: meals for selected date from JSON
        List<Meal>? meals = planMap[selectedDate];
        if (meals != null && meals.isNotEmpty) {
          return _DailyView(
            meals: meals,
            targetCal: targetCal,
            date: selectedDate,
            leading: null,
          );
        }
        // Selected date outside 7-day window: fetch from same JSON source (getMealPlan)
        return mealForSelectedDate.when(
          data: (fallbackMeals) => _DailyView(
            meals: fallbackMeals,
            targetCal: targetCal,
            date: selectedDate,
            leading: null,
          ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, __) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, __) => Center(child: Text('Error: $e')),
    );
  }
}

class _WeeklyMealView extends ConsumerWidget {
  const _WeeklyMealView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyMealPlanProvider);
    return async.when(
      data: (planMap) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Strategy', style: AppTypography.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          ...planMap.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: premiumCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(entry.key),
                        style: AppTypography.textTheme.titleSmall,
                      ),
                      Text(
                        '${entry.value.fold(0, (sum, meal) => sum + meal.calories)} kcal',
                        style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...entry.value.map((meal) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getMealTypeColor(meal.mealType),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${meal.mealType.toUpperCase()}: ${meal.name}',
                            style: AppTypography.textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '${meal.calories} kcal',
                          style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          )),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load weekly plan')),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast': return AppColors.info;
      case 'lunch': return AppColors.warning;
      case 'dinner': return AppColors.success;
      case 'night': return const Color(0xFF7C6DCD);
      default: return AppColors.textMuted;
    }
  }
}

class _MonthlyMealView extends ConsumerWidget {
  const _MonthlyMealView();

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthLabel = '${_monthNames[now.month - 1]} 1 – $daysInMonth';
    final async = ref.watch(monthlyMealPlanProvider);
    return async.when(
      data: (planMap) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(monthLabel, style: AppTypography.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: planMap.length,
            itemBuilder: (context, index) {
              final entry = planMap.entries.elementAt(index);
              final totalCal = entry.value.fold(0, (sum, meal) => sum + meal.calories);
              final isToday = entry.key == DateTime.now().toIso8601String().split('T').first;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showDayMealsPopup(context, entry.key, entry.value),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary.withOpacity(0.06) : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isToday ? AppColors.primary : AppColors.border,
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatShortDate(entry.key),
                        style: AppTypography.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${entry.value.length} meals',
                        style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      Text(
                        '$totalCal kcal',
                        style: AppTypography.textTheme.titleSmall?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load monthly plan')),
    );
  }

  String _formatShortDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showDayMealsPopup(BuildContext context, String dateStr, List<Meal> meals) {
    final dateLabel = _formatShortDate(dateStr);
    final totalCal = meals.fold(0, (sum, m) => sum + m.calories);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: AppTypography.textTheme.titleMedium,
                ),
                Text(
                  '$totalCal kcal',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...meals.map((meal) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: _mealTypeColor(meal.mealType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.mealType.toUpperCase(),
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meal.name,
                          style: AppTypography.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${meal.calories} kcal',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _mealTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return AppColors.info;
      case 'lunch': return AppColors.warning;
      case 'dinner': return AppColors.success;
      case 'night': return const Color(0xFF7C6DCD);
      default: return AppColors.textMuted;
    }
  }
}

class _DailyView extends StatefulWidget {
  final List<Meal> meals;
  final int targetCal;
  final String date;
  final Widget? leading;

  const _DailyView({
    required this.meals,
    required this.targetCal,
    required this.date,
    this.leading,
  });

  @override
  State<_DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<_DailyView> {
  late List<Meal> _meals;
  final Set<String> _doneMealIds = {};

  @override
  void initState() {
    super.initState();
    _meals = List<Meal>.from(widget.meals);
  }

  @override
  void didUpdateWidget(covariant _DailyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep local state in sync with the latest JSON-based plan
    _meals = List<Meal>.from(widget.meals);
  }

  void _handleSwap(Meal original, Meal replacement) {
    setState(() {
      final index = _meals.indexWhere((m) => m.id == original.id);
      if (index != -1) {
        _doneMealIds.remove(original.id);
        _meals[index] = replacement;
      }
    });
  }

  void _toggleDone(String mealId) {
    setState(() {
      if (_doneMealIds.contains(mealId)) {
        _doneMealIds.remove(mealId);
      } else {
        _doneMealIds.add(mealId);
      }
    });
  }

  int get _totalCal => _meals.fold(0, (s, m) => s + m.calories);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Scheduled Meals', style: AppTypography.textTheme.titleMedium),
            Text(
              '${_meals.length} Sessions',
              style: AppTypography.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ..._meals.map((m) {
          final originalMeal = m;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _MealCard(
              meal: m,
              date: widget.date,
              onMealSwapped: (alt) => _handleSwap(originalMeal, alt),
              isDone: _doneMealIds.contains(m.id),
              onToggleDone: () => _toggleDone(m.id),
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: premiumCardDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Calibration',
                style: AppTypography.textTheme.titleSmall,
              ),
              Text(
                '$_totalCal kcal',
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealCard extends ConsumerStatefulWidget {
  final Meal meal;
  final String date;
  final ValueChanged<Meal> onMealSwapped;
  final bool isDone;
  final VoidCallback onToggleDone;

  const _MealCard({
    required this.meal,
    required this.date,
    required this.onMealSwapped,
    required this.isDone,
    required this.onToggleDone,
  });

  static String _typeLabel(String type) {
    switch (type) {
      case 'breakfast':
        return 'MORNING';
      case 'lunch':
        return 'MIDDAY';
      case 'dinner':
        return 'EVENING';
      case 'night':
        return 'NIGHT';
      default:
        return 'SUPPLEMENT';
    }
  }

  @override
  ConsumerState<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends ConsumerState<_MealCard> {
  bool _swapping = false;
  bool _swapped = false;

  Future<void> _instantSwap() async {
    setState(() => _swapping = true);
    try {
      final alternatives = await ref.read(mealAlternativesProvider({
        'mealId': widget.meal.id,
        'mealType': widget.meal.mealType,
      }).future);
      if (alternatives.isNotEmpty && mounted) {
        // Record swap globally so all views reflect the change
        ref.read(mealSwapOverridesProvider.notifier)
            .recordSwap(widget.date, widget.meal.mealType, alternatives.first);
        widget.onMealSwapped(alternatives.first);
        if (mounted) setState(() => _swapped = true);
      }
    } catch (_) {
      // silently handle swap failure
    }
    if (mounted) setState(() => _swapping = false);
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final isDone = widget.isDone;
    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isDone ? AppColors.success.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone ? AppColors.success.withOpacity(0.4) : AppColors.border,
            width: isDone ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                      Text(
                        _MealCard._typeLabel(meal.mealType),
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (isDone) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      ],
                    ],
                  ),
                  Text(
                    '${meal.calories} kcal',
                    style: AppTypography.textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                meal.name,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroItem(label: 'Prot', value: '${meal.protein}g'),
                    _MacroItem(label: 'Carb', value: '${meal.carbs}g'),
                    _MacroItem(label: 'Fat', value: '${meal.fat}g'),
                    _MacroItem(label: 'Fib', value: '${meal.fiber}g'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MealDetailScreen(meal: meal),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.chefHat, size: 14),
                      label: const Text('Recipe'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (!_swapped) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _swapping ? null : _instantSwap,
                        icon: _swapping
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.refreshCw, size: 14),
                        label: const Text('Swap'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: isDone
                        ? ElevatedButton.icon(
                            onPressed: widget.onToggleDone,
                            icon: const Icon(Icons.check_circle, size: 14),
                            label: const Text('Done'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: widget.onToggleDone,
                            icon: const Icon(Icons.check_circle_outline, size: 14),
                            label: const Text('Done'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;

  const _MacroItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.textTheme.titleSmall?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
