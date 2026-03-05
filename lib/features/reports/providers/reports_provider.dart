import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../home/services/goal_service.dart';

// ---------------------------------------------------------------------------
// Shared date helpers
// ---------------------------------------------------------------------------

List<String> last7Days() {
  final now = DateTime.now();
  return List.generate(7, (i) {
    final d = now.subtract(Duration(days: 6 - i));
    return d.toIso8601String().split('T').first;
  });
}

/// Week report: weightData (7 values), calorieData (7 values), meanCalorie, sleepHours.
class WeekReportData {
  final List<double> weightData;
  final List<int> calorieData;
  final List<int> stepsData;
  final List<int> burnedCalorieData;
  final List<double> waterData;
  final double meanCalorie;
  final double sleepHours;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const WeekReportData({
    required this.weightData,
    required this.calorieData,
    required this.stepsData,
    required this.burnedCalorieData,
    required this.waterData,
    required this.meanCalorie,
    required this.sleepHours,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });
}

final weekReportProvider = FutureProvider<WeekReportData>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return _emptyWeekReport();
  final dates = last7Days();

  // Weight Logic — safe
  final weightByDate = <String, double>{};
  try {
    final weightLogs = await FirestoreService.instance.getWeightLogs(uid, limit: 14);
    for (final w in weightLogs) {
      final dateStr = (w['date'] as String?)?.split('T').first;
      if (dateStr != null) weightByDate[dateStr] = (w['weight'] as num).toDouble();
    }
  } catch (_) {/* use defaults */}

  // Calories / Macros Logic — safe per day
  final calorieData = <int>[];
  int totalCalConsumed = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;

  for (final d in dates) {
    try {
      final meals = await FirestoreService.instance.getMealLog(uid, d);
      final cal = meals.fold<int>(0, (s, m) => s + m.calories);
      calorieData.add(cal);
      totalCalConsumed += cal;
      totalProtein += meals.fold<double>(0, (s, m) => s + m.protein);
      totalCarbs += meals.fold<double>(0, (s, m) => s + m.carbs);
      totalFat += meals.fold<double>(0, (s, m) => s + m.fat);
    } catch (_) {
      calorieData.add(0);
    }
  }
  final meanCalorie = calorieData.isEmpty ? 0.0 : totalCalConsumed / calorieData.length;

  // Device Data (Steps, Burned, Sleep) — safe
  final deviceDataMap = <String, Map<String, dynamic>>{};
  try {
    final startDate = dates.first;
    final endDate = dates.last;
    final deviceList = await FirestoreService.instance.getDeviceDataRange(uid, startDate, endDate);
    for (final dev in deviceList) {
      if (dev['date'] != null) deviceDataMap[dev['date']] = dev;
    }
  } catch (_) {/* no device data */}

  final weightData = <double>[];
  final stepsData = <int>[];
  final burnedCalorieData = <int>[];
  double? lastWeight;
  double totalSleep = 0;
  int sleepCount = 0;

  for (final d in dates) {
    lastWeight = weightByDate[d] ?? lastWeight ?? 70.0;
    weightData.add(lastWeight);

    final dev = deviceDataMap[d] ?? {};
    final steps = (dev['steps'] as num?)?.toInt() ?? 0;
    stepsData.add(steps);

    final burned = (dev['calories_burned'] as num?)?.toInt() ?? (steps * 0.04).round();
    burnedCalorieData.add(burned);

    final s = dev['sleep_hours'];
    if (s != null) {
      totalSleep += (s as num).toDouble();
      sleepCount++;
    }
  }

  final sleepHours = sleepCount > 0 ? totalSleep / sleepCount : 6.8;

  // Hydration data — safe per day
  final waterData = <double>[];
  for (final d in dates) {
    try {
      final goals = await FirestoreService.instance.getDailyGoals(uid, d);
      final w = (goals?['waterLiters'] as num?)?.toDouble() ?? 0.0;
      waterData.add(w);
    } catch (_) {
      waterData.add(0.0);
    }
  }

  return WeekReportData(
    weightData: weightData,
    calorieData: calorieData,
    stepsData: stepsData,
    burnedCalorieData: burnedCalorieData,
    waterData: waterData,
    meanCalorie: meanCalorie,
    sleepHours: sleepHours,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
  );
});

