import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

/// Full workout library (all levels).
final workoutPlansProvider = FutureProvider<List<WorkoutPlan>>((ref) async {
  return WorkoutService.instance.getWorkoutPlans();
});

/// Today's workout based on user's activity-level preference.
final todayWorkoutProvider = FutureProvider<WorkoutPlan>((ref) async {
  final prefs = await ref.watch(preferencesFutureProvider.future);
  final level = prefs?.activityLevel ?? 'moderate';
  return WorkoutService.instance.getTodayWorkout(level);
});

/// Monthly workout calendar for the current month.
final monthlyWorkoutPlanProvider = FutureProvider<Map<int, WorkoutPlan>>((ref) async {
  final prefs = await ref.watch(preferencesFutureProvider.future);
  final level = prefs?.activityLevel ?? 'moderate';
  return WorkoutService.instance.getMonthlyWorkoutPlan(level);
});

/// Track which exercises have been checked off today.
/// Key = exercise name, Value = completed.
/// Scoped to the specific workout (by workoutId) so changing preferences resets progress.
class ExerciseCompletionNotifier extends StateNotifier<Map<String, bool>> {
  final String? _uid;
  final String _date;
  final String _workoutId;

  ExerciseCompletionNotifier(this._uid, this._date, this._workoutId) : super({}) {
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    if (_uid == null) return;
    final data = await FirestoreService.instance.getWorkoutLog(_uid, _date);
    if (data == null || !mounted) return;
    // Only restore completion if the stored workoutId matches current workout
    final storedId = data['workoutId'] as String? ?? '';
    if (storedId != _workoutId) {
      // Different workout → start fresh (clear old data)
      if (mounted) state = {};
      return;
    }
    final exercises = data['completedExercises'] as Map<String, dynamic>? ?? {};
    if (mounted) state = exercises.map((k, v) => MapEntry(k, v == true));
  }

  void toggle(String exerciseName) {
    final current = Map<String, bool>.from(state);
    current[exerciseName] = !(current[exerciseName] ?? false);
    state = current;
    _persist();
  }

  int get completedCount => state.values.where((v) => v).length;

  double progress(int total) => total == 0 ? 0 : completedCount / total;

  Future<void> _persist() async {
    if (_uid == null) return;
    await FirestoreService.instance.saveWorkoutExerciseCompletion(
      _uid, _date, _workoutId, state,
    );
  }
}

final exerciseCompletionProvider =
    StateNotifierProvider<ExerciseCompletionNotifier, Map<String, bool>>((ref) {
  final uid = ref.watch(authUserIdProvider);
  final date = DateTime.now().toIso8601String().split('T').first;
  // Watch todayWorkoutProvider so completion resets when workout changes
  final todayPlan = ref.watch(todayWorkoutProvider);
  final workoutId = todayPlan.valueOrNull?.id ?? '';
  return ExerciseCompletionNotifier(uid, date, workoutId);
});
