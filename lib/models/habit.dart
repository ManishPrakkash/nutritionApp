class Habit {
  final String id;
  final String name;
  final String description;

  Habit({required this.id, required this.name, required this.description});

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String criteriaType;
  final int criteriaValue;
  final String? habitId;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.criteriaType,
    required this.criteriaValue,
    this.habitId,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      criteriaType: json['criteria_type'],
      criteriaValue: json['criteria_value'],
      habitId: json['habit_id'],
    );
  }
}