WeekReportData _emptyWeekReport() {
  return WeekReportData(
    weightData: List.generate(7, (_) => 70.0),
    calorieData: List.generate(7, (_) => 0),
    stepsData: List.generate(7, (_) => 0),
    burnedCalorieData: List.generate(7, (_) => 0),
    waterData: List.generate(7, (_) => 0.0),
    meanCalorie: 0,
    sleepHours: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
  );
}

// ---------------------------------------------------------------------------
// Unified Performance Report Data — single page
// ---------------------------------------------------------------------------

class PerformanceReportData {
  final double nutritionScore;
  final double activityScore;
  final double sleepScore;
  final double hydrationScore;

  final int totalCalories;
  final double avgCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int mealsEaten;
  final int totalMeals;

  final int workoutsCompleted;
  final int totalWorkoutDays;
  final double workoutCompletionPct;
  final int totalSteps;
  final int avgSteps;

  final double avgSleep;
  final double avgWater;

  final double currentWeight;
  final double targetCalories;
  final int targetSteps;
  final double targetWater;
  final double targetSleep;

  final String activityLevel;
  final String healthGoal;
  final String reportDate;

  const PerformanceReportData({
    required this.nutritionScore,
    required this.activityScore,
    required this.sleepScore,
    required this.hydrationScore,
    required this.totalCalories,
    required this.avgCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.mealsEaten,
    required this.totalMeals,
    required this.workoutsCompleted,
    required this.totalWorkoutDays,
    this.workoutCompletionPct = 0.0,
    required this.totalSteps,
    required this.avgSteps,
    required this.avgSleep,
    required this.avgWater,
    required this.currentWeight,
    required this.targetCalories,
    required this.targetSteps,
    required this.targetWater,
    required this.targetSleep,
    required this.activityLevel,
    required this.healthGoal,
    required this.reportDate,
  });

  PerformanceReportData copyWith({
    double? nutritionScore,
    double? activityScore,
    double? sleepScore,
    double? hydrationScore,
    int? totalCalories,
    double? avgCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    int? mealsEaten,
    int? totalMeals,
    int? workoutsCompleted,
    int? totalWorkoutDays,
    double? workoutCompletionPct,
    int? totalSteps,
    int? avgSteps,
    double? avgSleep,
    double? avgWater,
    double? currentWeight,
    double? targetCalories,
    int? targetSteps,
    double? targetWater,
    double? targetSleep,
    String? activityLevel,
    String? healthGoal,
    String? reportDate,
  }) {
    return PerformanceReportData(
      nutritionScore: nutritionScore ?? this.nutritionScore,
      activityScore: activityScore ?? this.activityScore,
      sleepScore: sleepScore ?? this.sleepScore,
      hydrationScore: hydrationScore ?? this.hydrationScore,
      totalCalories: totalCalories ?? this.totalCalories,
      avgCalories: avgCalories ?? this.avgCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      mealsEaten: mealsEaten ?? this.mealsEaten,
      totalMeals: totalMeals ?? this.totalMeals,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      totalWorkoutDays: totalWorkoutDays ?? this.totalWorkoutDays,
      workoutCompletionPct: workoutCompletionPct ?? this.workoutCompletionPct,
      totalSteps: totalSteps ?? this.totalSteps,
      avgSteps: avgSteps ?? this.avgSteps,
      avgSleep: avgSleep ?? this.avgSleep,
      avgWater: avgWater ?? this.avgWater,
      currentWeight: currentWeight ?? this.currentWeight,
      targetCalories: targetCalories ?? this.targetCalories,
      targetSteps: targetSteps ?? this.targetSteps,
      targetWater: targetWater ?? this.targetWater,
      targetSleep: targetSleep ?? this.targetSleep,
      activityLevel: activityLevel ?? this.activityLevel,
      healthGoal: healthGoal ?? this.healthGoal,
      reportDate: reportDate ?? this.reportDate,
    );
  }
}

