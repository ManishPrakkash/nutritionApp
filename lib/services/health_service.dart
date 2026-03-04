import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  HealthService._();
  static final HealthService _instance = HealthService._();
  static HealthService get instance => _instance;

  final Health _health = Health();

  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
  ];

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.activityRecognition.request();
    }
    return await _health.requestAuthorization(_types);
  }

  Future<int> getSteps(DateTime start, DateTime end) async {
    try {
      final list = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: start,
        endTime: end,
      );
      int total = 0;
      for (final d in list) {
        if (d.value is NumericHealthValue) {
          total += (d.value as NumericHealthValue).numericValue.toInt();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<double> getSleepHours(DateTime start, DateTime end) async {
    try {
      final list = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: start,
        endTime: end,
      );
      double hours = 0;
      for (final d in list) {
        if (d.value is NumericHealthValue) {
          hours += (d.value as NumericHealthValue).numericValue;
        }
      }
      return hours;
    } catch (_) {
      return 0;
    }
  }

  Future<int?> getLastHeartRate() async {
    try {
      final now = DateTime.now();
      final list = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
      );
      if (list.isNotEmpty && list.first.value is NumericHealthValue) {
        return (list.first.value as NumericHealthValue).numericValue.toInt();
      }
    } catch (_) {}
    return null;
  }

  Future<double?> getLatestWeight() async {
    try {
      final now = DateTime.now();
      final list = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: now.subtract(const Duration(days: 365)),
        endTime: now,
      );
      if (list.isNotEmpty && list.first.value is NumericHealthValue) {
        return (list.first.value as NumericHealthValue).numericValue.toDouble();
      }
    } catch (_) {}
    return null;
  }

  Future<int> getCaloriesBurned(DateTime start, DateTime end) async {
    try {
      final list = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );
      int total = 0;
      for (final d in list) {
        if (d.value is NumericHealthValue) {
          total += (d.value as NumericHealthValue).numericValue.toInt();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}
