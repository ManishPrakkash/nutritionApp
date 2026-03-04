import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import '../models/workout.dart';

class WorkoutService {
  Future<List<WorkoutPlan>> getWorkoutPlans() async {
    final String response = await rootBundle.loadString('assets/data/workouts_data.json');
    final data = await json.decode(response) as List;
    return data.map((json) => WorkoutPlan.fromJson(json)).toList();
  }
}