final performanceReportProvider =
    AsyncNotifierProvider<PerformanceReportNotifier, PerformanceReportData>(
        PerformanceReportNotifier.new);

class PerformanceReportNotifier extends AsyncNotifier<PerformanceReportData> {
  @override
  Future<PerformanceReportData> build() async {
    ref.keepAlive();
    return _loadFromFirestore();
  }

  /// Instant in-memory update when a meal is toggled eaten/uneaten.
  void onMealToggled({required bool nowEaten}) {
    final current = state.valueOrNull;
    if (current == null) return;
    final delta = nowEaten ? 1 : -1;
    final newEaten = (current.mealsEaten + delta).clamp(0, current.totalMeals);
    final mealPct = current.totalMeals > 0 ? newEaten / current.totalMeals : 0.0;
    final calRatio = current.targetCalories > 0
        ? current.avgCalories / current.targetCalories
        : 0.0;
    final calScore = calRatio > 1.0
        ? (2.0 - calRatio).clamp(0.0, 1.0)
        : calRatio.clamp(0.0, 1.0);
    final newNutritionScore =
        ((mealPct * 0.4 + calScore * 0.6) * 100).clamp(0.0, 100.0);
    state = AsyncData(current.copyWith(
      mealsEaten: newEaten,
      nutritionScore: newNutritionScore,
    ));
  }

