import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/models/habit.dart';
import 'package:health_nutrition_app/services/firestore_service.dart';
import 'package:health_nutrition_app/features/auth/providers/auth_provider.dart';
import 'streak_provider.dart';

final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final String response = await rootBundle.loadString('assets/data/badges_data.json');
  final data = await json.decode(response) as Map<String, dynamic>;
  final habitsData = data['habits'] as List;
  return habitsData.map((h) => Habit.fromJson(h)).toList();
});

final badgesProvider = FutureProvider<List<Badge>>((ref) async {
  final String response = await rootBundle.loadString('assets/data/badges_data.json');
  final data = await json.decode(response) as Map<String, dynamic>;
  final badgesData = data['badges'] as List;
  return badgesData.map((b) => Badge.fromJson(b)).toList();
});

final dailyHabitCompletionProvider = StateProvider<Map<String, bool>>((ref) {
  return {};
});

final habitTrackerProvider = StateNotifierProvider<HabitTrackerNotifier, Map<String, bool>>((ref) {
  final userId = ref.watch(authUserIdProvider);
  return HabitTrackerNotifier(userId, ref);
});

class HabitTrackerNotifier extends StateNotifier<Map<String, bool>> {
  final String? _userId;
  final Ref _ref;

  HabitTrackerNotifier(this._userId, this._ref) : super({}) {
    _loadHabitStatus();
  }

  Future<void> _loadHabitStatus() async {
    if (_userId == null) return;
    final today = DateTime.now().toIso8601String().split('T').first;
    final habitLog = await FirestoreService.instance.getHabitLog(_userId!, today);
    state = habitLog;
  }

  Future<void> toggleHabit(String habitId, bool isCompleted) async {
    if (_userId == null) return;
    final today = DateTime.now().toIso8601String().split('T').first;
    
    state = {
      ...state,
      habitId: isCompleted,
    };

    await FirestoreService.instance.updateHabitLog(_userId!, today, state);
    
    // Invalidate providers that depend on habit changes
    _ref.invalidate(streakFutureProvider); 
  }
}
