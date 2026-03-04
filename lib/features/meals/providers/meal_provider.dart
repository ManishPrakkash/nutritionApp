import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/meal.dart';
import '../../../services/api_service.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService.instance);

final mealPlanProvider = FutureProvider.family<List<Meal>, String>((ref, date) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return [];
  final profile = await ref.watch(profileFutureProvider.future);
  final prefs = await ref.watch(preferencesFutureProvider.future);
  return ApiService.instance.getMealPlan(uid, date, profile: profile, prefs: prefs);
});

/// Last N days date strings (oldest first).
List<String> lastNDays(int n) {
  final now = DateTime.now();
  return List.generate(n, (i) {
    final d = now.subtract(Duration(days: n - 1 - i));
    return d.toIso8601String().split('T').first;
  });
}

class DayMealSummary {
  final String date;
  final int totalCal;
  final int mealCount;

  const DayMealSummary({required this.date, required this.totalCal, required this.mealCount});
}

final weeklyMealSummaryProvider = FutureProvider<List<DayMealSummary>>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return [];
  final dates = lastNDays(7);
  final list = <DayMealSummary>[];
  for (final d in dates) {
    final meals = await FirestoreService.instance.getMealLog(uid, d);
    final totalCal = meals.fold<int>(0, (s, m) => s + m.calories);
    list.add(DayMealSummary(date: d, totalCal: totalCal, mealCount: meals.length));
  }
  return list;
});

final monthlyMealSummaryProvider = FutureProvider<List<DayMealSummary>>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return [];
  final dates = lastNDays(30);
  final list = <DayMealSummary>[];
  for (final d in dates) {
    final meals = await FirestoreService.instance.getMealLog(uid, d);
    final totalCal = meals.fold<int>(0, (s, m) => s + m.calories);
    list.add(DayMealSummary(date: d, totalCal: totalCal, mealCount: meals.length));
  }
  return list;
});

/// Get alternative meals for a specific meal
final mealAlternativesProvider = FutureProvider.family<List<Meal>, Map<String, String>>((ref, params) async {
  final profile = await ref.watch(profileFutureProvider.future);
  final prefs = await ref.watch(preferencesFutureProvider.future);
  return ApiService.instance.getMealAlternatives(
    params['mealId']!,
    params['mealType']!,
    profile: profile,
    prefs: prefs,
  );
});

/// Get weekly meal plan (future 7 days)
final weeklyMealPlanProvider = FutureProvider<Map<String, List<Meal>>>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return {};
  final profile = await ref.watch(profileFutureProvider.future);
  final prefs = await ref.watch(preferencesFutureProvider.future);
  final today = DateTime.now().toIso8601String().split('T').first;
  return ApiService.instance.getWeeklyMealPlan(uid, today, profile: profile, prefs: prefs);
});

/// Get monthly meal plan (future 30 days)
final monthlyMealPlanProvider = FutureProvider<Map<String, List<Meal>>>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return {};
  final profile = await ref.watch(profileFutureProvider.future);
  final prefs = await ref.watch(preferencesFutureProvider.future);
  final today = DateTime.now().toIso8601String().split('T').first;
  return ApiService.instance.getMonthlyMealPlan(uid, today, profile: profile, prefs: prefs);
});
