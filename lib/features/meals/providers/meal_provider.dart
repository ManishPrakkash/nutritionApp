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

/// Get weekly meal plan (next 7 days starting from TOMORROW — today is in Daily tab)
final weeklyMealPlanProvider = FutureProvider<Map<String, List<Meal>>>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return {};
  final profile = await ref.watch(profileFutureProvider.future);
  final prefs = await ref.watch(preferencesFutureProvider.future);
  final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T').first;
  return ApiService.instance.getWeeklyMealPlan(uid, tomorrow, profile: profile, prefs: prefs);
});

/// Get monthly meal plan for the FULL current calendar month (1st to last day).
/// Resets automatically when the month changes.
final monthlyMealPlanProvider = FutureProvider<Map<String, List<Meal>>>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return {};
  final profile = await ref.watch(profileFutureProvider.future);
  final prefs = await ref.watch(preferencesFutureProvider.future);
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  return ApiService.instance.getMonthlyMealPlan(
    uid, firstOfMonth, daysCount: daysInMonth, profile: profile, prefs: prefs,
  );
});
