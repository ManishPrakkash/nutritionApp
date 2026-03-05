import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/meal.dart';
import '../../../services/api_service.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService.instance);

/// Tracks meal swap overrides keyed by "date:mealType" so a swap in any
/// view (Daily / Weekly / Monthly) is reflected everywhere.
class MealSwapNotifier extends StateNotifier<Map<String, Meal>> {
  MealSwapNotifier() : super({});

  /// Record a swap. [date] is ISO date string, [mealType] e.g. breakfast.
  void recordSwap(String date, String mealType, Meal replacement) {
    final key = '$date:${mealType.toLowerCase()}';
    state = {...state, key: replacement};
  }
}

final mealSwapOverridesProvider =
    StateNotifierProvider<MealSwapNotifier, Map<String, Meal>>(
        (ref) => MealSwapNotifier());

/// Apply swap overrides to a list of meals for a specific [date].
List<Meal> _applySwaps(List<Meal> meals, Map<String, Meal> overrides, String date) {
  if (overrides.isEmpty) return meals;
  return meals.map((m) {
    final key = '$date:${m.mealType.toLowerCase()}';
    return overrides[key] ?? m;
  }).toList();
}

/// Apply swap overrides to a map of date → meals.
Map<String, List<Meal>> _applySwapsToMap(
    Map<String, List<Meal>> planMap, Map<String, Meal> overrides) {
  if (overrides.isEmpty) return planMap;
  return planMap.map((date, meals) => MapEntry(date, _applySwaps(meals, overrides, date)));
}

/// Merge isEaten flags from Firestore into a list of meals.
/// Matches by meal type (breakfast, lunch, etc.) since meal ids may differ.
List<Meal> _mergeIsEaten(List<Meal> meals, List<Meal> stored) {
  if (stored.isEmpty) return meals;
  // Build set of mealType:id that are eaten in Firestore
  final eatenByType = <String, bool>{};
  final eatenById = <String, bool>{};
  for (final s in stored) {
    if (s.isEaten) {
      eatenByType[s.mealType.toLowerCase()] = true;
      eatenById[s.id] = true;
    }
  }
  return meals.map((m) {
    if (eatenById.containsKey(m.id) || eatenByType.containsKey(m.mealType.toLowerCase())) {
      return m.copyWith(isEaten: true);
    }
    return m;
  }).toList();
}

/// Merge isEaten flags across a date→meals map.
Future<Map<String, List<Meal>>> _mergeIsEatenMap(
    String uid, Map<String, List<Meal>> planMap) async {
  final result = <String, List<Meal>>{};
  for (final entry in planMap.entries) {
    try {
      final stored = await FirestoreService.instance.getMealLog(uid, entry.key);
      result[entry.key] = _mergeIsEaten(entry.value, stored);
    } catch (_) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}

final mealPlanProvider = FutureProvider.family<List<Meal>, String>((ref, date) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return [];
  final profile = await ref.watch(profileFutureProvider.future);
  final prefs = await ref.watch(preferencesFutureProvider.future);
  final overrides = ref.watch(mealSwapOverridesProvider);
  final meals = await ApiService.instance.getMealPlan(uid, date, profile: profile, prefs: prefs);
  final swapped = _applySwaps(meals, overrides, date);
  // Merge isEaten flags from Firestore so done states survive rebuilds
  final stored = await FirestoreService.instance.getMealLog(uid, date);
  final result = _mergeIsEaten(swapped, stored);
  // Persist only if no stored data yet (first load); otherwise let
  // the UI (toggleDone / handleSwap) manage saves to avoid clobbering isEaten.
  if (stored.isEmpty) {
    FirestoreService.instance.saveMealLog(uid, date, result);
  }
  return result;
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
  final overrides = ref.watch(mealSwapOverridesProvider);
  final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T').first;
  final plan = await ApiService.instance.getWeeklyMealPlan(uid, tomorrow, profile: profile, prefs: prefs);
  final swapped = _applySwapsToMap(plan, overrides);
  // Merge isEaten flags from Firestore so done states survive rebuilds
  return _mergeIsEatenMap(uid, swapped);
});

/// Get monthly meal plan for the FULL current calendar month (1st to last day).
/// Resets automatically when the month changes.
final monthlyMealPlanProvider = FutureProvider<Map<String, List<Meal>>>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return {};
  final profile = await ref.watch(profileFutureProvider.future);
  final prefs = await ref.watch(preferencesFutureProvider.future);
  final overrides = ref.watch(mealSwapOverridesProvider);
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final plan = await ApiService.instance.getMonthlyMealPlan(
    uid, firstOfMonth, daysCount: daysInMonth, profile: profile, prefs: prefs,
  );
  return _applySwapsToMap(plan, overrides);
});
