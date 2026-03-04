import 'dart:math';

import '../../../core/constants/app_constants.dart';
import '../../../models/user_profile.dart';
import '../../../models/user_preferences.dart';

class DailyGoals {
  final int stepsTarget;
  final double waterLiters;
  final double sleepHours;

  const DailyGoals({
    required this.stepsTarget,
    required this.waterLiters,
    required this.sleepHours,
  });
}

class GoalService {
  GoalService._();

  static DailyGoals computeTodayGoals({
    UserProfile? profile,
    UserPreferences? preferences,
  }) {
    final activity = (preferences?.activityLevel ?? 'moderate').toLowerCase();

    int baseSteps = AppConstants.defaultStepsGoal;
    double baseWater = AppConstants.defaultWaterLiters;
    double baseSleep = AppConstants.defaultSleepHours;

    switch (activity) {
      case 'sedentary':
        baseSteps = 6000;
        baseWater = 2.0;
        baseSleep = 8.0;
        break;
      case 'light':
        baseSteps = 8000;
        baseWater = 2.2;
        baseSleep = 7.5;
        break;
      case 'moderate':
        baseSteps = 10000;
        baseWater = 2.5;
        baseSleep = 7.5;
        break;
      case 'active':
        baseSteps = 12000;
        baseWater = 2.8;
        baseSleep = 7.0;
        break;
      case 'extreme':
        baseSteps = 14000;
        baseWater = 3.0;
        baseSleep = 7.0;
        break;
    }

    // Light day-of-week variation so each day feels slightly different
    final today = DateTime.now();
    final dayIndex = today.weekday; // 1-7
    final variationSeed = today.year * 1000 + today.dayOfYear;
    final rand = Random(variationSeed);

    // Steps vary by ±10%
    final stepsFactor = 0.9 + rand.nextDouble() * 0.2; // 0.9–1.1
    final stepsTarget = (baseSteps * stepsFactor).round();

    // Water varies by ±0.3 L
    final waterDelta = (rand.nextDouble() * 0.6) - 0.3; // -0.3–+0.3
    final waterTarget = (baseWater + waterDelta).clamp(1.5, 3.5);

    // Slightly higher sleep target on weekends
    final isWeekend = dayIndex == DateTime.saturday || dayIndex == DateTime.sunday;
    final sleepTarget = (baseSleep + (isWeekend ? 0.5 : 0.0)).clamp(6.5, 9.0);

    return DailyGoals(
      stepsTarget: stepsTarget,
      waterLiters: double.parse(waterTarget.toStringAsFixed(1)),
      sleepHours: double.parse(sleepTarget.toStringAsFixed(1)),
    );
  }
}

extension on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays + 1;
  }
}
