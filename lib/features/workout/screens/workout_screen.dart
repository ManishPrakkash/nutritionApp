import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/workout.dart';
import '../providers/workout_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(workoutPlansProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout Library'),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (plans) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: premiumCardDecoration(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailScreen(plan: plan),
                      ),
                    );
                  },
                  child: Padding
                  (
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.dumbbell,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.title,
                                    style: AppTypography.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${plan.durationMinutes} min • ${plan.level} • ${plan.location}',
                                    style: AppTypography.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _WorkoutTag(label: plan.level),
                            const SizedBox(width: 8),
                            _WorkoutTag(label: plan.location),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WorkoutDetailScreen extends ConsumerWidget {
  final WorkoutPlan plan;

  const WorkoutDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authUserIdProvider);
    final today = DateTime.now().toIso8601String().split('T').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: uid == null
            ? Future.value(null)
            : FirestoreService.instance.getWorkoutLog(uid, today),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final completed = (data?['completed'] as bool?) ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: premiumCardDecoration(),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.dumbbell,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: AppTypography.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${plan.durationMinutes} min • ${plan.level} • ${plan.location}',
                              style: AppTypography.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(plan.description,
                    style: AppTypography.textTheme.bodyLarge),
                const SizedBox(height: 16),
                if (uid != null)
                  Row(
                    children: [
                      Icon(
                        completed
                            ? LucideIcons.checkCircle2
                            : LucideIcons.circle,
                        size: 18,
                        color: completed
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        completed
                            ? 'Marked as done for today'
                            : 'Not done yet today',
                        style: AppTypography.textTheme.bodySmall,
                      ),
                    ],
                  ),
                if (uid != null) const SizedBox(height: 12),
                if (uid != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final newCompleted = !completed;
                      await FirestoreService.instance.saveWorkoutLog(
                        uid,
                        today,
                        newCompleted,
                        plan.durationMinutes,
                      );
                      // Refresh by rebuilding the FutureBuilder
                      (context as Element).markNeedsBuild();
                    },
                    icon: Icon(
                      completed
                          ? LucideIcons.x
                          : LucideIcons.checkCircle2,
                      size: 18,
                    ),
                    label: Text(
                      completed ? 'Mark as not done' : 'Mark as done',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildSection(context, plan.warmUpDescription, plan.warmUp),
                const SizedBox(height: 24),
                _buildSection(context, 'Main Workout', plan.mainExercises),
                const SizedBox(height: 24),
                _buildSection(context, plan.coolDownDescription, plan.coolDown),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<WorkoutExercise> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 16),
        ...exercises.map((e) => ListTile(
              title: Text(e.name),
              trailing: Text('${e.sets} sets, ${e.reps} reps'),
            )),
      ],
    );
  }
}

class _WorkoutTag extends StatelessWidget {
  final String label;

  const _WorkoutTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall,
      ),
    );
  }
}
