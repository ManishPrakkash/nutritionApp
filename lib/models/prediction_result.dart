class HealthRiskPrediction {
  final String condition; // obesity, diabetes, hypertension, etc.
  final String level; // low, moderate, high
  final double score; // 0-100
  final String? description;

  const HealthRiskPrediction({
    required this.condition,
    required this.level,
    required this.score,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'condition': condition,
        'level': level,
        'score': score,
        'description': description,
      };

  factory HealthRiskPrediction.fromJson(Map<String, dynamic> json) {
    final score = json['score'];
    return HealthRiskPrediction(
      condition: (json['condition'] ?? json['Condition'] ?? '') as String,
      level: (json['level'] ?? json['Level'] ?? 'low') as String,
      score: score is num ? score.toDouble() : 0.0,
      description: (json['description'] ?? json['Description']) as String?,
    );
  }
}

class PredictionResult {
  final String? id;
  final String userId;
  final DateTime timestamp;
  final List<HealthRiskPrediction> predictions;
  final Map<String, dynamic>? userStats;
  /// BMI Category (Random Forest): Underweight / Normal / Overweight / Obese
  final String? bmiCategory;
  /// Badge Status (Gradient Boosting): Beginner / Bronze / Silver / Gold / Platinum
  final String? badgeStatus;
  /// Calorie Target (Ridge Regression): daily calorie target
  final double? calorieTarget;

  const PredictionResult({
    this.id,
    required this.userId,
    required this.timestamp,
    required this.predictions,
    this.userStats,
    this.bmiCategory,
    this.badgeStatus,
    this.calorieTarget,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'timestamp': timestamp.toIso8601String(),
        'predictions': predictions.map((e) => e.toJson()).toList(),
        'user_stats': userStats,
        'bmi_category': bmiCategory,
        'badge_status': badgeStatus,
        'calorie_target': calorieTarget,
      };

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final stats = json['user_stats'] is Map<String, dynamic>
        ? json['user_stats'] as Map<String, dynamic>
        : json['userStats'] is Map<String, dynamic>
            ? json['userStats'] as Map<String, dynamic>
            : null;
    DateTime ts = DateTime.now();
    try {
      if (json['timestamp'] != null) ts = DateTime.parse(json['timestamp'] as String);
    } catch (_) {}
    final rawList = json['predictions'] ?? json['Predictions'];
    final List<HealthRiskPrediction> predictions = [];
    if (rawList is List<dynamic>) {
      for (final e in rawList) {
        if (e is! Map<String, dynamic>) continue;
        try {
          predictions.add(HealthRiskPrediction.fromJson(e));
        } catch (_) {}
      }
    }
    String? bmiCat = json['bmi_category'] as String? ?? json['bmiCategory'] as String?;
    if (bmiCat == null && stats != null) bmiCat = stats['bmi_category'] as String?;
    String? badge = json['badge_status'] as String? ?? json['badgeStatus'] as String?;
    if (badge == null && stats != null) badge = stats['badge_status'] as String?;
    double? cal;
    if (json['calorie_target'] != null) cal = (json['calorie_target'] as num).toDouble();
    else if (json['calorieTarget'] != null) cal = (json['calorieTarget'] as num).toDouble();
    else if (stats != null && stats['calorie_target'] != null) cal = (stats['calorie_target'] as num).toDouble();
    return PredictionResult(
      id: json['id'] as String?,
      userId: (json['user_id'] ?? json['userId'] ?? '') as String,
      timestamp: ts,
      predictions: predictions,
      userStats: stats,
      bmiCategory: bmiCat,
      badgeStatus: badge,
      calorieTarget: cal,
    );
  }
}
