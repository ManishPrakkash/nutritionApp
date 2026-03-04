class WorkoutExercise {
  final String name;
  final String reps;
  final int sets;

  const WorkoutExercise({
    required this.name,
    required this.reps,
    required this.sets,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      name: json['name'] ?? '',
      reps: json['reps'] ?? '',
      sets: json['sets'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'reps': reps,
    'sets': sets,
  };
}

class WorkoutPlan {
  final String id;
  final int dayIndex;
  final String title;
  final String level;
  final String activityLevel;
  final String focusArea;
  final String location;
  final int durationMinutes;
  final String description;
  final String warmUpDescription;
  final List<WorkoutExercise> warmUp;
  final List<WorkoutExercise> mainExercises;
  final String coolDownDescription;
  final List<WorkoutExercise> coolDown;

  const WorkoutPlan({
    required this.id,
    this.dayIndex = 0,
    required this.title,
    required this.level,
    this.activityLevel = '',
    this.focusArea = '',
    required this.location,
    required this.durationMinutes,
    required this.description,
    required this.warmUpDescription,
    required this.warmUp,
    required this.mainExercises,
    required this.coolDownDescription,
    required this.coolDown,
  });

  /// Total number of individual exercises across warm-up, main, and cool-down.
  int get totalExerciseCount => warmUp.length + mainExercises.length + coolDown.length;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    var warmUpList = json['warmUp'] as List? ?? [];
    var mainExercisesList = json['mainExercises'] as List? ?? [];
    var coolDownList = json['coolDown'] as List? ?? [];

    return WorkoutPlan(
      id: json['id'] ?? '',
      dayIndex: json['dayIndex'] ?? 0,
      title: json['title'] ?? '',
      level: json['level'] ?? '',
      activityLevel: json['activityLevel'] ?? '',
      focusArea: json['focusArea'] ?? '',
      location: json['location'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      description: json['description'] ?? '',
      warmUpDescription: json['warmUpDescription'] ?? '',
      warmUp: warmUpList.map((e) => WorkoutExercise.fromJson(e)).toList(),
      mainExercises: mainExercisesList.map((e) => WorkoutExercise.fromJson(e)).toList(),
      coolDownDescription: json['coolDownDescription'] ?? '',
      coolDown: coolDownList.map((e) => WorkoutExercise.fromJson(e)).toList(),
    );
  }
}
