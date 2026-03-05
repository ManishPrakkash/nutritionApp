import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/risk_snapshot.dart';
import '../services/streak_service.dart';
import '../services/pedometer_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../meals/screens/meal_detail_screen.dart';
import '../../meals/screens/meal_plan_screen.dart';
import '../../meals/providers/meal_provider.dart';
import '../../../models/meal.dart';
import '../../../services/firestore_service.dart';
import '../../reports/screens/reports_screen.dart';
import '../../grocery/screens/grocery_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/providers/profile_provider.dart';
import '../../health_risk/providers/predictions_provider.dart';
import '../../workout/screens/workout_screen.dart';
import '../../workout/providers/workout_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/steps_provider.dart';
import '../../streaks/screens/habit_tracker_screen.dart';
import '../services/goal_service.dart';
import '../widgets/daily_goals_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabData(icon: LucideIcons.home, label: 'Home'),
    _TabData(icon: LucideIcons.utensils, label: 'Meals'),
    _TabData(icon: LucideIcons.barChart3, label: 'Reports'),
    _TabData(icon: LucideIcons.shoppingCart, label: 'Grocery'),
    _TabData(icon: LucideIcons.user, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = ref.read(authUserIdProvider);
      if (uid == null) return;

      // Init pedometer (non-critical)
      try {
        await PedometerService.instance.init(uid);
      } catch (_) {}

      // Record today's login for streak tracking (non-critical)
      try {
        final streakService = ref.read(streakServiceProvider);
        await streakService.recordTodayLogin(uid);
        ref.invalidate(currentStreakProvider);
        ref.invalidate(weeklyProgressProvider);
      } catch (_) {}

      // Always show daily goals dialog if not set today
      if (mounted) await _checkDailyGoals(uid);
    });
  }

  Future<void> _checkDailyGoals(String uid) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final existing = await FirestoreService.instance.getDailyGoals(uid, today);
    if (existing != null) {
      // Check if all 3 goals were actually filled (non-zero)
      final water = (existing['waterLiters'] as num?)?.toDouble() ?? 0;
      final steps = (existing['steps'] as num?)?.toInt() ?? 0;
      final sleep = (existing['sleepHours'] as num?)?.toDouble() ?? 0;
      if (water > 0 && steps > 0 && sleep > 0) return; // All set
    }
    if (!mounted) return;
    // Keep showing dialog until all goals are entered
    bool? saved;
    while (saved != true && mounted) {
      saved = await DailyGoalsDialog.show(
        context,
        uid: uid,
        defaultWater: 0,
        defaultSteps: 0,
        defaultSleep: 0,
      );
    }
    // Refresh dashboard so new goals appear immediately
    ref.invalidate(todayDailyGoalsProvider);
  }

  @override
  void dispose() {
    PedometerService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final name = profile?.fullName.split(' ').first ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(name: name),
          const MealPlanScreen(),
          const ReportsScreen(),
          const GroceryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.98),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_tabs.length, (i) {
            final t = _tabs[i];
            final selected = _currentIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _currentIndex = i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / (_tabs.length + 1.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: selected ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ] : [],
                      ),
                      child: Icon(
                        t.icon,
                        size: 20,
                        color: selected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabData {
  final IconData icon;
  final String label;
  const _TabData({required this.icon, required this.label});
}

class _HomeTab extends ConsumerWidget {
  final String name;

  const _HomeTab({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final prefs = ref.watch(preferencesFutureProvider).valueOrNull;
    final predictions = ref.watch(latestPredictionProvider).valueOrNull;
    final currentSteps = ref.watch(currentStepsProvider);
    final uid = ref.watch(authUserIdProvider);
    final today = DateTime.now().toIso8601String().split('T').first;

    // Read user-entered daily goals from Firestore (set via popup)
    final dailyGoalsAsync = uid == null
        ? const AsyncValue<Map<String, dynamic>?>.data(null)
        : ref.watch(todayDailyGoalsProvider(uid));
    final dailyGoals = dailyGoalsAsync.valueOrNull;
    final waterTarget = (dailyGoals?['waterLiters'] as num?)?.toDouble() ?? 0.0;
    final stepsTarget = (dailyGoals?['steps'] as num?)?.toInt() ?? 0;
    final sleepTarget = (dailyGoals?['sleepHours'] as num?)?.toDouble() ?? 0.0;

    // GoalService defaults used for calorie adjustment fallback
    final defaultGoals = GoalService.computeTodayGoals(profile: profile, preferences: prefs);

    final baseCalories = predictions?.calorieTarget ?? profile?.tdee ?? 2166.0;
    double targetCalDouble = baseCalories;

    // Use user-entered goals for calorie adjustments, fall back to defaults
    final effectiveSteps = stepsTarget > 0 ? stepsTarget : defaultGoals.stepsTarget;
    final effectiveSleep = sleepTarget > 0 ? sleepTarget : defaultGoals.sleepHours;

    const baselineSteps = 10000;
    final stepsDelta = (effectiveSteps - baselineSteps).toDouble();
    targetCalDouble += (stepsDelta * 0.03);

    const baselineSleep = 7.5;
    final sleepDelta = effectiveSleep - baselineSleep;
    targetCalDouble += sleepDelta * 40.0;

    final targetCal = targetCalDouble.round();

    // Use mealPlanProvider (same source as meals preview) for calories consumed
    final todayMealsAsync = ref.watch(mealPlanProvider(today));
    final meals = todayMealsAsync.value ?? const <Meal>[];
    final consumed = meals.fold<int>(0, (sum, m) => sum + m.calories);

    final steps = currentSteps;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            '${Formatters.greeting()}, $name',
            style: AppTypography.textTheme.headlineSmall,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SummaryCard(
              caloriesConsumed: consumed,
              caloriesTarget: targetCal,
              waterLiters: waterTarget,
              steps: steps,
              sleepHours: sleepTarget,
              waterTargetLiters: waterTarget,
              stepsTarget: stepsTarget,
              sleepTargetHours: sleepTarget,
            ),
            const SizedBox(height: 24),
            const StreakCard(),
            const SizedBox(height: 24),
            const RiskSnapshotWidget(),
            const SizedBox(height: 32),
            _SectionHeader(
              title: "Today's Meals",
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MealPlanScreen()),
              ),
            ),
            const SizedBox(height: 16),
            const _MealsPreview(),
            const SizedBox(height: 32),
            _SectionHeader(
              title: "Today's Workout",
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutScreen()),
              ),
            ),
            const SizedBox(height: 16),
            const _WorkoutPreview(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

typedef _TodayWorkoutKey = (String uid, String date);

final _todayWorkoutProvider =
    FutureProvider.family<Map<String, dynamic>?, _TodayWorkoutKey>(
        (ref, key) async {
  final (uid, date) = key;
  return FirestoreService.instance.getWorkoutLog(uid, date);
});

final todayDailyGoalsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
  final today = DateTime.now().toIso8601String().split('T').first;
  return FirestoreService.instance.getDailyGoals(uid, today);
});

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAction;

  const _SectionHeader({required this.title, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.textTheme.headlineSmall,
        ),
        TextButton(
          onPressed: onAction,
          child: const Text('View All'),
        ),
      ],
    );
  }
}

