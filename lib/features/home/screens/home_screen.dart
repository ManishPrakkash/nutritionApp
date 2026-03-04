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
import '../../health_risk/providers/predictions_provider.dart';
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
import '../../workout/screens/workout_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/steps_provider.dart';
import '../../streaks/screens/habit_tracker_screen.dart';
import '../services/goal_service.dart';

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
      if (uid != null) {
        await PedometerService.instance.init(uid);
        // Record today's login for streak tracking
        final streakService = ref.read(streakServiceProvider);
        await streakService.recordTodayLogin();
        // Refresh streak providers
        ref.invalidate(currentStreakProvider);
        ref.invalidate(weeklyProgressProvider);
      }
    });
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
    // Use the latest saved prediction snapshot so kcal goal and
    // risk assessment stay static until a new assessment is run.
    final predictions = ref.watch(latestPredictionProvider).valueOrNull;
    final currentSteps = ref.watch(currentStepsProvider);
    final goals = GoalService.computeTodayGoals(profile: profile, preferences: prefs);

    // Derive today's kcal goal from base prediction/TDEE and today's
    // water/steps/sleep/BMI goals. This value is static for the day
    // because `computeTodayGoals` is date-based.
    final baseCalories = predictions?.calorieTarget ?? profile?.tdee ?? 2166.0;

    // Use the goals to nudge the kcal target so it conceptually reflects
    // "for this water/steps/sleep/BMI plan, this many kcal will be done".
    double targetCalDouble = baseCalories;

    // Adjust for steps goal: around ±300 kcal when far from 10k steps.
    const baselineSteps = 10000;
    final stepsDelta = (goals.stepsTarget - baselineSteps).toDouble();
    targetCalDouble += (stepsDelta * 0.03); // 0.03 kcal per step delta

    // Adjust for sleep goal relative to 7.5h.
    const baselineSleep = 7.5;
    final sleepDelta = goals.sleepHours - baselineSleep;
    targetCalDouble += sleepDelta * 40.0; // ~40 kcal per hour difference

    final targetCal = targetCalDouble.round();

    final uid = ref.watch(authUserIdProvider);
    final today = DateTime.now().toIso8601String().split('T').first;
    final todayMealsAsync = uid == null
      ? const AsyncValue<List<Meal>>.data([])
      : ref.watch(_todayMealsProvider((uid, today)));

    final meals = todayMealsAsync.value ?? const <Meal>[];
    final consumed = meals.fold<int>(0, (sum, m) => sum + m.calories);

    // TODO: Wire real water & sleep data from device logs when available.
    final water = 0.0;      // dynamic placeholder until actual intake is tracked
    final steps = currentSteps;
    final sleep = 6.5;      // placeholder for sleep hours from last night

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
              waterLiters: water,
              steps: steps,
              sleepHours: sleep,
              waterTargetLiters: goals.waterLiters,
              stepsTarget: goals.stepsTarget,
              sleepTargetHours: goals.sleepHours,
            ),
            const SizedBox(height: 24),
            const StreakCard(),
            const SizedBox(height: 24),
            RiskSnapshotWidget(
              predictions: ref.watch(latestPredictionProvider).valueOrNull?.predictions,
            ),
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

typedef _TodayKey = (String uid, String date);

final _todayMealsProvider = FutureProvider.family<List<Meal>, _TodayKey>((ref, key) async {
  final (uid, date) = key;
  return FirestoreService.instance.getMealLog(uid, date);
});

typedef _TodayWorkoutKey = (String uid, String date);

final _todayWorkoutProvider =
    FutureProvider.family<Map<String, dynamic>?, _TodayWorkoutKey>(
        (ref, key) async {
  final (uid, date) = key;
  return FirestoreService.instance.getWorkoutLog(uid, date);
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
                              meal.mealType == 'dinner' ? LucideIcons.chefHat : LucideIcons.apple,
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

    final workoutData = workoutAsync.value;
    final bool completed = (workoutData?['completed'] as bool?) ?? false;

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
                    Text('Beginner Home Workout', style: AppTypography.textTheme.titleMedium),
                    Text('30 min • Intermediate', style: AppTypography.textTheme.bodySmall),
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
