class Meal {
  final String id;
  final String name;
  final String mealType; // breakfast, lunch, dinner, snack
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
