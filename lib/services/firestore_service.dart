import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_profile.dart';
import '../models/user_preferences.dart';
import '../models/prediction_result.dart';
import '../models/meal.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService _instance = FirestoreService._();
  static FirestoreService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<void> saveProfile(UserProfile profile) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(profile.uid)
        .set({}, SetOptions(merge: true));
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(profile.uid)
        .collection('data')
        .doc(AppConstants.profileDoc)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection('data')
        .doc(AppConstants.profileDoc)
        .get();
    if (snap.exists && snap.data() != null) {
      return UserProfile.fromJson(snap.data()!);
    }
    return null;
  }

  Future<void> savePreferences(String uid, UserPreferences prefs) async {
    // Ensure user document exists (required by some Firestore rules for subcollection writes)
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set({'updatedAt': DateTime.now().toIso8601String()}, SetOptions(merge: true));
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection('data')
        .doc(AppConstants.preferencesDoc)
        .set(prefs.toJson(), SetOptions(merge: true));
  }

  Future<UserPreferences?> getPreferences(String uid) async {
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection('data')
        .doc(AppConstants.preferencesDoc)
        .get();
    if (snap.exists && snap.data() != null) {
      return UserPreferences.fromJson(snap.data()!);
    }
    return null;
  }

  Future<void> savePrediction(PredictionResult result) async {
    await _firestore.collection(AppConstants.predictionsCollection).add({
      'user_id': result.userId,
      'timestamp': result.timestamp.toIso8601String(),
      'predictions': result.predictions.map((e) => e.toJson()).toList(),
      'user_stats': result.userStats,
      'bmi_category': result.bmiCategory,
      'badge_status': result.badgeStatus,
      'calorie_target': result.calorieTarget,
    });
  }

  Future<PredictionResult?> getLatestPrediction(String uid) async {
    final snap = await _firestore
        .collection(AppConstants.predictionsCollection)
        .where('user_id', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      data['id'] = snap.docs.first.id;
      return PredictionResult.fromJson(data);
    }
    return null;
  }

  Future<void> saveMealLog(String uid, String date, List<Meal> meals) async {
    await _firestore
        .collection(AppConstants.mealLogsCollection)
        .doc(uid)
        .collection('days')
        .doc(date)
        .set({
      'meals': meals.map((e) => e.toJson()).toList(),
      'date': date,
    }, SetOptions(merge: true));
  }

  Future<List<Meal>> getMealLog(String uid, String date) async {
    final snap = await _firestore
        .collection(AppConstants.mealLogsCollection)
        .doc(uid)
        .collection('days')
        .doc(date)
        .get();
    if (snap.exists) {
      final list = snap.data()?['meals'] as List<dynamic>?;
      return list
              ?.map((e) => Meal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    }
    return [];
  }

  Future<void> saveWorkoutLog(
      String uid, String date, bool completed, int durationMinutes,
      [List<Map<String, dynamic>>? exercises]) async {
    await _firestore
        .collection(AppConstants.workoutLogsCollection)
        .doc(uid)
        .collection('days')
        .doc(date)
        .set({
      'completed': completed,
      'durationMinutes': durationMinutes,
      'exercises': exercises ?? [],
      'date': date,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getWorkoutLog(String uid, String date) async {
    final snap = await _firestore
        .collection(AppConstants.workoutLogsCollection)
        .doc(uid)
        .collection('days')
        .doc(date)
        .get();
    return snap.data();
  }

  /// Persist per-exercise completion map for a given day, scoped to workout ID.
  Future<void> saveWorkoutExerciseCompletion(
      String uid, String date, String workoutId, Map<String, bool> completedExercises) async {
    await _firestore
        .collection(AppConstants.workoutLogsCollection)
        .doc(uid)
        .collection('days')
        .doc(date)
        .set({
      'completedExercises': completedExercises,
      'workoutId': workoutId,
      'date': date,
    }, SetOptions(merge: true));
  }

  /// Save user-entered daily goals (water, steps, sleep) for a specific date.
  Future<void> saveDailyGoals(
      String uid, String date, double waterLiters, int steps, double sleepHours) async {
    await _firestore
        .collection(AppConstants.dailyGoalsCollection)
        .doc(uid)
        .collection('days')
        .doc(date)
        .set({
      'waterLiters': waterLiters,
      'steps': steps,
      'sleepHours': sleepHours,
      'date': date,
    });
  }

  /// Get user-entered daily goals for a specific date. Returns null if not set.
  Future<Map<String, dynamic>?> getDailyGoals(String uid, String date) async {
    final snap = await _firestore
        .collection(AppConstants.dailyGoalsCollection)
        .doc(uid)
        .collection('days')
        .doc(date)
        .get();
    return snap.data();
  }

  Future<void> saveStreak(String uid, {
    required int currentStreak,
    required int longestStreak,
    required Map<String, dynamic> badgeStatus,
    required Map<String, dynamic> habitLogs,
  }) async {
    await _firestore.collection(AppConstants.streaksCollection).doc(uid).set({
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'badge_status': badgeStatus,
      'habit_logs': habitLogs,
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getStreak(String uid) async {
    final doc = await _firestore.collection('streaks').doc(uid).get();
    return doc.exists ? doc.data()! : {};
  }

  Future<void> addWeightLog(String uid, DateTime date, double weightKg) async {
    await _firestore
        .collection(AppConstants.weightLogsCollection)
        .doc(uid)
        .collection('logs')
        .add({'date': date.toIso8601String(), 'weight': weightKg});
  }

  Future<List<Map<String, dynamic>>> getWeightLogs(String uid,
      {int limit = 30}) async {
    final snap = await _firestore
        .collection(AppConstants.weightLogsCollection)
        .doc(uid)
        .collection('logs')
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((e) {
      final d = e.data();
      d['id'] = e.id;
      return d;
    }).toList();
  }

  Future<void> saveDeviceData(String uid, String date, {
    int? steps,
    int? heartRateBpm,
    double? sleepHours,
    int? caloriesBurned,
  }) async {
    final data = <String, dynamic>{
      'date': date,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (steps != null) data['steps'] = steps;
    if (heartRateBpm != null) data['heart_rate_bpm'] = heartRateBpm;
    if (sleepHours != null) data['sleep_hours'] = sleepHours;
    if (caloriesBurned != null) data['calories_burned'] = caloriesBurned;
    await _firestore
        .collection(AppConstants.deviceDataCollection)
        .doc(uid)
        .collection('days')
        .doc(date)
        .set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getDeviceData(String uid, String date) async {
    final snap = await _firestore
        .collection(AppConstants.deviceDataCollection)
        .doc(uid)
        .collection('days')
        .doc(date)
        .get();
    return snap.data();
  }

  Future<List<Map<String, dynamic>>> getDeviceDataRange(String uid,
      String startDate, String endDate) async {
    final snap = await _firestore
        .collection(AppConstants.deviceDataCollection)
        .doc(uid)
        .collection('days')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();
    return snap.docs.map((e) => e.data()).toList();
  }

  Future<Map<String, bool>> getHabitLog(String uid, String date) async {
    final doc = await _firestore.collection('streaks').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final habitLogs = data['habit_logs'] as Map<String, dynamic>? ?? {};
      final dailyLog = habitLogs[date] as Map<String, dynamic>? ?? {};
      return dailyLog.map((key, value) => MapEntry(key, value as bool));
    }
    return {};
  }

  Future<void> updateHabitLog(String uid, String date, Map<String, bool> habits) async {
    await _firestore.collection('streaks').doc(uid).set({
      'habit_logs': {
        date: habits,
      },
    }, SetOptions(merge: true));
  }

  Future<void> updateBadgeStatus(String uid, String badgeId, bool isEarned) async {
    await _firestore.collection('streaks').doc(uid).set({
      'badge_status': {
        badgeId: isEarned,
      },
    }, SetOptions(merge: true));
  }
}
