import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../models/user_profile.dart';
import '../models/user_preferences.dart';
import '../models/prediction_result.dart';
import '../models/meal.dart';

class ApiService {
  ApiService._();
  static final ApiService _instance = ApiService._();
  static ApiService get instance => _instance;

  /// Safe String from map value (null or non-String becomes '').
  static String _str(dynamic v) => v == null ? '' : v.toString();
  static List<String> _stringList(dynamic v) {
    if (v == null || v is! List) return [];
    return v.map((e) => e == null ? '' : e.toString()).where((s) => s.isNotEmpty).toList();
  }

  static String get baseUrl => AppConstants.apiBaseUrl;
  late final Dio _dio;
  List<Map<String, dynamic>>? _allMeals;
  Map<String, dynamic>? _renderData;
  Map<String, dynamic>? _mlData;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      sendTimeout: AppConstants.apiTimeout,
    ));
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    _loadMealsData();
    _loadRenderData();
    _loadMLData();
  }

  Future<void> _loadMealsData() async {
    if (_allMeals != null) return;
    const paths = [
      'assets/data/meals_data.json',
      'packages/health_nutrition_app/assets/data/meals_data.json',
    ];
    for (final path in paths) {
      try {
        final String jsonString = await rootBundle.loadString(path);
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        final list = jsonData['meals'];
        if (list is List && list.isNotEmpty) {
          _allMeals = List<Map<String, dynamic>>.from(list);
          return;
        }
      } catch (_) {
        continue;
      }
    }
    _allMeals = _getHardcodedMeals();
  }

  Future<void> _loadRenderData() async {
    if (_renderData != null) return;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/render_data.json');
      _renderData = jsonDecode(jsonString);
    } catch (e) {
      // Fallback to empty data if JSON fails to load
      _renderData = {'rendered_images': {}, 'nutrition_charts': {}, 'visualizations': {}};
    }
  }

  Future<void> _loadMLData() async {
    if (_mlData != null) return;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/ml_data.json');
      _mlData = jsonDecode(jsonString);
    } catch (e) {
      // Fallback to empty data if JSON fails to load
      _mlData = {'prediction_templates': [], 'service_status': {'status': 'offline'}};
    }
  }

  List<Map<String, dynamic>> _getHardcodedMeals() {
    // Minimal in-app fallback set, used only if the JSON
    // asset cannot be loaded for some reason. Kept small
    // but with multiple options per meal type so that the
    // weekly plan can still look varied and date-driven.
    return [
      {
        'id': 'fallback_b1',
        'name': 'Basic Oats',
        'mealType': 'breakfast',
        'calories': 300,
        'protein': 8,
        'carbs': 50,
        'fat': 6,
        'fiber': 4,
        'prepMinutes': 10,
        'dietaryType': 'vegetarian',
        'ingredients': ['Oats - 1 cup', 'Milk - 1/2 cup', 'Honey - 1 tbsp'],
        'steps': ['Boil milk', 'Add oats', 'Cook for 5 minutes', 'Add honey'],
        'cuisine': 'continental',
        'healthScore': 80,
      },
      {
        'id': 'fallback_b2',
        'name': 'Fruit & Yogurt Bowl',
        'mealType': 'breakfast',
        'calories': 280,
        'protein': 12,
        'carbs': 38,
        'fat': 7,
        'fiber': 5,
        'prepMinutes': 8,
        'dietaryType': 'vegetarian',
        'ingredients': ['Greek yogurt - 1 cup', 'Mixed fruit - 1 cup', 'Nuts - 1 tbsp'],
        'steps': ['Add yogurt to bowl', 'Top with fruit', 'Finish with nuts'],
        'cuisine': 'continental',
        'healthScore': 82,
      },
      {
        'id': 'fallback_l1',
        'name': 'Dal Tadka + Brown Rice',
        'mealType': 'lunch',
        'calories': 580,
        'protein': 18,
        'carbs': 72,
        'fat': 12,
        'fiber': 8,
        'prepMinutes': 35,
        'dietaryType': 'vegetarian',
        'ingredients': ['Toor dal', 'Brown rice', 'Onion', 'Tomato', 'Spices'],
        'steps': ['Cook dal', 'Prepare tadka', 'Steam rice', 'Serve together'],
        'cuisine': 'indian',
        'healthScore': 84,
      },
      {
        'id': 'fallback_l2',
        'name': 'Grilled Paneer Salad',
        'mealType': 'lunch',
        'calories': 460,
        'protein': 24,
        'carbs': 30,
        'fat': 20,
        'fiber': 6,
        'prepMinutes': 20,
        'dietaryType': 'vegetarian',
        'ingredients': ['Paneer cubes', 'Mixed greens', 'Tomato', 'Cucumber', 'Olive oil'],
        'steps': ['Grill paneer', 'Chop vegetables', 'Toss with dressing'],
        'cuisine': 'indian',
        'healthScore': 81,
      },
      {
        'id': 'fallback_d1',
        'name': 'Grilled Chicken with Vegetables',
        'mealType': 'dinner',
        'calories': 480,
        'protein': 42,
        'carbs': 25,
        'fat': 18,
        'fiber': 5,
        'prepMinutes': 40,
        'dietaryType': 'non-vegetarian',
        'ingredients': ['Chicken breast', 'Mixed vegetables', 'Olive oil', 'Herbs'],
        'steps': ['Marinate chicken', 'Grill chicken', 'Sauté vegetables', 'Serve together'],
        'cuisine': 'continental',
        'healthScore': 85,
      },
      {
        'id': 'fallback_d2',
        'name': 'Veggie Stir Fry with Tofu',
        'mealType': 'dinner',
        'calories': 430,
        'protein': 22,
        'carbs': 40,
        'fat': 16,
        'fiber': 7,
        'prepMinutes': 25,
        'dietaryType': 'vegan',
        'ingredients': ['Tofu', 'Bell peppers', 'Broccoli', 'Soy sauce', 'Garlic'],
        'steps': ['Chop vegetables and tofu', 'Stir fry with garlic', 'Add sauce and serve'],
        'cuisine': 'asian',
        'healthScore': 83,
      },
      {
        'id': 'fallback_d3',
        'name': 'Lentil Soup with Whole Grain Bread',
        'mealType': 'dinner',
        'calories': 420,
        'protein': 18,
        'carbs': 58,
        'fat': 10,
        'fiber': 12,
        'prepMinutes': 30,
        'dietaryType': 'vegetarian',
        'ingredients': ['Red lentils', 'Onion', 'Carrot', 'Celery', 'Whole grain bread'],
        'steps': ['Sauté vegetables', 'Add lentils and broth', 'Simmer until tender', 'Serve with bread'],
        'cuisine': 'continental',
        'healthScore': 86,
      },
    ];
  }

  /// Builds the request body for /predict/all from real profile and preferences only.
  /// No default/sample values — missing fields are sent as null; backend must handle them.
  static Map<String, dynamic> buildPredictAllPayload(
      UserProfile profile, [UserPreferences? prefs]) {
    final p = prefs ?? const UserPreferences();
    
    // Core biometric validation
    if (profile.age <= 0) throw ArgumentError('Invalid biological age');
    if (profile.heightCm < 50 || profile.heightCm > 300) throw ArgumentError('Invalid height metrics');
    if (profile.weightKg < 20 || profile.weightKg > 500) throw ArgumentError('Invalid mass metrics');

    return <String, dynamic>{
      'user_id': profile.uid,
      'age': profile.age,
      'gender': profile.gender.toLowerCase(),
      'height_cm': profile.heightCm,
      'weight_kg': profile.weightKg,
      'activity_level': (p.activityLevel.isEmpty ? 'moderate' : p.activityLevel).toLowerCase(),
      'goal': (p.healthGoal.isEmpty ? 'maintain' : p.healthGoal).toLowerCase(),
      'dietary_preference': (p.dietTypes.isEmpty ? 'balanced' : p.dietTypes.first).toLowerCase(),
      // Optional/Extended diagnostics (can be null for standard prediction)
      'avg_sleep_hours': 8.0,
      'daily_steps': 10000,
      'water_intake_litres': 3.0,
      'calories_burned_per_day': 500.0,
      'avg_heart_rate_bpm': 72.0,
      'stress_level': 'low',
      'sleep_quality_score': 85,
      'fitness_level': 'intermediate',
      'workout_days_per_week': 3,
      'meal_frequency_per_day': null, // Not provided in UserPreferences
      'food_allergy': p.allergies.isEmpty ? null : p.allergies.join(', '),
      'medical_history': p.medicalHistory.isEmpty ? null : p.medicalHistory.join(', '),
      'daily_calorie_target': profile.tdee != null ? profile.tdee!.round() : null,
      'protein_target_g': null, // Not provided in UserPreferences
      'carbs_target_g': null, // Not provided in UserPreferences
      'fat_target_g': null, // Not provided in UserPreferences
      'current_streak_days': null, // Not provided in UserPreferences
      'total_workouts_logged': null, // Not provided in UserPreferences
      'total_meals_logged': null, // Not provided in UserPreferences
      'number_of_people': null, // Not provided in UserPreferences
      'budget_range': null, // Not provided in UserPreferences
    };
  }

  /// Maps app activity_level to backend format (e.g. "Moderately Active").
  static String _mapActivityLevel(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return 'Sedentary';
      case 'light':
        return 'Lightly Active';
      case 'moderate':
        return 'Moderately Active';
      case 'active':
        return 'Very Active';
      case 'extreme':
        return 'Extremely Active';
      default:
        return 'Moderately Active';
    }
  }

  /// POST /predict/all — ML backend returns predictions (risks), bmi_category, badge_status, calorie_target.
  /// Now uses local JSON data instead of HTTP requests.
  ///
  /// [meanCalorie]   - average daily calories from recent logs.
  /// [avgSteps]      - average daily step count from device data.
  /// [avgSleepHours] - average sleep duration in hours.
  /// [avgBurned]     - average calories burned per day.
  Future<Map<String, dynamic>> predictAll(
    UserProfile profile, [
    UserPreferences? prefs,
    double? meanCalorie,
    double? avgSteps,
    double? avgSleepHours,
    double? avgBurned,
  ]) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      await _loadMLData();
      
      final templates = _mlData?['prediction_templates'] as List<dynamic>? ?? [];
      if (templates.isEmpty) {
        throw Exception('No ML prediction templates available');
      }
      
      // Select template based on BMI category
      Map<String, dynamic> selectedTemplate;
      final bmi = profile.bmi;
      
      if (bmi != null) {
        if (bmi < 18.5) {
          // Find underweight template
          selectedTemplate = templates.firstWhere(
            (t) => t['bmi_category'] == 'Underweight',
            orElse: () => templates[0]
          );
        } else if (bmi >= 18.5 && bmi < 25.0) {
          // Find normal weight template (randomly select from normal templates)
          final normalTemplates = templates.where((t) => t['bmi_category'] == 'Normal').toList();
          if (normalTemplates.isNotEmpty) {
            final random = Random();
            selectedTemplate = normalTemplates[random.nextInt(normalTemplates.length)];
          } else {
            selectedTemplate = templates[0];
          }
        } else if (bmi >= 25.0 && bmi < 30.0) {
          // Find overweight template
          selectedTemplate = templates.firstWhere(
            (t) => t['bmi_category'] == 'Overweight',
            orElse: () => templates[1]
          );
        } else {
          // Find obese template
          selectedTemplate = templates.firstWhere(
            (t) => t['bmi_category'] == 'Obese',
            orElse: () => templates[2]
          );
        }
      } else {
        // Default to first template if no BMI
        selectedTemplate = templates[0];
      }
      
      // Create a copy of the template to modify
      final result = Map<String, dynamic>.from(selectedTemplate);
      
      // Apply age adjustments
      final age = profile.age;
      if (age != null && _mlData!.containsKey('age_adjustments')) {
        final ageAdjustments = _mlData!['age_adjustments'] as Map<String, dynamic>;
        String ageGroup;
        if (age < 26) ageGroup = '18-25';
        else if (age < 36) ageGroup = '26-35';
        else if (age < 46) ageGroup = '36-45';
        else if (age < 56) ageGroup = '46-55';
        else if (age < 66) ageGroup = '56-65';
        else ageGroup = '65+';
        
        if (ageAdjustments.containsKey(ageGroup)) {
          final adjustment = ageAdjustments[ageGroup] as Map<String, dynamic>;
          final scoreModifier = adjustment['score_modifier'] as int? ?? 0;
          final calorieBonus = adjustment['calorie_bonus'] as int? ?? 0;
          
          // Adjust prediction scores
          final predictions = result['predictions'] as List<dynamic>;
          for (final prediction in predictions) {
            if (prediction is Map<String, dynamic>) {
              final currentScore = prediction['score'] as double? ?? 0.0;
              prediction['score'] = (currentScore + scoreModifier).clamp(0.0, 100.0);
            }
          }
          
          // Adjust calorie target
          final currentCalories = result['calorie_target'] as int? ?? 2000;
          result['calorie_target'] = currentCalories + calorieBonus;
        }
      }
      
        // Apply activity level adjustments based on user preferences
        final String? activityLevel =
          (prefs?.activityLevel.isNotEmpty ?? false) ? prefs!.activityLevel : null;
        if (activityLevel != null && _mlData!.containsKey('activity_modifiers')) {
        final activityMods = _mlData!['activity_modifiers'] as Map<String, dynamic>;
        final mappedActivity = _mapActivityLevel(activityLevel).toLowerCase();
        
        String activityKey = 'moderate'; // default
        if (mappedActivity.contains('sedentary')) activityKey = 'sedentary';
        else if (mappedActivity.contains('lightly')) activityKey = 'light';
        else if (mappedActivity.contains('very')) activityKey = 'active';
        else if (mappedActivity.contains('extremely')) activityKey = 'extreme';
        
        if (activityMods.containsKey(activityKey)) {
          final modifier = activityMods[activityKey] as Map<String, dynamic>;
          final scoreModifier = modifier['score_modifier'] as int? ?? 0;
          final calorieModifier = modifier['calorie_modifier'] as int? ?? 0;
          
          // Adjust prediction scores
          final predictions = result['predictions'] as List<dynamic>;
          for (final prediction in predictions) {
            if (prediction is Map<String, dynamic>) {
              final currentScore = prediction['score'] as double? ?? 0.0;
              prediction['score'] = (currentScore + scoreModifier).clamp(0.0, 100.0);
            }
          }
          
          // Adjust calorie target
          final currentCalories = result['calorie_target'] as int? ?? 2000;
          result['calorie_target'] = currentCalories + calorieModifier;
        }
      }
      
      // Apply lifestyle-based adjustments when available
      if (meanCalorie != null || avgSteps != null || avgSleepHours != null || avgBurned != null) {
        final predictions = result['predictions'] as List<dynamic>? ?? [];

        double? tdee = profile.tdee;

        for (final prediction in predictions) {
          if (prediction is! Map<String, dynamic>) continue;

          final condition = (prediction['condition'] as String? ?? '').toLowerCase();
          double score = (prediction['score'] as num?)?.toDouble() ?? 0.0;

          // Diet: consistently eating far above target increases obesity & diabetes risk
          if (meanCalorie != null && tdee != null && tdee > 0) {
            final surplusRatio = (meanCalorie - tdee) / tdee; // e.g. 0.2 = 20% above
            if (surplusRatio > 0.1) {
              if (condition.contains('obes')) {
                score += (surplusRatio * 40).clamp(0, 20); // up to +20
              } else if (condition.contains('diab')) {
                score += (surplusRatio * 30).clamp(0, 15); // up to +15
              }
            }
          }

          // Activity: very low steps increase diabetes & hypertension risk; high steps reduce
          if (avgSteps != null) {
            if (avgSteps < 4000) {
              if (condition.contains('diab') || condition.contains('hyper')) {
                score += 10;
              }
            } else if (avgSteps > 9000) {
              if (condition.contains('diab') || condition.contains('hyper')) {
                score -= 8;
              }
            }
          }

          // Sleep: too little sleep modestly increases metabolic / blood-pressure risks
          if (avgSleepHours != null) {
            if (avgSleepHours < 6.0) {
              if (condition.contains('diab') || condition.contains('hyper')) {
                score += 5;
              }
            } else if (avgSleepHours > 8.5) {
              // slightly protective when over 8h and otherwise healthy
              if (condition.contains('diab') || condition.contains('obes')) {
                score -= 3;
              }
            }
          }

          // Ensure scores stay within 0-100
          prediction['score'] = score.clamp(0.0, 100.0);
        }

        // Attach simple lifestyle summary into user_stats for UI
        final stats = (result['user_stats'] as Map<String, dynamic>? ?? {}).cast<String, dynamic>();
        if (meanCalorie != null) stats['avg_daily_calories'] = meanCalorie.round();
        if (avgSteps != null) stats['avg_daily_steps'] = avgSteps.round();
        if (avgSleepHours != null) stats['avg_sleep_hours'] = double.parse(avgSleepHours.toStringAsFixed(1));
        if (avgBurned != null) stats['avg_calories_burned'] = avgBurned.round();
        result['user_stats'] = stats;
      }

      // Add timestamp and user_id
      result['timestamp'] = DateTime.now().toIso8601String();
      result['user_id'] = profile.uid;
      
      return result;
    } catch (e) {
      // Return fallback prediction on error
      return {
        'user_id': profile.uid,
        'timestamp': DateTime.now().toIso8601String(),
        'bmi_category': 'Normal',
        'badge_status': 'Bronze',
        'calorie_target': 2000,
        'predictions': [
          {
            'condition': 'general_health',
            'level': 'moderate',
            'score': 50.0,
            'description': 'ML service temporarily unavailable - using default values'
          }
        ],
        'user_stats': {
          'bmi': profile.bmi ?? 22.0,
          'fitness_score': 50
        }
      };
    }
  }

  /// Check ML service health and model information (Dummy implementation)
  /// Returns status of machine learning service and available models
  Future<Map<String, dynamic>> getMLServiceStatus() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      await _loadMLData();
      
      final serviceStatus = _mlData?['service_status'] as Map<String, dynamic>?;
      if (serviceStatus != null) {
        return Map<String, dynamic>.from(serviceStatus);
      }
      
      // Fallback status
      return {
        'status': 'offline',
        'version': '2.0.0-dummy',
        'models': [],
        'message': 'ML service status unavailable'
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to retrieve ML service status'
      };
    }
  }

  Future<PredictionResult> getPredictions(
    UserProfile profile, [
    UserPreferences? prefs,
    double? meanCalorie,
    double? avgSteps,
    double? avgSleepHours,
    double? avgBurned,
  ]) async {
    final data = await predictAll(
      profile,
      prefs,
      meanCalorie,
      avgSteps,
      avgSleepHours,
      avgBurned,
    );
    try {
      return PredictionResult.fromJson(data);
    } catch (e) {
       throw Exception('Data decoding error: The system could not parse the intelligence report.');
    }
  }

  Future<List<Meal>> getMealPlan(String userId, String date,
      {UserProfile? profile, UserPreferences? prefs}) async {
    await _loadMealsData();
    
    try {
      // Use local data with dietary filtering
      final dietTypes = prefs?.dietTypes ?? ['vegetarian'];
      final filteredMeals = _filterMealsByDietaryType(dietTypes);
      
      final List<Meal> dayMeals = [];
      
      // Get breakfast
      dayMeals.addAll(_getVariedMeals(filteredMeals, userId, date, 'breakfast', count: 1));
      
      // Get lunch
      dayMeals.addAll(_getVariedMeals(filteredMeals, userId, date, 'lunch', count: 1));
      
      // Get dinner
      dayMeals.addAll(_getVariedMeals(filteredMeals, userId, date, 'dinner', count: 1));
      
      if (dayMeals.isNotEmpty) return dayMeals;
      final fromJson = _defaultMealsForDayFromJson(date: date, userId: userId);
      return fromJson.isNotEmpty ? fromJson : _defaultMealsForDayRotated(date: date, userId: userId);
    } catch (_) {
      final fromJson = _defaultMealsForDayFromJson(date: date, userId: userId);
      return fromJson.isNotEmpty ? fromJson : _defaultMealsForDayRotated(date: date, userId: userId);
    }
  }

  /// Build default day from JSON with date-based rotation so each day gets
  /// different meals. Returns empty if JSON not loaded.
  List<Meal> _defaultMealsForDayFromJson({String? date, String? userId}) {
    if (_allMeals == null || _allMeals!.isEmpty) return [];
    final baseDate = DateTime(2025, 1, 1);
    DateTime parsedDate;
    try {
      parsedDate = date != null ? DateTime.parse(date) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final dayIndex = parsedDate.difference(baseDate).inDays;
    final userOffset = userId != null ? userId.hashCode.abs() : 0;

    final types = ['breakfast', 'lunch', 'dinner'];
    final List<Meal> result = [];
    for (final mealType in types) {
      final byType = _allMeals!
          .where((m) =>
              (m['mealType'] as String? ?? '').toLowerCase() == mealType)
          .toList();
      if (byType.isEmpty) return [];
      
      // Use unique offset per type to ensure breakfast/lunch/dinner variety
      final typeOffset = mealType.hashCode.abs() % 100;
      final idx = (dayIndex + userOffset + typeOffset) % byType.length;
      final match = byType[idx] as Map<String, dynamic>;
      result.add(Meal(
        id: _str(match['id']),
        name: _str(match['name']).isEmpty ? 'Unknown Meal' : _str(match['name']),
        mealType: _str(match['mealType']).isEmpty ? mealType : _str(match['mealType']),
        calories: (match['calories'] as num?)?.toInt() ?? 300,
        protein: (match['protein'] as num?)?.toDouble() ?? 10.0,
        carbs: (match['carbs'] as num?)?.toDouble() ?? 40.0,
        fat: (match['fat'] as num?)?.toDouble() ?? 8.0,
        fiber: (match['fiber'] as num?)?.toDouble() ?? 5.0,
        prepMinutes: (match['prepMinutes'] as num?)?.toInt() ?? 20,
        ingredients: _stringList(match['ingredients']),
        steps: _stringList(match['steps']),
      ));
    }
    return result;
  }

  /// Hardcoded fallback with date-based rotation so each day gets different meals.
  List<Meal> _defaultMealsForDayRotated({String? date, String? userId}) {
    final hardcoded = _getHardcodedMeals();
    final baseDate = DateTime(2025, 1, 1);
    DateTime parsedDate;
    try {
      parsedDate = date != null ? DateTime.parse(date) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final dayIndex = parsedDate.difference(baseDate).inDays;
    final userOffset = userId != null ? userId.hashCode.abs() : 0;

    final types = ['breakfast', 'lunch', 'dinner'];
    final List<Meal> result = [];
    for (final mealType in types) {
      final byType = hardcoded
          .where((m) =>
              (m['mealType'] as String? ?? '').toLowerCase() == mealType)
          .toList();
      if (byType.isEmpty) return _defaultMealsForDay();
      final idx = (dayIndex + userOffset) % byType.length;
      final m = byType[idx] as Map<String, dynamic>;
      result.add(Meal(
        id: _str(m['id']),
        name: _str(m['name']).isEmpty ? 'Unknown Meal' : _str(m['name']),
        mealType: _str(m['mealType']).isEmpty ? mealType : _str(m['mealType']),
        calories: (m['calories'] as num?)?.toInt() ?? 300,
        protein: (m['protein'] as num?)?.toDouble() ?? 10.0,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 40.0,
        fat: (m['fat'] as num?)?.toDouble() ?? 8.0,
        fiber: (m['fiber'] as num?)?.toDouble() ?? 5.0,
        prepMinutes: (m['prepMinutes'] as num?)?.toInt() ?? 20,
        ingredients: _stringList(m['ingredients']),
        steps: _stringList(m['steps']),
      ));
    }
    return result;
  }

  List<Meal> _defaultMealsForDay() {
    return [
      const Meal(
        id: '1',
        name: 'Oats with Banana & Honey',
        mealType: 'breakfast',
        calories: 320,
        protein: 8,
        carbs: 52,
        fat: 6,
        fiber: 4,
        prepMinutes: 15,
        ingredients: [
          'Rolled oats - 1 cup',
          'Banana - 1 medium',
          'Honey - 1 tbsp',
          'Milk or water - 1/2 cup',
          'Cinnamon - pinch',
        ],
        steps: [
          'Boil milk or water in a saucepan.',
          'Add oats and cook until creamy.',
          'Slice banana and place on top.',
          'Drizzle with honey and sprinkle cinnamon.',
        ],
      ),
      const Meal(
        id: '2',
        name: 'Dal Tadka + Brown Rice',
        mealType: 'lunch',
        calories: 580,
        protein: 18,
        carbs: 72,
        fat: 12,
        fiber: 8,
        prepMinutes: 35,
        ingredients: [
          'Toor dal - 1/2 cup',
          'Brown rice - 1 cup cooked',
          'Onion & tomato - finely chopped',
          'Ghee or oil - 1 tbsp',
          'Spices (cumin, chili, turmeric)',
        ],
        steps: [
          'Pressure cook dal with salt and turmeric.',
          'Prepare tadka with ghee, cumin and spices.',
          'Mix tadka into cooked dal.',
          'Serve hot with steamed brown rice.',
        ],
      ),
      const Meal(
        id: '3',
        name: 'Grilled Chicken with Vegetables',
        mealType: 'dinner',
        calories: 480,
        protein: 42,
        carbs: 25,
        fat: 18,
        fiber: 5,
        prepMinutes: 40,
        ingredients: [
          'Chicken breast - 150 g',
          'Mixed vegetables - 1 cup',
          'Olive oil - 1 tbsp',
          'Garlic, herbs, salt & pepper',
        ],
        steps: [
          'Marinate chicken with oil, garlic and herbs.',
          'Grill or pan-sear chicken until cooked through.',
          'Sauté mixed vegetables in a pan.',
          'Serve grilled chicken with vegetables on the side.',
        ],
      ),
    ];
  }

  /// Default meals for a specific type; when date/userId provided, rotate by day for variety.
  List<Meal> _defaultMealsForType(String mealType, {int count = 1, String? date, String? userId}) {
    final all = (date != null || userId != null)
        ? _defaultMealsForDayRotated(date: date, userId: userId)
        : _defaultMealsForDay();
    final typeMeals =
        all.where((m) => m.mealType.toLowerCase() == mealType.toLowerCase()).toList();

    if (typeMeals.isEmpty) return all.take(count).toList();

    final List<Meal> result = [];
    for (int i = 0; i < count; i++) {
      result.add(typeMeals[i % typeMeals.length]);
    }
    return result;
  }

  /// Filter meals based on dietary preferences
  List<Map<String, dynamic>> _filterMealsByDietaryType(List<String> dietTypes) {
    if (_allMeals == null) return [];

    // If no specific diet types, use the full catalog.
    if (dietTypes.isEmpty) return _allMeals!;

    final matches = _allMeals!.where((meal) {
      final mealDietaryType =
          meal['dietaryType']?.toString().toLowerCase() ?? '';

      // Check if any of the user's diet types match.
      for (final userDietType in dietTypes) {
        final normalizedUserType = userDietType.toLowerCase();

        // Direct matches.
        if (mealDietaryType == normalizedUserType) return true;

        // Special case handling / loose matching.
        if (normalizedUserType == 'vegan' && mealDietaryType == 'vegan') {
          return true;
        }
        if (normalizedUserType == 'vegetarian' &&
            (mealDietaryType == 'vegetarian' ||
                mealDietaryType == 'vegan')) {
          return true;
        }
        if (normalizedUserType == 'non-veg' &&
            mealDietaryType == 'non-vegetarian') {
          return true;
        }
      }

      return false;
    }).toList();

    // If nothing matched the user's diet labels (e.g. an unsupported tag),
    // fall back to the full catalog so we still get varied plans.
    return matches.isEmpty ? _allMeals! : matches;
  }

  /// Get meals varied by user ID and calendar date so each day looks different
  List<Meal> _getVariedMeals(
    List<Map<String, dynamic>> filteredMeals,
    String userId,
    String date,
    String mealType, {
    int count = 3,
  }) {
    // If diet filter left nothing, use full catalog so we still get date-based variety
    var mealsToUse = filteredMeals;
    if (mealsToUse.isEmpty && _allMeals != null && _allMeals!.isNotEmpty) {
      mealsToUse = _allMeals!;
    }
    if (mealsToUse.isEmpty) {
      return _defaultMealsForType(mealType, count: count, date: date, userId: userId);
    }

    // Filter by meal type first
    final mealTypeFiltered = mealsToUse
        .where((meal) =>
            meal['mealType']?.toString().toLowerCase() ==
            mealType.toLowerCase())
        .toList();

    if (mealTypeFiltered.isEmpty) {
      return _defaultMealsForType(mealType, count: count, date: date, userId: userId);
    }

    // Use a deterministic rotation based on calendar day so that
    // each date gets a different set of meals, but the same date
    // always maps to the same choices across Daily / Weekly / Program.
    final baseDate = DateTime(2025, 1, 1);
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final dayIndex = parsedDate.difference(baseDate).inDays;
    final userOffset = userId.hashCode.abs();
    
    // Add type-specific offset to ensure variety between meal types
    final typeOffset = mealType.hashCode.abs() % 100;

    final List<Meal> selectedMeals = [];
    for (int i = 0; i < count; i++) {
      final idx = (dayIndex + userOffset + typeOffset + i) % mealTypeFiltered.length;
      final mealData = mealTypeFiltered[idx];

      selectedMeals.add(Meal(
        id: _str(mealData['id']),
        name: _str(mealData['name']).isEmpty ? 'Unknown Meal' : _str(mealData['name']),
        mealType: _str(mealData['mealType']).isEmpty ? mealType : _str(mealData['mealType']),
        calories: (mealData['calories'] as num?)?.toInt() ?? 300,
        protein: (mealData['protein'] as num?)?.toDouble() ?? 10.0,
        carbs: (mealData['carbs'] as num?)?.toDouble() ?? 40.0,
        fat: (mealData['fat'] as num?)?.toDouble() ?? 8.0,
        fiber: (mealData['fiber'] as num?)?.toDouble() ?? 5.0,
        prepMinutes: (mealData['prepMinutes'] as num?)?.toInt() ?? 20,
        ingredients: _stringList(mealData['ingredients']),
        steps: _stringList(mealData['steps']),
      ));
    }

    return selectedMeals;
  }

  Future<List<Map<String, dynamic>>> getGroceryList(
    String userId, {
    String period = 'week', // 'day', 'week', or 'month'
    String budget = 'medium',
    int people = 2,
    UserProfile? profile,
    UserPreferences? prefs,
  }) async {
    // Build grocery list purely from local meal JSON and user context
    await _loadMealsData();

    final days = period == 'day'
        ? 1
        : period == 'month'
            ? 30
            : 7; // default to week

    final now = DateTime.now();
    final List<Meal> plannedMeals = [];

    // Generate meal plan for the requested period and aggregate ingredients
    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T').first;
      final mealsForDay = await getMealPlan(
        userId,
        dateStr,
        profile: profile,
        prefs: prefs,
      );
      plannedMeals.addAll(mealsForDay);
    }

    if (plannedMeals.isEmpty) {
      return _defaultGroceryList();
    }

    // Aggregate ingredients across all meals
    final Map<String, Map<String, dynamic>> aggregated = {};

    for (final meal in plannedMeals) {
      for (final raw in meal.ingredients) {
        final ingredient = raw.trim();
        if (ingredient.isEmpty) continue;

        final parts = ingredient.split('-');
        final name = parts.first.trim();
        final qty = parts.length > 1 ? parts.sublist(1).join('-').trim() : '';
        final key = name.toLowerCase();

        if (!aggregated.containsKey(key)) {
          aggregated[key] = {
            'name': name,
            'baseQty': qty.isEmpty ? '1 unit' : qty,
            'count': 1,
          };
        } else {
          aggregated[key]!['count'] =
              (aggregated[key]!['count'] as int) + 1;
        }
      }
    }

    if (aggregated.isEmpty) {
      return _defaultGroceryList();
    }

    // Scale quantities by number of people and budget
    final budgetFactor = () {
      switch (budget.toLowerCase()) {
        case 'low':
          return 0.8;
        case 'high':
          return 1.25;
        default:
          return 1.0;
      }
    }();

    final Map<String, List<Map<String, dynamic>>> byCategory = {};

    aggregated.forEach((_, value) {
      final name = value['name'] as String;
      final baseQty = value['baseQty'] as String;
      final count = (value['count'] as int) * people;
      final category = _inferGroceryCategory(name);

      final displayQty = count <= 1 ? baseQty : '$baseQty x $count';
      final unitPrice = _getMarketPricePerUnit(name, baseQty) ?? _estimateBasePrice(category);
      final price = (unitPrice * count * budgetFactor).round();

      final item = {
        'name': name,
        'quantity': displayQty,
        'price': price,
      };

      byCategory.putIfAbsent(category, () => []).add(item);
    });

    final List<Map<String, dynamic>> result = [];
    byCategory.forEach((category, items) {
      result.add({
        'category': category.toUpperCase(),
        'items': items,
      });
    });

    // Sort categories alphabetically for a stable UI
    result.sort((a, b) =>
        (a['category'] as String).compareTo(b['category'] as String));

    return result;
  }

  String _inferGroceryCategory(String ingredientName) {
    final n = ingredientName.toLowerCase();
    if (n.contains('spinach') ||
        n.contains('broccoli') ||
        n.contains('tomato') ||
        n.contains('carrot') ||
        n.contains('cabbage') ||
        n.contains('pepper') ||
        n.contains('onion')) {
      return 'Vegetables';
    }
    if (n.contains('apple') ||
        n.contains('banana') ||
        n.contains('berry') ||
        n.contains('orange') ||
        n.contains('grape') ||
        n.contains('mango')) {
      return 'Fruits';
    }
    if (n.contains('chicken') ||
        n.contains('egg') ||
        n.contains('paneer') ||
        n.contains('tofu') ||
        n.contains('fish') ||
        n.contains('dal') ||
        n.contains('lentil')) {
      return 'Proteins';
    }
    if (n.contains('rice') ||
        n.contains('oat') ||
        n.contains('bread') ||
        n.contains('wheat') ||
        n.contains('pasta') ||
        n.contains('quinoa')) {
      return 'Grains & Pulses';
    }
    if (n.contains('milk') ||
        n.contains('yogurt') ||
        n.contains('curd') ||
        n.contains('cheese') ||
        n.contains('butter')) {
      return 'Dairy & Eggs';
    }
    if (n.contains('oil') || n.contains('ghee') || n.contains('olive')) {
      return 'Fats & Oils';
    }
    return 'Others';
  }

  /// Approximate Indian market rate (INR) per 1 unit for common ingredients. Returns null if not found (fallback to category).
  int? _getMarketPricePerUnit(String ingredientName, String baseQty) {
    final n = ingredientName.toLowerCase();
    final q = baseQty.toLowerCase();

    // Dairy & eggs (approx ₹ per cup / 100g / unit)
    if (n.contains('greek yogurt') || n.contains('curd')) return 55;
    if (n.contains('milk')) return q.contains('cup') ? 30 : 60; // per cup ~30, per L ~60
    if (n.contains('cream')) return 45;
    if (n.contains('cheese') || n.contains('feta')) return 50;
    if (n.contains('butter')) return 25; // per tbsp
    if (n.contains('egg')) return 8;   // per piece
    if (n.contains('paneer')) return 70; // 200g block ~70

    // Fats & oils
    if (n.contains('olive oil')) return 55;  // per tbsp / small unit
    if (n.contains('oil') || n.contains('ghee')) return 15; // per tbsp

    // Grains & pulses
    if (n.contains('rice') && n.contains('basmati')) return 50;
    if (n.contains('rice') || n.contains('poha') || n.contains('flattened rice')) return 25;
    if (n.contains('oats') || n.contains('rolled oats')) return 20;
    if (n.contains('quinoa')) return 80;
    if (n.contains('dosa batter') || n.contains('idli batter')) return 40;
    if (n.contains('dal') || n.contains('toor') || n.contains('lentil') || n.contains('moong')) return 40;
    if (n.contains('bread')) return 35;
    if (n.contains('flour') || n.contains('wheat')) return 15;
    if (n.contains('chickpea') || n.contains('rajma') || n.contains('kidney bean')) return 35;

    // Vegetables
    if (n.contains('potato') || n.contains('potatoes')) return 15;
    if (n.contains('onion') || n.contains('onions')) return 20;
    if (n.contains('tomato') || n.contains('tomatoes')) return 25;
    if (n.contains('spinach') || n.contains('palak')) return 30;
    if (n.contains('broccoli')) return 50;
    if (n.contains('bell pepper') || n.contains('capsicum')) return 25;
    if (n.contains('carrot') || n.contains('carrots')) return 20;
    if (n.contains('cabbage')) return 25;
    if (n.contains('green chilies') || n.contains('chili')) return 5;
    if (n.contains('ginger') || n.contains('garlic') || n.contains('ginger-garlic')) return 10;
    if (n.contains('cucumber')) return 15;
    if (n.contains('zucchini')) return 40;
    if (n.contains('mushroom')) return 50;
    if (n.contains('eggplant') || n.contains('brinjal')) return 30;
    if (n.contains('mixed greens') || n.contains('lettuce')) return 40;
    if (n.contains('snap peas') || n.contains('peas')) return 35;

    // Fruits
    if (n.contains('banana')) return 8;
    if (n.contains('apple')) return 30;
    if (n.contains('orange')) return 25;
    if (n.contains('berry') || n.contains('berries')) return 60;
    if (n.contains('mixed fruit') || n.contains('mixed berries')) return 50;
    if (n.contains('mango')) return 40;
    if (n.contains('grape')) return 50;
    if (n.contains('avocado')) return 80;
    if (n.contains('lemon') || n.contains('lime')) return 5;

    // Nuts, seeds, dry
    if (n.contains('nuts') || n.contains('mixed nuts')) return 40;
    if (n.contains('almond')) return 50;
    if (n.contains('peanut') || n.contains('peanuts')) return 25;
    if (n.contains('cashew')) return 60;
    if (n.contains('walnut')) return 45;
    if (n.contains('chia seed') || n.contains('seeds')) return 15;
    if (n.contains('coconut')) return 40;
    if (n.contains('coconut milk') || n.contains('coconut flakes')) return 55;
    if (n.contains('granola')) return 40;

    // Condiments & pantry
    if (n.contains('honey')) return 25;
    if (n.contains('sugar')) return 10;
    if (n.contains('salt')) return 5;
    if (n.contains('cinnamon') || n.contains('turmeric') || n.contains('cumin')) return 5;
    if (n.contains('curry leaves') || n.contains('mustard seeds')) return 5;
    if (n.contains('sambar powder') || n.contains('garam masala') || n.contains('biryani masala')) return 15;
    if (n.contains('tamarind')) return 10;
    if (n.contains('soy sauce') || n.contains('vinegar')) return 20;
    if (n.contains('tahini')) return 40;
    if (n.contains('hummus')) return 50;

    // Proteins
    if (n.contains('chicken')) return 120; // per 300g portion
    if (n.contains('fish') || n.contains('salmon')) return 150;
    if (n.contains('mutton')) return 200;
    if (n.contains('beef')) return 180;
    if (n.contains('shrimp') || n.contains('prawn')) return 140;
    if (n.contains('tofu')) return 60;

    return null;
  }

  int _estimateBasePrice(String category) {
    switch (category) {
      case 'Vegetables':
        return 40;
      case 'Fruits':
        return 60;
      case 'Proteins':
        return 80;
      case 'Grains & Pulses':
        return 70;
      case 'Dairy & Eggs':
      case 'Fats & Oils':
        return 55;
      default:
        return 40;
    }
  }

  List<Map<String, dynamic>> _defaultGroceryList() => [
        {'category': 'VEGETABLES', 'items': [
          {'name': 'Spinach', 'quantity': '500g', 'price': 35},
          {'name': 'Broccoli', 'quantity': '250g', 'price': 50},
          {'name': 'Tomatoes', 'quantity': '1 kg', 'price': 40},
        ]},
        {'category': 'GRAINS & PULSES', 'items': [
          {'name': 'Brown Rice', 'quantity': '2 kg', 'price': 180},
          {'name': 'Moong Dal', 'quantity': '500g', 'price': 80},
        ]},
        {'category': 'DAIRY & EGGS', 'items': [
          {'name': 'Greek Yogurt', 'quantity': '400g', 'price': 110},
          {'name': 'Paneer', 'quantity': '200g', 'price': 70},
        ]},
      ];

  Future<List<Meal>> searchRecipes(List<String> ingredients) async {
    await _loadMealsData();
    
    try {
      if (_allMeals == null || ingredients.isEmpty) return [];
      
      // Search for meals containing any of the specified ingredients
      final matchingMeals = _allMeals!.where((meal) {
        final mealIngredients = List<String>.from(meal['ingredients'] ?? []);
        return ingredients.any((searchIngredient) => 
            mealIngredients.any((mealIngredient) => 
                mealIngredient.toLowerCase().contains(searchIngredient.toLowerCase())
            )
        );
      }).toList();
      
      // Convert to Meal objects and return
      return matchingMeals.take(10).map((mealData) {
        return Meal(
          id: _str(mealData['id']),
          name: _str(mealData['name']).isEmpty ? 'Recipe' : _str(mealData['name']),
          mealType: _str(mealData['mealType']).isEmpty ? 'lunch' : _str(mealData['mealType']),
          calories: (mealData['calories'] as num?)?.toInt() ?? 300,
          protein: (mealData['protein'] as num?)?.toDouble() ?? 10.0,
          carbs: (mealData['carbs'] as num?)?.toDouble() ?? 40.0,
          fat: (mealData['fat'] as num?)?.toDouble() ?? 8.0,
          fiber: (mealData['fiber'] as num?)?.toDouble() ?? 5.0,
          prepMinutes: (mealData['prepMinutes'] as num?)?.toInt() ?? 20,
          ingredients: _stringList(mealData['ingredients']),
          steps: _stringList(mealData['steps']),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get alternative meal suggestions based on dietary preferences and health conditions
  Future<List<Meal>> getMealAlternatives(String mealId, String mealType,
      {UserProfile? profile, UserPreferences? prefs}) async {
    await _loadMealsData();
    
    try {
      // Use local data with dietary filtering
      final dietTypes = prefs?.dietTypes ?? ['vegetarian'];
      final filteredMeals = _filterMealsByDietaryType(dietTypes);
      
      // Create a seed based on mealId for consistent alternatives
      final seed = mealId.hashCode;
      final random = Random(seed);
      
      // Filter by meal type and exclude the current meal
      final alternatives = filteredMeals.where((meal) => 
          meal['mealType']?.toString().toLowerCase() == mealType.toLowerCase() &&
          meal['id'] != mealId).toList();
      
      if (alternatives.isEmpty) return _getDefaultAlternatives(mealType);
      
      // Shuffle and select 2-3 alternatives
      alternatives.shuffle(random);
      
      return alternatives.take(3).map((mealData) {
        return Meal(
          id: _str(mealData['id']),
          name: _str(mealData['name']).isEmpty ? 'Alternative Meal' : _str(mealData['name']),
          mealType: _str(mealData['mealType']).isEmpty ? mealType : _str(mealData['mealType']),
          calories: (mealData['calories'] as num?)?.toInt() ?? 300,
          protein: (mealData['protein'] as num?)?.toDouble() ?? 10.0,
          carbs: (mealData['carbs'] as num?)?.toDouble() ?? 40.0,
          fat: (mealData['fat'] as num?)?.toDouble() ?? 8.0,
          fiber: (mealData['fiber'] as num?)?.toDouble() ?? 5.0,
          prepMinutes: (mealData['prepMinutes'] as num?)?.toInt() ?? 20,
          ingredients: _stringList(mealData['ingredients']),
          steps: _stringList(mealData['steps']),
        );
      }).toList();
    } catch (_) {
      return _getDefaultAlternatives(mealType);
    }
  }

  /// Generate weekly meal plan (7 days) with no repeated meals across the week
  Future<Map<String, List<Meal>>> getWeeklyMealPlan(String userId, String startDate,
      {UserProfile? profile, UserPreferences? prefs}) async {
    await _loadMealsData();
    
    try {
      final dietTypes = prefs?.dietTypes ?? ['vegetarian'];
      var filtered = _filterMealsByDietaryType(dietTypes);
      if (filtered.isEmpty && _allMeals != null && _allMeals!.isNotEmpty) {
        filtered = _allMeals!;
      }
      if (filtered.isEmpty) {
        return _buildWeeklyPlanFallback(startDate, userId);
      }

      // Deduplicate by meal id so each meal appears once per type
      var breakfastPool = _dedupeById(
          filtered.where((m) => (m['mealType'] as String? ?? '').toLowerCase() == 'breakfast').toList());
      var lunchPool = _dedupeById(
          filtered.where((m) => (m['mealType'] as String? ?? '').toLowerCase() == 'lunch').toList());
      var dinnerPool = _dedupeById(
          filtered.where((m) => (m['mealType'] as String? ?? '').toLowerCase() == 'dinner').toList());

      // Use full JSON catalog to maximize variety (100+ breakfasts, 130+ lunches, 100+ dinners in meals_data.json)
      // so we don't repeat the same meal every day. Fill from _allMeals first, then fallback.
      final fullCatalog = _allMeals ?? [];
      final fallback = _getHardcodedMeals();
      breakfastPool = _ensurePoolSizeFromCatalog(breakfastPool, fullCatalog, fallback, 'breakfast', 7);
      lunchPool = _ensurePoolSizeFromCatalog(lunchPool, fullCatalog, fallback, 'lunch', 7);
      dinnerPool = _ensurePoolSizeFromCatalog(dinnerPool, fullCatalog, fallback, 'dinner', 7);

      final start = DateTime.parse(startDate);
      final plan = <String, List<Meal>>{};
      final usedBreakfastIds = <String>{};
      final usedLunchIds = <String>{};
      final usedDinnerIds = <String>{};
      String? lastBreakfastId;
      String? lastLunchId;
      String? lastDinnerId;

      for (int i = 0; i < 7; i++) {
        final date = start.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T').first;
        final dayMeals = <Meal>[];
        final b = _pickOneNoRepeat(breakfastPool, dateStr, userId, 'breakfast', usedBreakfastIds, lastBreakfastId);
        lastBreakfastId = b.id;
        dayMeals.add(b);
        final l = _pickOneNoRepeat(lunchPool, dateStr, userId, 'lunch', usedLunchIds, lastLunchId);
        lastLunchId = l.id;
        dayMeals.add(l);
        final d = _pickOneNoRepeat(dinnerPool, dateStr, userId, 'dinner', usedDinnerIds, lastDinnerId);
        lastDinnerId = d.id;
        dayMeals.add(d);
        plan[dateStr] = dayMeals;
      }
      return plan;
    } catch (_) {
      return _getDefaultWeeklyPlan(startDate);
    }
  }

  /// Keep first occurrence of each meal id to avoid duplicate entries in the pool
  List<Map<String, dynamic>> _dedupeById(List<Map<String, dynamic>> list) {
    final seen = <String>{};
    return list.where((m) {
      final id = _str(m['id']);
      if (id.isEmpty || seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();
  }

  /// Ensure pool has at least [minSize] options. Fill from [fullCatalog] (all JSON meals of type) first for max variety, then [fallback].
  List<Map<String, dynamic>> _ensurePoolSizeFromCatalog(
    List<Map<String, dynamic>> pool,
    List<Map<String, dynamic>> fullCatalog,
    List<Map<String, dynamic>> fallback,
    String mealType,
    int minSize,
  ) {
    if (pool.length >= minSize) return pool;
    final typeLower = mealType.toLowerCase();
    final existingIds = <String>{};
    for (final m in pool) {
      final id = _str(m['id']);
      if (id.isNotEmpty) existingIds.add(id);
    }
    final result = List<Map<String, dynamic>>.from(pool);

    // Add from full JSON catalog first (100+ breakfasts, 130+ lunches, 100+ dinners in meals_data.json)
    for (final m in fullCatalog) {
      if (result.length >= minSize) break;
      if ((m['mealType'] as String? ?? '').toLowerCase() != typeLower) continue;
      final id = _str(m['id']);
      if (id.isEmpty || existingIds.contains(id)) continue;
      result.add(m);
      existingIds.add(id);
    }

    // Then add from hardcoded fallback if still needed
    for (final m in fallback) {
      if (result.length >= minSize) break;
      if ((m['mealType'] as String? ?? '').toLowerCase() != typeLower) continue;
      final id = _str(m['id']);
      if (id.isEmpty || existingIds.contains(id)) continue;
      result.add(m);
      existingIds.add(id);
    }
    return result;
  }

  /// Ensure pool has at least [minSize] options by adding fallback meals of [mealType] not already in pool
  List<Map<String, dynamic>> _ensurePoolSize(
    List<Map<String, dynamic>> pool,
    List<Map<String, dynamic>> fallback,
    String mealType,
    int minSize,
  ) {
    if (pool.length >= minSize) return pool;
    final typeLower = mealType.toLowerCase();
    final existingIds = <String>{};
    for (final m in pool) {
      final id = _str(m['id']);
      if (id.isNotEmpty) existingIds.add(id);
    }
    final toAdd = fallback
        .where((m) =>
            (m['mealType'] as String? ?? '').toLowerCase() == typeLower &&
            !existingIds.contains(_str(m['id'])))
        .toList();
    final result = List<Map<String, dynamic>>.from(pool);
    for (final m in toAdd) {
      if (result.length >= minSize) break;
      result.add(m);
      existingIds.add(_str(m['id']));
    }
    return result;
  }

  /// Pick one meal of [mealType] from [pool], avoiding ids in [usedIds] and avoiding [lastPickedId] when possible (no consecutive-day repeat).
  Meal _pickOneNoRepeat(
    List<Map<String, dynamic>> pool,
    String date,
    String userId,
    String mealType,
    Set<String> usedIds, [
    String? lastPickedId,
  ]) {
    if (pool.isEmpty) {
      return _defaultMealsForType(mealType, count: 1, date: date, userId: userId).first;
    }
    var available = pool.where((m) => !usedIds.contains(_str(m['id']))).toList();
    if (available.isEmpty) {
      usedIds.clear();
      available = List<Map<String, dynamic>>.from(pool);
    }
    // Prefer not to repeat the same meal as yesterday
    final withoutLast = lastPickedId != null && lastPickedId.isNotEmpty
        ? available.where((m) => _str(m['id']) != lastPickedId).toList()
        : available;
    if (withoutLast.isNotEmpty) available = withoutLast;

    final baseDate = DateTime(2025, 1, 1);
    final dayIndex = DateTime.tryParse(date)?.difference(baseDate).inDays ?? 0;
    final userOffset = userId.hashCode.abs();
    
    // Use a unique index for each selection to ensure variety even if pools are small
    // Combine base date index, user hash, and meal type hash for a unique sequence
    final typeOffset = mealType.hashCode.abs() % 100;
    final idx = (dayIndex + userOffset + typeOffset) % available.length;
    
    final mealData = available[idx] as Map<String, dynamic>;
    final id = _str(mealData['id']);
    if (id.isNotEmpty) usedIds.add(id);

    return Meal(
      id: id,
      name: _str(mealData['name']).isEmpty ? 'Unknown Meal' : _str(mealData['name']),
      mealType: _str(mealData['mealType']).isEmpty ? mealType : _str(mealData['mealType']),
      calories: (mealData['calories'] as num?)?.toInt() ?? 300,
      protein: (mealData['protein'] as num?)?.toDouble() ?? 10.0,
      carbs: (mealData['carbs'] as num?)?.toDouble() ?? 40.0,
      fat: (mealData['fat'] as num?)?.toDouble() ?? 8.0,
      fiber: (mealData['fiber'] as num?)?.toDouble() ?? 5.0,
      prepMinutes: (mealData['prepMinutes'] as num?)?.toInt() ?? 20,
      ingredients: _stringList(mealData['ingredients']),
      steps: _stringList(mealData['steps']),
    );
  }

  Map<String, List<Meal>> _buildWeeklyPlanFallback(String startDate, String userId) {
    final start = DateTime.parse(startDate);
    final plan = <String, List<Meal>>{};
    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T').first;
      plan[dateStr] = _defaultMealsForDayRotated(date: dateStr, userId: userId);
      if (plan[dateStr]!.isEmpty) {
        plan[dateStr] = _defaultMealsForDay();
      }
    }
    return plan;
  }

  /// Generate monthly meal plan (30 days)
  Future<Map<String, List<Meal>>> getMonthlyMealPlan(String userId, String startDate,
      {UserProfile? profile, UserPreferences? prefs}) async {
    await _loadMealsData();
    
    try {
      final start = DateTime.parse(startDate);
      final plan = <String, List<Meal>>{};
      
      for (int i = 0; i < 30; i++) {
        final date = start.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T').first;
        plan[dateStr] = await getMealPlan(userId, dateStr, profile: profile, prefs: prefs);
      }
      return plan;
    } catch (_) {
      return _getDefaultMonthlyPlan(startDate);
    }
  }

  // ==================== RENDER API METHODS (DUMMY) ====================
  
  /// Render meal image (Dummy implementation)
  /// Returns meal image URL from JSON data
  Future<String?> renderMealImage(String mealId, {
    int width = 400, 
    int height = 300,
    String style = 'realistic'
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      await _loadRenderData();
      
      // Check if specific meal image exists
      final renderedImages = _renderData?['rendered_images'] as Map<String, dynamic>?;
      if (renderedImages?.containsKey(mealId) == true) {
        final mealData = renderedImages![mealId] as Map<String, dynamic>;
        String imageUrl = mealData['full_image'] as String? ?? '';
        // Modify URL to include requested dimensions
        if (imageUrl.isNotEmpty && (width != 400 || height != 300)) {
          imageUrl = imageUrl.replaceAll('w=400&h=300', 'w=$width&h=$height');
        }
        return imageUrl;
      }
      
      // Fallback to default images based on meal type
      final defaultImages = _renderData?['default_images'] as Map<String, dynamic>?;
      if (defaultImages != null) {
        // Try to determine meal type from mealId or use breakfast as default
        String mealType = 'breakfast';
        if (mealId.contains('lunch') || mealId.contains('_l')) mealType = 'lunch';
        else if (mealId.contains('dinner') || mealId.contains('_d')) mealType = 'dinner';
        else if (mealId.contains('snack') || mealId.contains('_s')) mealType = 'snack';
        
        final typeImages = defaultImages[mealType] as List<dynamic>?;
        if (typeImages != null && typeImages.isNotEmpty) {
          final random = Random();
          String imageUrl = typeImages[random.nextInt(typeImages.length)] as String;
          // Modify URL to include requested dimensions
          if (width != 400 || height != 300) {
            imageUrl = imageUrl.replaceAll('w=400&h=300', 'w=$width&h=$height');
          }
          return imageUrl;
        }
      }
      
      return null;
    } catch (e) {
      // Return null on error (render service unavailable)
      return null;
    }
  }

  /// Render nutrition chart (Dummy implementation)
  /// Returns chart image from JSON data
  Future<String?> renderNutritionChart(String mealId, {
    String chartType = 'pie', // pie, bar, donut
    List<String> nutrients = const ['protein', 'carbs', 'fat', 'fiber']
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    try {
      await _loadRenderData();
      
      final nutritionCharts = _renderData?['nutrition_charts'] as Map<String, dynamic>?;
      if (nutritionCharts != null && nutritionCharts.containsKey(chartType)) {
        final charts = nutritionCharts[chartType] as List<dynamic>;
        if (charts.isNotEmpty) {
          final random = Random();
          return charts[random.nextInt(charts.length)] as String;
        }
      }
      
      // Fallback to first available chart type
      if (nutritionCharts != null) {
        for (final entry in nutritionCharts.entries) {
          final charts = entry.value as List<dynamic>;
          if (charts.isNotEmpty) {
            return charts.first as String;
          }
        }
      }
      
      return null;
    } catch (e) {
      // Return null on error (render service unavailable)
      return null;
    }
  }

  /// Render meal thumbnail (Dummy implementation)
  /// Returns thumbnail image URL from JSON data
  Future<String?> renderMealThumbnail(String mealId, {
    int size = 150,
    bool includeCalories = true
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));
    
    try {
      await _loadRenderData();
      
      // Check if specific meal thumbnail exists
      final renderedImages = _renderData?['rendered_images'] as Map<String, dynamic>?;
      if (renderedImages?.containsKey(mealId) == true) {
        final mealData = renderedImages![mealId] as Map<String, dynamic>;
        String thumbnailUrl = mealData['thumbnail'] as String? ?? '';
        // Modify URL to include requested size
        if (thumbnailUrl.isNotEmpty && size != 150) {
          thumbnailUrl = thumbnailUrl.replaceAll('w=150&h=150', 'w=$size&h=$size');
        }
        return thumbnailUrl;
      }
      
      // Fallback to default images
      final defaultImages = _renderData?['default_images'] as Map<String, dynamic>?;
      if (defaultImages != null) {
        String mealType = 'breakfast';
        if (mealId.contains('lunch') || mealId.contains('_l')) mealType = 'lunch';
        else if (mealId.contains('dinner') || mealId.contains('_d')) mealType = 'dinner';
        else if (mealId.contains('snack') || mealId.contains('_s')) mealType = 'snack';
        
        final typeImages = defaultImages[mealType] as List<dynamic>?;
        if (typeImages != null && typeImages.isNotEmpty) {
          final random = Random();
          String imageUrl = typeImages[random.nextInt(typeImages.length)] as String;
          // Convert to thumbnail size
          imageUrl = imageUrl.replaceAll('w=400&h=300', 'w=$size&h=$size');
          return imageUrl;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Render recipe steps with images (Dummy implementation)
  /// Returns list of step images from JSON data
  Future<List<String>?> renderRecipeSteps(String mealId, {
    int imageWidth = 300,
    int imageHeight = 200
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    try {
      await _loadRenderData();
      
      // Check if specific meal recipe steps exist
      final renderedImages = _renderData?['rendered_images'] as Map<String, dynamic>?;
      if (renderedImages?.containsKey(mealId) == true) {
        final mealData = renderedImages![mealId] as Map<String, dynamic>;
        final recipeSteps = mealData['recipe_steps'] as List<dynamic>?;
        if (recipeSteps != null && recipeSteps.isNotEmpty) {
          return recipeSteps.map((step) {
            String stepUrl = step as String;
            // Modify URL to include requested dimensions
            if (imageWidth != 300 || imageHeight != 200) {
              stepUrl = stepUrl.replaceAll('w=300&h=200', 'w=$imageWidth&h=$imageHeight');
            }
            return stepUrl;
          }).toList();
        }
      }
      
      // Fallback: create steps from default images
      final defaultImages = _renderData?['default_images'] as Map<String, dynamic>?;
      if (defaultImages != null) {
        String mealType = 'breakfast';
        if (mealId.contains('lunch') || mealId.contains('_l')) mealType = 'lunch';
        else if (mealId.contains('dinner') || mealId.contains('_d')) mealType = 'dinner';
        else if (mealId.contains('snack') || mealId.contains('_s')) mealType = 'snack';
        
        final typeImages = defaultImages[mealType] as List<dynamic>?;
        if (typeImages != null && typeImages.isNotEmpty) {
          // Return 2-4 steps from available images
          final random = Random();
          final stepCount = 2 + random.nextInt(3);
          final selectedImages = <String>[];
          
          for (int i = 0; i < stepCount && i < typeImages.length; i++) {
            String stepUrl = typeImages[i] as String;
            stepUrl = stepUrl.replaceAll('w=400&h=300', 'w=$imageWidth&h=$imageHeight');
            selectedImages.add(stepUrl);
          }
          
          return selectedImages;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Render meal plan visualization (Dummy implementation)
  /// Returns meal plan visualization from JSON data
  Future<String?> renderMealPlanVisualization(Map<String, List<Meal>> mealPlan, {
    String viewType = 'weekly', // weekly, monthly
    String layout = 'calendar', // calendar, timeline, grid
    int width = 800,
    int height = 600
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1200));
    
    try {
      await _loadRenderData();
      
      final visualizations = _renderData?['visualizations'] as Map<String, dynamic>?;
      if (visualizations != null) {
        final planKey = '${viewType}_plan';
        if (visualizations.containsKey(planKey)) {
          final planImages = visualizations[planKey] as List<dynamic>;
          if (planImages.isNotEmpty) {
            final random = Random();
            String imageUrl = planImages[random.nextInt(planImages.length)] as String;
            // Modify URL to include requested dimensions
            if (width != 800 || height != 600) {
              imageUrl = imageUrl.replaceAll('w=800&h=600', 'w=$width&h=$height');
            }
            return imageUrl;
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Render custom meal collage (Dummy implementation)
  /// Creates a collage from JSON data
  Future<String?> renderMealCollage(List<String> mealIds, {
    String arrangement = 'grid2x2', // grid2x2, grid3x3, horizontal, vertical
    int width = 600,
    int height = 600,
    bool includeNutritionSummary = false
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 900));
    
    try {
      await _loadRenderData();
      
      final visualizations = _renderData?['visualizations'] as Map<String, dynamic>?;
      if (visualizations != null && visualizations.containsKey('meal_collage')) {
        final collageImages = visualizations['meal_collage'] as List<dynamic>;
        if (collageImages.isNotEmpty) {
          final random = Random();
          String imageUrl = collageImages[random.nextInt(collageImages.length)] as String;
          // Modify URL to include requested dimensions
          if (width != 600 || height != 600) {
            imageUrl = imageUrl.replaceAll('w=600&h=600', 'w=$width&h=$height');
          }
          return imageUrl;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check render service health (Dummy implementation)
  /// Returns status of image rendering service
  Future<Map<String, dynamic>> getRenderServiceStatus() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    return {
      'status': 'offline', // Always offline since it's dummy
      'version': '1.0.0-dummy',
      'endpoints': [
        'renderMealImage',
        'renderNutritionChart', 
        'renderMealThumbnail',
        'renderRecipeSteps',
        'renderMealPlanVisualization',
        'renderMealCollage'
      ],
      'supportedFormats': ['jpg', 'png', 'webp'],
      'maxResolution': '1920x1080',
      'message': 'Render service is currently in dummy mode'
    };
  }

  // ==================== END RENDER API ====================

  /// Default alternative meals based on meal type
  List<Meal> _getDefaultAlternatives(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return [
          const Meal(
            id: 'alt_b1',
            name: 'Greek Yogurt with Berries',
            mealType: 'breakfast',
            calories: 280,
            protein: 15,
            carbs: 35,
            fat: 8,
            fiber: 5,
            prepMinutes: 10,
            ingredients: [
              'Greek yogurt - 1 cup',
              'Mixed berries - 1/2 cup',
              'Honey - 1 tsp',
              'Nuts or seeds - 1 tbsp',
            ],
            steps: [
              'Add yogurt to a bowl.',
              'Top with berries and nuts.',
              'Drizzle with honey and serve chilled.',
            ],
          ),
          const Meal(
            id: 'alt_b2',
            name: 'Avocado Toast with Eggs',
            mealType: 'breakfast',
            calories: 350,
            protein: 18,
            carbs: 28,
            fat: 20,
            fiber: 8,
            prepMinutes: 12,
            ingredients: [
              'Whole-grain bread - 2 slices',
              'Avocado - 1/2, mashed',
              'Eggs - 2',
              'Salt, pepper, chili flakes',
            ],
            steps: [
              'Toast the bread slices.',
              'Mash avocado with salt and pepper.',
              'Cook eggs to preference (boiled or fried).',
              'Spread avocado on toast and top with eggs.',
            ],
          ),
        ];
      case 'lunch':
        return [
          const Meal(
            id: 'alt_l1',
            name: 'Quinoa Buddha Bowl',
            mealType: 'lunch',
            calories: 520,
            protein: 16,
            carbs: 68,
            fat: 18,
            fiber: 12,
            prepMinutes: 25,
            ingredients: [
              'Cooked quinoa - 1 cup',
              'Roasted vegetables - 1 cup',
              'Chickpeas - 1/2 cup',
              'Tahini or yogurt dressing - 2 tbsp',
            ],
            steps: [
              'Cook quinoa as per package directions.',
              'Roast or sauté mixed vegetables.',
              'Assemble bowl with quinoa, veggies and chickpeas.',
              'Drizzle with dressing before serving.',
            ],
          ),
          const Meal(
            id: 'alt_l2',
            name: 'Chickpea & Vegetable Curry',
            mealType: 'lunch',
            calories: 480,
            protein: 20,
            carbs: 65,
            fat: 14,
            fiber: 15,
            prepMinutes: 30,
            ingredients: [
              'Chickpeas (cooked) - 1 cup',
              'Mixed vegetables - 1 cup',
              'Onion, tomato, ginger-garlic paste',
              'Curry spices and oil',
            ],
            steps: [
              'Sauté onion and spices in oil.',
              'Add tomatoes and cook into a masala.',
              'Stir in chickpeas and vegetables with water.',
              'Simmer until vegetables are tender.',
            ],
          ),
        ];
      case 'dinner':
        return [
          const Meal(
            id: 'alt_d1',
            name: 'Baked Salmon with Sweet Potato',
            mealType: 'dinner',
            calories: 450,
            protein: 38,
            carbs: 32,
            fat: 16,
            fiber: 6,
            prepMinutes: 40,
            ingredients: [
              'Salmon fillet - 150 g',
              'Sweet potato - 1 medium',
              'Olive oil, salt, pepper, herbs',
            ],
            steps: [
              'Season salmon with oil, salt and herbs.',
              'Bake salmon and sliced sweet potato in oven.',
              'Serve together with a squeeze of lemon.',
            ],
          ),
          const Meal(
            id: 'alt_d2',
            name: 'Lentil & Vegetable Stew',
            mealType: 'dinner',
            calories: 420,
            protein: 22,
            carbs: 58,
            fat: 10,
            fiber: 18,
            prepMinutes: 35,
            ingredients: [
              'Lentils - 1 cup',
              'Carrot, celery, onion - chopped',
              'Tomatoes - 2',
              'Vegetable stock and spices',
            ],
            steps: [
              'Sauté vegetables in a pot.',
              'Add lentils, tomatoes and stock.',
              'Simmer until lentils are soft and stew thickens.',
            ],
          ),
        ];
      default:
        return [];
    }
  }

  /// Generate default weekly meal plan
  Map<String, List<Meal>> _getDefaultWeeklyPlan(String startDate) {
    final start = DateTime.parse(startDate);
    final plan = <String, List<Meal>>{};
    
    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T').first;
      plan[dateStr] = _defaultMealsForDay();
    }
    return plan;
  }

  /// Generate default monthly meal plan
  Map<String, List<Meal>> _getDefaultMonthlyPlan(String startDate) {
    final start = DateTime.parse(startDate);
    final plan = <String, List<Meal>>{};
    
    for (int i = 0; i < 30; i++) {
      final date = start.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T').first;
      plan[dateStr] = _defaultMealsForDay();
    }
    return plan;
  }
}
