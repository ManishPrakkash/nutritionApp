class Meal {
  final String id;
  final String name;
  final String mealType; // breakfast, lunch, dinner, night, snack
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String? imageUrl;
  final String? recipeUrl;
  final List<String> ingredients;
  final List<String> steps;
  final int prepMinutes;
  final bool isEaten;
  final bool isFavorite;
  final String dietaryType;       // vegetarian, vegan, non-vegetarian
  final String cuisine;           // indian, asian, mediterranean, continental, mexican
  final int healthScore;          // 0-100
  final List<String> allergensPresent; // dairy, gluten, nuts, shellfish, eggs
  final List<String> healthGoalFit;   // weight_loss, muscle_gain, maintain_weight, etc.

  const Meal({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.imageUrl,
    this.recipeUrl,
    this.ingredients = const [],
    this.steps = const [],
    this.prepMinutes = 0,
    this.isEaten = false,
    this.isFavorite = false,
    this.dietaryType = '',
    this.cuisine = '',
    this.healthScore = 0,
    this.allergensPresent = const [],
    this.healthGoalFit = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mealType': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'imageUrl': imageUrl,
        'recipeUrl': recipeUrl,
        'ingredients': ingredients,
        'steps': steps,
        'prepMinutes': prepMinutes,
        'isEaten': isEaten,
        'isFavorite': isFavorite,
        'dietaryType': dietaryType,
        'cuisine': cuisine,
        'healthScore': healthScore,
        'allergensPresent': allergensPresent,
        'healthGoalFit': healthGoalFit,
      };

  static String _str(dynamic v) => v == null ? '' : v.toString();
  static String? _optStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: _str(json['id']),
        name: _str(json['name']).isEmpty ? 'Unknown Meal' : _str(json['name']),
        mealType: _str(json['mealType']).isEmpty ? 'snack' : _str(json['mealType']),
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
        imageUrl: _optStr(json['imageUrl']),
        recipeUrl: _optStr(json['recipeUrl']),
        ingredients: _stringList(json['ingredients']),
        steps: _stringList(json['steps']),
        prepMinutes: (json['prepMinutes'] as num?)?.toInt() ?? 0,
        isEaten: json['isEaten'] as bool? ?? false,
        isFavorite: json['isFavorite'] as bool? ?? false,
        dietaryType: _str(json['dietaryType']),
        cuisine: _str(json['cuisine']),
        healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
        allergensPresent: _stringList(json['allergensPresent']),
        healthGoalFit: _stringList(json['healthGoalFit']),
      );

  static List<String> _stringList(dynamic v) {
    if (v == null) return [];
    if (v is! List) return [];
    return v.map((e) => e == null ? '' : e.toString()).where((s) => s.isNotEmpty).toList();
  }

  Meal copyWith({
    String? id,
    String? name,
    String? mealType,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    String? imageUrl,
    String? recipeUrl,
    List<String>? ingredients,
    List<String>? steps,
    int? prepMinutes,
    bool? isEaten,
    bool? isFavorite,
    String? dietaryType,
    String? cuisine,
    int? healthScore,
    List<String>? allergensPresent,
    List<String>? healthGoalFit,
  }) =>
      Meal(
        id: id ?? this.id,
        name: name ?? this.name,
        mealType: mealType ?? this.mealType,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        fiber: fiber ?? this.fiber,
        imageUrl: imageUrl ?? this.imageUrl,
        recipeUrl: recipeUrl ?? this.recipeUrl,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        prepMinutes: prepMinutes ?? this.prepMinutes,
        isEaten: isEaten ?? this.isEaten,
        isFavorite: isFavorite ?? this.isFavorite,
        dietaryType: dietaryType ?? this.dietaryType,
        cuisine: cuisine ?? this.cuisine,
        healthScore: healthScore ?? this.healthScore,
        allergensPresent: allergensPresent ?? this.allergensPresent,
        healthGoalFit: healthGoalFit ?? this.healthGoalFit,
      );
}

class DayMealPlan {
  final String date;
  final List<Meal> meals;
  final int totalCalories;
  final int targetCalories;

  const DayMealPlan({
    required this.date,
    required this.meals,
    required this.totalCalories,
    required this.targetCalories,
  });
}
