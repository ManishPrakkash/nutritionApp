import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/workout.dart';
import '../../../services/workout_service.dart';

final workoutPlansProvider = FutureProvider<List<WorkoutPlan>>((ref) async {
  return WorkoutService().getWorkoutPlans();
});