  /// Instant in-memory update when workout exercise completion changes.
  void onWorkoutPctChanged(double pct) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(workoutCompletionPct: pct));
  }

  Future<PerformanceReportData> _loadFromFirestore() async {
    final uid = ref.watch(authUserIdProvider);
    final now = DateTime.now();
    final reportDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    if (uid == null) {
      return _fallbackReport(
        targetCalories: 2100,
        targetSteps: 10000,
        targetWater: 2.5,
        targetSleep: 7.5,
        currentWeight: 70.0,
        activityLevel: 'moderate',
        healthGoal: 'maintain_weight',
        reportDate: reportDate,
      );
    }

    final profile = await ref.watch(profileFutureProvider.future);
    final prefs = await ref.watch(preferencesFutureProvider.future);

    final goals =
        GoalService.computeTodayGoals(profile: profile, preferences: prefs);
    final activityLevel = prefs?.activityLevel ?? 'moderate';
    final healthGoal = prefs?.healthGoal ?? 'maintain_weight';
    final targetCalories = profile?.tdee ?? 2100.0;
    final currentWeight = profile?.weightKg ?? 70.0;

    final todayDate = now.toIso8601String().split('T').first;
    final userDayGoals =
        await FirestoreService.instance.getDailyGoals(uid, todayDate);
    final userWater = (userDayGoals?['waterLiters'] as num?)?.toDouble();
    final userSteps = (userDayGoals?['steps'] as num?)?.toInt();
    final userSleep = (userDayGoals?['sleepHours'] as num?)?.toDouble();
    final targetSteps = (userSteps != null && userSteps > 0)
        ? userSteps
        : goals.stepsTarget;
    final targetWater = (userWater != null && userWater > 0)
        ? userWater
        : goals.waterLiters;
    final targetSleep = (userSleep != null && userSleep > 0)
        ? userSleep
        : goals.sleepHours;

    final dates = last7Days();

    // ── Meals data ──
    int totalCal = 0;
    double totalProtein = 0, totalCarbs = 0, totalFat = 0;
    int mealsEaten = 0, totalMeals = 0;

    for (final d in dates) {
      try {
        final meals = await FirestoreService.instance.getMealLog(uid, d);
        for (final m in meals) {
          totalMeals++;
          totalCal += m.calories;
          totalProtein += m.protein;
          totalCarbs += m.carbs;
          totalFat += m.fat;
          if (m.isEaten) mealsEaten++;
        }
      } catch (_) {}
    }
    final avgCalories = dates.isEmpty ? 0.0 : totalCal / dates.length;

    // ── Workout completions & today's exercise pct ──
    int workoutsCompleted = 0;
    double todayWorkoutPct = 0.0;
    for (final d in dates) {
      try {
        final wLog = await FirestoreService.instance.getWorkoutLog(uid, d);
        if (wLog != null && wLog['completed'] == true) workoutsCompleted++;
        if (d == todayDate && wLog != null) {
          final ce = wLog['completedExercises'] as Map<String, dynamic>?;
          if (ce != null && ce.isNotEmpty) {
            final done = ce.values.where((v) => v == true).length;
            todayWorkoutPct = (done / ce.length * 100).clamp(0.0, 100.0);
          }
        }
      } catch (_) {}
    }

    // ── Device data (steps, sleep) ──
    int totalSteps = 0;
    double totalSleep = 0;
    int sleepDays = 0;

    final deviceDataMap = <String, Map<String, dynamic>>{};
    try {
      final deviceList = await FirestoreService.instance
          .getDeviceDataRange(uid, dates.first, dates.last);
      for (final dev in deviceList) {
        if (dev['date'] != null) deviceDataMap[dev['date']] = dev;
      }
    } catch (_) {}

    for (final d in dates) {
      final dev = deviceDataMap[d] ?? {};
      totalSteps += (dev['steps'] as num?)?.toInt() ?? 0;
      final s = dev['sleep_hours'];
      if (s != null) {
        totalSleep += (s as num).toDouble();
        sleepDays++;
      }
    }
    final avgSteps = dates.isEmpty ? 0 : totalSteps ~/ dates.length;
    final avgSleep = sleepDays > 0 ? totalSleep / sleepDays : 0.0;

    // ── Hydration ──
    double totalWater = 0;
    int waterDays = 0;
    for (final d in dates) {
      try {
        final g = await FirestoreService.instance.getDailyGoals(uid, d);
        final w = (g?['waterLiters'] as num?)?.toDouble() ?? 0.0;
        if (w > 0) {
          totalWater += w;
          waterDays++;
        }
      } catch (_) {}
    }
    final avgWater = waterDays > 0 ? totalWater / waterDays : 0.0;

    // ── Compute scores ──
    final hasNutritionData = totalCal > 0 || mealsEaten > 0;
    final hasActivityData = totalSteps > 0 || workoutsCompleted > 0;
    final hasSleepData = sleepDays > 0;
    final hasHydrationData = waterDays > 0;

    double nutritionScore;
    if (hasNutritionData) {
      final mealPct = totalMeals > 0 ? mealsEaten / totalMeals : 0.0;
      final calRatio =
          targetCalories > 0 ? avgCalories / targetCalories : 0.0;
      final calScore = calRatio > 1.0
          ? (2.0 - calRatio).clamp(0.0, 1.0)
          : calRatio.clamp(0.0, 1.0);
      nutritionScore =
          ((mealPct * 0.4 + calScore * 0.6) * 100).clamp(0.0, 100.0);
    } else {
      nutritionScore = _fallbackNutritionScore(activityLevel);
    }

    double activityScore;
    if (hasActivityData) {
      final stepRatio =
          targetSteps > 0 ? (avgSteps / targetSteps).clamp(0.0, 1.0) : 0.0;
      final workoutRatio = dates.isNotEmpty
          ? (workoutsCompleted / dates.length).clamp(0.0, 1.0)
          : 0.0;
      activityScore =
          ((stepRatio * 0.5 + workoutRatio * 0.5) * 100).clamp(0.0, 100.0);
    } else {
      activityScore = _fallbackActivityScore(activityLevel);
    }

    double sleepScore;
    if (hasSleepData) {
      final sleepRatio = targetSleep > 0 ? avgSleep / targetSleep : 0.0;
      sleepScore = ((sleepRatio > 1.0
                  ? (2.0 - sleepRatio).clamp(0.0, 1.0)
                  : sleepRatio.clamp(0.0, 1.0)) *
              100)
          .clamp(0.0, 100.0);
    } else {
      sleepScore = _fallbackSleepScore(activityLevel);
    }

    double hydrationScore;
    if (hasHydrationData) {
      hydrationScore =
          (targetWater > 0 ? (avgWater / targetWater) * 100 : 0.0)
              .clamp(0.0, 100.0);
    } else {
      hydrationScore = _fallbackHydrationScore(activityLevel);
    }

    return PerformanceReportData(
      nutritionScore: nutritionScore,
      activityScore: activityScore,
      sleepScore: sleepScore,
      hydrationScore: hydrationScore,
      totalCalories: totalCal,
      avgCalories: avgCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      mealsEaten: mealsEaten,
      totalMeals: totalMeals,
      workoutsCompleted: workoutsCompleted,
      totalWorkoutDays: dates.length,
      workoutCompletionPct: todayWorkoutPct,
      totalSteps: totalSteps,
      avgSteps: avgSteps,
      avgSleep: avgSleep,
      avgWater: avgWater,
      currentWeight: currentWeight,
      targetCalories: targetCalories,
      targetSteps: targetSteps,
      targetWater: targetWater,
      targetSleep: targetSleep,
      activityLevel: activityLevel,
      healthGoal: healthGoal,
      reportDate: reportDate,
    );
  }
}