class _MealsPreview extends ConsumerWidget {
  const _MealsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.now().toIso8601String().split('T').first;
    final mealsAsync = ref.watch(mealPlanProvider(date));

    return Container(
      decoration: premiumCardDecoration(),
      padding: const EdgeInsets.all(20),
      child: mealsAsync.when(
        data: (meals) {
            if (meals.isEmpty) {
              return Center(child: Text('No meals planned for today', style: AppTypography.textTheme.bodySmall));
            }

            // Show only the first 5 meals in the Home preview.
            final previewMeals = meals.take(5).toList();

            return Column(
              children: previewMeals.asMap().entries.map((entry) {
                final meal = entry.value;
                final isLast = entry.key == previewMeals.length - 1;
                return Column(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)),
                      ),
                      child: _MealItem(
                        name: meal.name,
                        calories: meal.calories,
                        icon: meal.mealType == 'breakfast' ? LucideIcons.coffee :
                              meal.mealType == 'lunch' ? LucideIcons.utensilsCrossed :
                              meal.mealType == 'dinner' ? LucideIcons.chefHat :
                              meal.mealType == 'night' ? LucideIcons.moon : LucideIcons.apple,
                      ),
                    ),
                    if (!isLast) const Divider(height: 32),
                  ],
                );
              }).toList(),
            );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (_, __) => const Text('Could not load meals'),
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  final String name;
  final int calories;
  final IconData icon;

  const _MealItem({required this.name, required this.calories, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.textTheme.titleMedium),
              Text('$calories kcal', style: AppTypography.textTheme.bodySmall),
            ],
          ),
        ),
        Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
      ],
    );
  }
}

class _WorkoutPreview extends ConsumerWidget {
  const _WorkoutPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authUserIdProvider);
    final today = DateTime.now().toIso8601String().split('T').first;
    final workoutAsync = uid == null
        ? const AsyncValue<Map<String, dynamic>?>.data(null)
        : ref.watch(_todayWorkoutProvider((uid, today)));
    final todayPlanAsync = ref.watch(todayWorkoutProvider);
    final completionMap = ref.watch(exerciseCompletionProvider);

    final workoutData = workoutAsync.value;
    final bool completed = (workoutData?['completed'] as bool?) ?? false;

    // Get today's plan info
    String title = 'Today\'s Workout';
    String subtitle = 'Loading...';
    double progress = 0.0;
    todayPlanAsync.whenData((plan) {
      title = plan.title;
      subtitle = '${plan.durationMinutes} min • ${plan.level} • ${plan.focusArea}';
      final allNames = [
        ...plan.warmUp.map((e) => e.name),
        ...plan.mainExercises.map((e) => e.name),
        ...plan.coolDown.map((e) => e.name),
      ];
      final total = allNames.length;
      final doneCount = allNames.where((n) => completionMap[n] == true).length;
      progress = total == 0 ? 0.0 : doneCount / total;
    });

    final pct = (progress * 100).round();

    return Container(
      decoration: premiumCardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.dumbbell, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.textTheme.titleMedium),
                    Text(subtitle, style: AppTypography.textTheme.bodySmall),
                  ],
                ),
              ),
              if (completed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.checkCircle2,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Done today',
                        style: GoogleFonts.poppins(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (progress > 0 && !completed) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$pct%',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                );
              },
              child: const Text('Open Workout'),
            ),
          ),
        ],
      ),
    );
  }
}
