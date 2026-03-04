import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/habit.dart';
import '../../home/services/streak_service.dart';
import 'habit_provider.dart';

class BadgeProgress {
  final Badge badge;
  final bool isEarned;
  final double progress; // 0.0 to 1.0

  BadgeProgress({required this.badge, required this.isEarned, required this.progress});
}

final userBadgesProvider = FutureProvider<List<BadgeProgress>>((ref) async {
  final allBadges = await ref.watch(badgesProvider.future);
  final streakData = await ref.watch(streakFutureProvider.future);
  final userId = ref.watch(authUserIdProvider);
  // Use login-based streak from SharedPreferences (actual login data)
  final loginStreak = await ref.watch(currentStreakProvider.future);

  if (userId == null) return [];

  final earnedBadges = (streakData?['badge_status'] as Map<String, dynamic>?) ?? {};
  final habitLogs = (streakData?['habit_logs'] as Map<String, dynamic>?) ?? {};

  final List<BadgeProgress> badgeProgressList = [];

  for (final badge in allBadges) {
    bool isEarned = earnedBadges[badge.id] == true;
    double progress = 0.0;

    if (badge.criteriaType == 'streak') {
      final currentStreak = loginStreak;
      progress = (currentStreak / badge.criteriaValue).clamp(0.0, 1.0);
      if (currentStreak >= badge.criteriaValue) {
        isEarned = true;
      }
    } else if (badge.criteriaType == 'habit_streak' && badge.habitId != null) {
      int consecutiveDays = 0;
      final today = DateTime.now();
      for (int i = 0; i < badge.criteriaValue; i++) {
        final date = today.subtract(Duration(days: i));
        final dateString = date.toIso8601String().split('T').first;
        final dayLog = habitLogs[dateString] as Map<String, dynamic>?;
        if (dayLog?[badge.habitId!] == true) {
          consecutiveDays++;
        } else {
          break; 
        }
      }
      progress = (consecutiveDays / badge.criteriaValue).clamp(0.0, 1.0);
      if (consecutiveDays >= badge.criteriaValue) {
        isEarned = true;
      }
    }
    if (isEarned && earnedBadges[badge.id] != true) {
      await FirestoreService.instance.updateBadgeStatus(userId, badge.id, true);
    }

    badgeProgressList.add(BadgeProgress(badge: badge, isEarned: isEarned, progress: progress));
  }

  return badgeProgressList;
});

/// Fetches streak data from Firestore for the current user.
/// Invalidate after saving a workout or meal log to refresh.
final streakFutureProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return null;
  return FirestoreService.instance.getStreak(uid);
});

final streakProvider = Provider<AsyncValue<Map<String, dynamic>?>>((ref) {
  return ref.watch(streakFutureProvider);
});

/// Helper: current streak count from streak data.
int streakCount(Map<String, dynamic>? data) {
  if (data == null) return 0;
  final n = data['current_streak'];
  return (n is num) ? n.toInt() : 0;
}