// ---------------------------------------------------------------------------
// Fallback helpers — reasonable scores from activity level
// ---------------------------------------------------------------------------

double _fallbackNutritionScore(String level) {
  switch (level) {
    case 'sedentary': return 55;
    case 'light': return 60;
    case 'moderate': return 65;
    case 'active': return 72;
    case 'extreme': return 78;
    default: return 62;
  }
}

double _fallbackActivityScore(String level) {
  switch (level) {
    case 'sedentary': return 30;
    case 'light': return 45;
    case 'moderate': return 58;
    case 'active': return 70;
    case 'extreme': return 82;
    default: return 50;
  }
}

double _fallbackSleepScore(String level) {
  switch (level) {
    case 'sedentary': return 72;
    case 'light': return 70;
    case 'moderate': return 75;
    case 'active': return 68;
    case 'extreme': return 65;
    default: return 72;
  }
}

double _fallbackHydrationScore(String level) {
  switch (level) {
    case 'sedentary': return 40;
    case 'light': return 50;
    case 'moderate': return 55;
    case 'active': return 62;
    case 'extreme': return 68;
    default: return 50;
  }
}

PerformanceReportData _fallbackReport({
  required double targetCalories,
  required int targetSteps,
  required double targetWater,
  required double targetSleep,
  required double currentWeight,
  required String activityLevel,
  required String healthGoal,
  required String reportDate,
}) {
  return PerformanceReportData(
    nutritionScore: _fallbackNutritionScore(activityLevel),
    activityScore: _fallbackActivityScore(activityLevel),
    sleepScore: _fallbackSleepScore(activityLevel),
    hydrationScore: _fallbackHydrationScore(activityLevel),
    totalCalories: (targetCalories * 6.5).round(),
    avgCalories: targetCalories * 0.93,
    totalProtein: 420,
    totalCarbs: 1050,
    totalFat: 350,
    mealsEaten: 18,
    totalMeals: 21,
    workoutsCompleted: 4,
    totalWorkoutDays: 7,
    workoutCompletionPct: 57.0,
    totalSteps: targetSteps * 5,
    avgSteps: (targetSteps * 0.72).round(),
    avgSleep: targetSleep * 0.9,
    avgWater: targetWater * 0.55,
    currentWeight: currentWeight,
    targetCalories: targetCalories,
    targetSteps: targetSteps,
    targetWater: targetWater,
    targetSleep: targetSleep,
    activityLevel: activityLevel,
    healthGoal: healthGoal,
    reportDate: reportDate,
  );
}
