import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// Provides a singleton StreakService instance.
final streakServiceProvider = Provider<StreakService>((ref) => StreakService());

/// Current login streak for the authenticated user.
/// Returns 0 when no user is signed in.
final currentStreakProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return 0;
  final service = ref.read(streakServiceProvider);
  await service.recordTodayLogin(uid);
  return service.getCurrentStreak(uid);
});

/// Weekly login progress (Mon–Sun) for the authenticated user.
final weeklyProgressProvider = FutureProvider<List<bool>>((ref) async {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return List.filled(7, false);
  final service = ref.read(streakServiceProvider);
  return service.getWeeklyProgress(uid);
});

class StreakService {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Per-user key helpers
  String _loginDatesKey(String uid) => 'login_dates_$uid';
  String _currentStreakKey(String uid) => 'current_streak_$uid';
  String _lastLoginKey(String uid) => 'last_login_date_$uid';

  /// Records today's login and updates streak
  Future<void> recordTodayLogin(String uid) async {
    final prefs = await _prefs;
    final today = _getTodayDateString();
    final lastLogin = prefs.getString(_lastLoginKey(uid));
    
    // If already logged in today, don't update
    if (lastLogin == today) return;
    
    // Get current login dates
    final loginDates = prefs.getStringList(_loginDatesKey(uid)) ?? [];
    
    // Add today if not already present
    if (!loginDates.contains(today)) {
      loginDates.add(today);
      await prefs.setStringList(_loginDatesKey(uid), loginDates);
    }
    
    // Update last login date
    await prefs.setString(_lastLoginKey(uid), today);
    
    // Calculate and update streak
    final streak = _calculateStreak(loginDates);
    await prefs.setInt(_currentStreakKey(uid), streak);
  }

  /// Gets the current login streak
  Future<int> getCurrentStreak(String uid) async {
    final prefs = await _prefs;
    final loginDates = prefs.getStringList(_loginDatesKey(uid)) ?? [];
    return _calculateStreak(loginDates);
  }

  /// Gets weekly progress for the current calendar week (Mon-Sun).
  Future<List<bool>> getWeeklyProgress(String uid) async {
    final prefs = await _prefs;
    final loginDates = prefs.getStringList(_loginDatesKey(uid)) ?? [];
    
    final today = DateTime.now();
    // Monday of the current week (1 = Mon ... 7 = Sun)
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final List<bool> weekProgress = [];
    for (int i = 0; i < 7; i++) {
      final checkDate = monday.add(Duration(days: i));
      final dateString = _formatDateString(checkDate);
      weekProgress.add(loginDates.contains(dateString));
    }
    
    return weekProgress;
  }

  /// Calculates current streak based on login dates
  int _calculateStreak(List<String> loginDates) {
    if (loginDates.isEmpty) return 0;
    
    // Sort dates in descending order
    final sortedDates = loginDates.map((date) => DateTime.parse(date)).toList();
    sortedDates.sort((a, b) => b.compareTo(a));
    
    final today = DateTime.now();
    final todayString = _getTodayDateString();
    
    // Check if logged in today
    if (!loginDates.contains(todayString)) return 0;
    
    int streak = 1; // Start with 1 for today
    DateTime currentDate = today.subtract(const Duration(days: 1));
    
    // Check consecutive days backwards from yesterday
    while (true) {
      final currentDateString = _formatDateString(currentDate);
      if (loginDates.contains(currentDateString)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Gets today's date as string (YYYY-MM-DD)
  String _getTodayDateString() {
    return _formatDateString(DateTime.now());
  }

  /// Formats date as YYYY-MM-DD string
  String _formatDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Resets all streak data for a user
  Future<void> resetStreak(String uid) async {
    final prefs = await _prefs;
    await prefs.remove(_loginDatesKey(uid));
    await prefs.remove(_currentStreakKey(uid));
    await prefs.remove(_lastLoginKey(uid));
  }

  /// Gets streak statistics
  Future<Map<String, dynamic>> getStreakStats(String uid) async {
    final prefs = await _prefs;
    final loginDates = prefs.getStringList(_loginDatesKey(uid)) ?? [];
    final currentStreak = await getCurrentStreak(uid);
    
    // Calculate longest streak
    int longestStreak = _calculateLongestStreak(loginDates);
    
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalLoginDays': loginDates.length,
      'lastLoginDate': prefs.getString(_lastLoginKey(uid)),
    };
  }

  /// Calculates the longest streak from all login dates
  int _calculateLongestStreak(List<String> loginDates) {
    if (loginDates.isEmpty) return 0;
    
    final sortedDates = loginDates.map((date) => DateTime.parse(date)).toList();
    sortedDates.sort();
    
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final previousDate = sortedDates[i - 1];
      final currentDate = sortedDates[i];
      
      // Check if dates are consecutive
      final daysDifference = currentDate.difference(previousDate).inDays;
      
      if (daysDifference == 1) {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }
}