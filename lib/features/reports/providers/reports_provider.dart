import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Last 7 days (oldest first) for week view: [dateString, ...]
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
  
  // Weight Logic
  final weightLogs = await FirestoreService.instance.getWeightLogs(uid, limit: 14);
  final weightByDate = <String, double>{};
  for (final w in weightLogs) {
    final dateStr = (w['date'] as String?)?.split('T').first;
    if (dateStr != null) weightByDate[dateStr] = (w['weight'] as num).toDouble();
  }
  
  // Calories Consumed Logic
  final calorieData = <int>[];
  int totalCalConsumed = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;

  for (final d in dates) {
    final meals = await FirestoreService.instance.getMealLog(uid, d);
    final cal = meals.fold<int>(0, (s, m) => s + m.calories);
    calorieData.add(cal);
    totalCalConsumed += cal;
    totalProtein += meals.fold<double>(0, (s, m) => s + m.protein);
    totalCarbs += meals.fold<double>(0, (s, m) => s + m.carbs);
    totalFat += meals.fold<double>(0, (s, m) => s + m.fat);
  }
  final meanCalorie = calorieData.isEmpty ? 0.0 : totalCalConsumed / calorieData.length;

  // Device Data (Steps, Burned, Sleep)
  final weightData = <double>[];
  final stepsData = <int>[];
  final burnedCalorieData = <int>[];
  double? lastWeight;
  double totalSleep = 0;
  int sleepCount = 0;

  final startDate = dates.first;
  final endDate = dates.last;
  final deviceDataMap = <String, Map<String, dynamic>>{};
  final deviceList = await FirestoreService.instance.getDeviceDataRange(uid, startDate, endDate);
  for (final dev in deviceList) {
    if (dev['date'] != null) deviceDataMap[dev['date']] = dev;
  }

  for (final d in dates) {
    lastWeight = weightByDate[d] ?? lastWeight ?? 70.0;
    weightData.add(lastWeight);

    final dev = deviceDataMap[d] ?? {};
    final steps = (dev['steps'] as num?)?.toInt() ?? 0;
    stepsData.add(steps);

    // Calc burned calories: steps * 0.04 + BMR part (simplified)
    final burned = (dev['calories_burned'] as num?)?.toInt() ?? (steps * 0.04).round();
    burnedCalorieData.add(burned);

    final s = dev['sleep_hours'];
    if (s != null) {
      totalSleep += (s as num).toDouble();
      sleepCount++;
    }
  }

  final sleepHours = sleepCount > 0 ? totalSleep / sleepCount : 6.8;

  return WeekReportData(
    weightData: weightData,
    calorieData: calorieData,
    stepsData: stepsData,
    burnedCalorieData: burnedCalorieData,
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
    meanCalorie: 0,
    sleepHours: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
  );
}

/// Last 30 days (oldest first) for month view: [dateString, ...]
List<String> last30Days() {
  final now = DateTime.now();
  return List.generate(30, (i) {
    final d = now.subtract(Duration(days: 29 - i));
    return d.toIso8601String().split('T').first;
  });
}

/// Month report: weightData (30 values), calorieData (30 values), meanCalorie, sleepHours.
class MonthReportData {
  final List<double> weightData;
  final List<int> calorieData;
  final List<int> stepsData;
  final List<int> burnedCalorieData;
  final double meanCalorie;
  final double sleepHours;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const MonthReportData({
    required this.weightData,
    required this.calorieData,
    required this.stepsData,
    required this.burnedCalorieData,
    required this.meanCalorie,
    required this.sleepHours,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });
}

final monthReportProvider = FutureProvider<MonthReportData>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return _emptyMonthReport();
  final dates = last30Days();

  // Weight Logic
  final weightLogs = await FirestoreService.instance.getWeightLogs(uid, limit: 60);
  final weightByDate = <String, double>{};
  for (final w in weightLogs) {
    final dateStr = (w['date'] as String?)?.split('T').first;
    if (dateStr != null) weightByDate[dateStr] = (w['weight'] as num).toDouble();
  }

  // Calories Consumed Logic
  final calorieData = <int>[];
  int totalCalConsumed = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;
  for (final d in dates) {
    final meals = await FirestoreService.instance.getMealLog(uid, d);
    final cal = meals.fold<int>(0, (s, m) => s + m.calories);
    calorieData.add(cal);
    totalCalConsumed += cal;
    totalProtein += meals.fold<double>(0, (s, m) => s + m.protein);
    totalCarbs += meals.fold<double>(0, (s, m) => s + m.carbs);
    totalFat += meals.fold<double>(0, (s, m) => s + m.fat);
  }
  final meanCalorie = calorieData.isEmpty ? 0.0 : totalCalConsumed / calorieData.length;

  // Device Data (Steps, Burned, Sleep)
  final weightData = <double>[];
  final stepsData = <int>[];
  final burnedCalorieData = <int>[];
  double? lastWeight;
  double totalSleep = 0;
  int sleepCount = 0;

  final startDate = dates.first;
  final endDate = dates.last;
  final deviceDataMap = <String, Map<String, dynamic>>{};
  final deviceList = await FirestoreService.instance.getDeviceDataRange(uid, startDate, endDate);
  for (final dev in deviceList) {
    if (dev['date'] != null) deviceDataMap[dev['date']] = dev;
  }

  for (final d in dates) {
    lastWeight = weightByDate[d] ?? lastWeight ?? 70.0;
    weightData.add(lastWeight);

    final dev = deviceDataMap[d] ?? {};
    final steps = (dev['steps'] as num?)?.toInt() ?? 0;
    stepsData.add(steps);

    // Calc burned calories: steps * 0.04 + BMR part (simplified)
    final burned = (dev['calories_burned'] as num?)?.toInt() ?? (steps * 0.04).round();
    burnedCalorieData.add(burned);

    final s = dev['sleep_hours'];
    if (s != null) {
      totalSleep += (s as num).toDouble();
      sleepCount++;
    }
  }

  final sleepHours = sleepCount > 0 ? totalSleep / sleepCount : 6.8;

  return MonthReportData(
    weightData: weightData,
    calorieData: calorieData,
    stepsData: stepsData,
    burnedCalorieData: burnedCalorieData,
    meanCalorie: meanCalorie,
    sleepHours: sleepHours,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
  );
});

MonthReportData _emptyMonthReport() {
  return MonthReportData(
    weightData: List.generate(30, (_) => 70.0),
    calorieData: List.generate(30, (_) => 0),
    stepsData: List.generate(30, (_) => 0),
    burnedCalorieData: List.generate(30, (_) => 0),
    meanCalorie: 0,
    sleepHours: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
  );
}
