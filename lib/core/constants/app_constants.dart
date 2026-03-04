class AppConstants {
  AppConstants._();

  static const String appName = 'ZenFuel AI';
  static const String tagline = 'Personalized Nutrition & Health';

  // API — ML/backend base URL (zenhealth-app on Render)
  static const String apiBaseUrl = 'https://zenhealth-app.onrender.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Firestore paths
  static const String usersCollection = 'users';
  static const String profileDoc = 'profile';
  static const String preferencesDoc = 'preferences';
  static const String predictionsCollection = 'predictions';
  static const String mealLogsCollection = 'meal_logs';
  static const String workoutLogsCollection = 'workout_logs';
  static const String streaksCollection = 'streaks';
  static const String weightLogsCollection = 'weight_logs';
  static const String deviceDataCollection = 'device_data';

  // Streak thresholds (days)
  static const int bronzeDays = 7;
  static const int silverDays = 15;
  static const int goldDays = 30;
  static const int platinumDays = 90;
  static const int legendDays = 180;

  // Defaults
  static const double defaultWaterLiters = 3.0;
  static const int defaultStepsGoal = 10000;
  static const double defaultSleepHours = 8.0;
}
