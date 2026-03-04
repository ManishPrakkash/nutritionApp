import 'dart:convert';

class UserPreferences {
  final List<String> dietTypes;
  final List<String> allergies;
  final String healthGoal;
  final List<String> medicalHistory;
  final String activityLevel;
  final List<String> preferredCuisine;
  final int stepsGoal;

  const UserPreferences({
    this.dietTypes = const [],
    this.allergies = const [],
    this.healthGoal = '',
    this.medicalHistory = const [],
    this.activityLevel = 'moderate',
    this.preferredCuisine = const [],
    this.stepsGoal = 10000,
  });

  Map<String, dynamic> toJson() => {
        'dietTypes': dietTypes,
        'allergies': allergies,
        'healthGoal': healthGoal,
        'medicalHistory': medicalHistory,
        'activityLevel': activityLevel,
        'preferredCuisine': preferredCuisine,
        'stepsGoal': stepsGoal,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        dietTypes: List<String>.from(json['dietTypes'] ?? []),
        allergies: List<String>.from(json['allergies'] ?? []),
        healthGoal: json['healthGoal'] as String? ?? '',
        medicalHistory: List<String>.from(json['medicalHistory'] ?? []),
        activityLevel: json['activityLevel'] as String? ?? 'moderate',
        preferredCuisine: List<String>.from(json['preferredCuisine'] ?? []),
        stepsGoal: json['stepsGoal'] as int? ?? 10000,
      );

  String toJsonString() => jsonEncode(toJson());
}
