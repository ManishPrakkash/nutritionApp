import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/theme/app_colors.dart';
import 'package:health_nutrition_app/core/theme/app_typography.dart';
import 'package:health_nutrition_app/features/streaks/providers/habit_provider.dart';

class HabitTrackerScreen extends ConsumerWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final completedHabits = ref.watch(habitTrackerProvider);
    final habitNotifier = ref.read(habitTrackerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Habit Tracker'),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (habits) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              final isCompleted = completedHabits[habit.id] ?? false;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  value: isCompleted,
                  onChanged: (bool? value) {
                    if (value != null) {
                      habitNotifier.toggleHabit(habit.id, value);
                    }
                  },
                  title: Text(habit.name, style: AppTypography.textTheme.titleMedium),
                  subtitle: Text(habit.description, style: AppTypography.textTheme.bodyMedium),
                  activeColor: AppColors.primary,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
