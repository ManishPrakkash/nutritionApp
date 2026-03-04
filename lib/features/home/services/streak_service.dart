import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'streak_service.g.dart';

@riverpod
StreakService streakService(StreakServiceRef ref) {
  return StreakService();
}

@riverpod
class CurrentStreak extends _$CurrentStreak {
  @override
  Future<int> build() async {
    final service = ref.read(streakServiceProvider);
    await service.recordTodayLogin();
    return service.getCurrentStreak();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final service = ref.read(streakServiceProvider);
    await service.recordTodayLogin();
    state = AsyncData(await service.getCurrentStreak());
  }
}

@riverpod
class WeeklyProgress extends _$WeeklyProgress {
  @override
  Future<List<bool>> build() async {
    final service = ref.read(streakServiceProvider);
    return service.getWeeklyProgress();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final service = ref.read(streakServiceProvider);
    state = AsyncData(await service.getWeeklyProgress());
  }
}

class StreakService {
  static const String _loginDatesKey = 'login_dates';
  static const String _currentStreakKey = 'current_streak';
  static const String _lastLoginKey = 'last_login_date';
  
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Records today's login and updates streak
  Future<void> recordTodayLogin() async {
    final prefs = await _prefs;
    final today = _getTodayDateString();
    final lastLogin = prefs.getString(_lastLoginKey);
    
    // If already logged in today, don't update
    if (lastLogin == today) return;
    
    // Get current login dates
    final loginDates = prefs.getStringList(_loginDatesKey) ?? [];
    
    // Add today if not already present
    if (!loginDates.contains(today)) {
      loginDates.add(today);
      await prefs.setStringList(_loginDatesKey, loginDates);
    }
    
    // Update last login date
    await prefs.setString(_lastLoginKey, today);
    
    // Calculate and update streak
    final streak = _calculateStreak(loginDates);
    await prefs.setInt(_currentStreakKey, streak);
  }

  /// Gets the current login streak
  Future<int> getCurrentStreak() async {
    final prefs = await _prefs;
    final loginDates = prefs.getStringList(_loginDatesKey) ?? [];
    return _calculateStreak(loginDates);
  }

  /// Gets weekly progress for the current calendar week (Mon-Sun).
  Future<List<bool>> getWeeklyProgress() async {
    final prefs = await _prefs;
    final loginDates = prefs.getStringList(_loginDatesKey) ?? [];
    
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

  /// Resets all streak data (for testing or user request)
  Future<void> resetStreak() async {
    final prefs = await _prefs;
    await prefs.remove(_loginDatesKey);
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_lastLoginKey);
  }

  /// Gets streak statistics
  Future<Map<String, dynamic>> getStreakStats() async {
    final prefs = await _prefs;
    final loginDates = prefs.getStringList(_loginDatesKey) ?? [];
    final currentStreak = await getCurrentStreak();
    
    // Calculate longest streak
    int longestStreak = _calculateLongestStreak(loginDates);
    
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalLoginDays': loginDates.length,
      'lastLoginDate': prefs.getString(_lastLoginKey),
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