import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import '../models/workout.dart';

class WorkoutService {
  WorkoutService._();
  static final WorkoutService instance = WorkoutService._();

  List<WorkoutPlan>? _allWorkouts;

  Future<void> _load() async {
    if (_allWorkouts != null) return;
    final raw = await rootBundle.loadString('assets/data/workout_registry.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final list = data['workouts'] as List;
    _allWorkouts = list.map((w) => WorkoutPlan.fromJson(w)).toList();
  }

  /// All workouts in the registry (for the library screen).
  Future<List<WorkoutPlan>> getWorkoutPlans() async {
    await _load();
    return _allWorkouts!;
  }

  /// Get today's workout based on user's activity level and date-based rotation.
  /// Uses dayIndex 1-35 mapped from (day-of-month) so it rotates monthly.
  Future<WorkoutPlan> getTodayWorkout(String activityLevel, {DateTime? date}) async {
    await _load();
    final now = date ?? DateTime.now();
    // Map activity level to pool; default to moderate
    final level = activityLevel.toLowerCase();
    final pool = _allWorkouts!.where((w) => w.activityLevel == level).toList();
    if (pool.isEmpty) {
      // Fallback to moderate
      final mod = _allWorkouts!.where((w) => w.activityLevel == 'moderate').toList();
      if (mod.isEmpty) return _allWorkouts!.first;
      final idx = ((now.day - 1) % mod.length);
      return mod[idx];
    }
    // day 1 -> dayIndex 1, day 31 -> dayIndex 31 (wraps within 35)
    final idx = ((now.day - 1) % pool.length);
    return pool[idx];
  }

  /// Get the full month workout plan for the current calendar month.
  /// Returns a map from day number (1-based) to [WorkoutPlan].
  Future<Map<int, WorkoutPlan>> getMonthlyWorkoutPlan(String activityLevel, {DateTime? date}) async {
    await _load();
    final now = date ?? DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final level = activityLevel.toLowerCase();
    var pool = _allWorkouts!.where((w) => w.activityLevel == level).toList();
    if (pool.isEmpty) {
      pool = _allWorkouts!.where((w) => w.activityLevel == 'moderate').toList();
    }
    if (pool.isEmpty) pool = _allWorkouts!;

    final plan = <int, WorkoutPlan>{};
    for (int d = 1; d <= daysInMonth; d++) {
      plan[d] = pool[(d - 1) % pool.length];
    }
    return plan;
  }
}