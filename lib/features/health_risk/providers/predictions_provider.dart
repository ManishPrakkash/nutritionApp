import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/prediction_result.dart';
import '../../../services/api_service.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../reports/providers/reports_provider.dart';

/// Fetches health risk predictions from the ML backend using current profile and preferences.
/// Saves the result to Firestore for history. Invalidate to refresh.
/// With correct input, ML returns valid output and all data is saved to DB; on API/network failure, error is shown and user can Retry.
final predictionsFutureProvider =
  FutureProvider<PredictionResult?>((ref) async {
  final profile = await ref.watch(profileFutureProvider.future);
  final uid = ref.watch(authUserIdProvider);
  if (uid == null || profile == null) return null;
  final prefs = await ref.watch(preferencesFutureProvider.future);
  // Pull recent lifestyle data from the weekly report to enrich predictions
  final weekReport = await ref.watch(weekReportProvider.future);
  final meanCalorie = weekReport.meanCalorie;
  final avgSteps = weekReport.stepsData.isEmpty
      ? 0.0
      : weekReport.stepsData.reduce((a, b) => a + b) /
          weekReport.stepsData.length;
  final avgSleep = weekReport.sleepHours;
  final avgBurned = weekReport.burnedCalorieData.isEmpty
      ? 0.0
      : weekReport.burnedCalorieData.reduce((a, b) => a + b) /
          weekReport.burnedCalorieData.length;

  final result = await ApiService.instance.getPredictions(
    profile,
    prefs,
    meanCalorie,
    avgSteps,
    avgSleep,
    avgBurned,
  );
  final toSave = PredictionResult(
    userId: result.userId.isEmpty ? uid : result.userId,
    timestamp: result.timestamp,
    predictions: result.predictions,
    userStats: result.userStats,
    bmiCategory: result.bmiCategory,
    badgeStatus: result.badgeStatus,
    calorieTarget: result.calorieTarget,
  );
  try {
    await FirestoreService.instance.savePrediction(toSave);
  } catch (_) {
    await FirestoreService.instance.savePrediction(toSave);
  }
  return result;
});

/// Reads the most recently saved prediction for the current user from Firestore.
/// This is used for static daily snapshots (e.g. Home dashboard) so that
/// values do not change dynamically as inputs fluctuate.
final latestPredictionProvider =
    FutureProvider<PredictionResult?>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return null;
  return FirestoreService.instance.getLatestPrediction(uid);
});
