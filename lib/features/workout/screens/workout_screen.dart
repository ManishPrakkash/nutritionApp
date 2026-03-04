import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/workout.dart';
import '../providers/workout_provider.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 1,
              labelStyle: AppTypography.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTypography.textTheme.titleSmall,
              tabs: const [
                Tab(text: "Today's"),
                Tab(text: 'Library'),
                Tab(text: 'Monthly'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TodayWorkoutTab(),
                _WorkoutLibraryTab(),
                _MonthlyWorkoutTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// TAB 1: TODAY'S WORKOUT
class _TodayWorkoutTab extends ConsumerWidget {
  const _TodayWorkoutTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayWorkoutProvider);

    return todayAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, __) => Center(child: Text('Error: $e')),
      data: (plan) => _TodayWorkoutContent(plan: plan),
    );
  }
}

class _TodayWorkoutContent extends ConsumerWidget {
  final WorkoutPlan plan;
  const _TodayWorkoutContent({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionMap = ref.watch(exerciseCompletionProvider);
    final notifier = ref.read(exerciseCompletionProvider.notifier);

    final allNames = <String>[
      ...plan.warmUp.map((e) => e.name),
      ...plan.mainExercises.map((e) => e.name),
      ...plan.coolDown.map((e) => e.name),
    ];

    final total = allNames.length;
    final doneCount = allNames.where((n) => completionMap[n] == true).length;
    final progress = total == 0 ? 0.0 : doneCount / total;
    final pct = (progress * 100).round();
    final allDone = doneCount == total && total > 0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header card
        Container(
          decoration: premiumCardDecoration(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.dumbbell,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.title,
                            style: AppTypography.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${plan.durationMinutes} min  ${plan.level}  ${plan.focusArea}',
                          style: AppTypography.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(plan.description,
                  style: AppTypography.textTheme.bodyMedium),
              const SizedBox(height: 16),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          allDone ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$pct%',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      color: allDone ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                allDone
                    ? 'Workout complete!'
                    : '$doneCount of $total exercises done',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: allDone ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Exercise sections
        _ExerciseSectionHeader(title: plan.warmUpDescription, icon: LucideIcons.flame),
        const SizedBox(height: 8),
        ...plan.warmUp.map((e) => _ExerciseTile(
              exercise: e,
              done: completionMap[e.name] == true,
              onToggle: () => notifier.toggle(e.name),
            )),

        const SizedBox(height: 20),
        _ExerciseSectionHeader(title: 'Main Workout', icon: LucideIcons.dumbbell),
        const SizedBox(height: 8),
        ...plan.mainExercises.map((e) => _ExerciseTile(
              exercise: e,
              done: completionMap[e.name] == true,
              onToggle: () => notifier.toggle(e.name),
            )),

        const SizedBox(height: 20),
        _ExerciseSectionHeader(title: plan.coolDownDescription, icon: LucideIcons.leaf),
        const SizedBox(height: 8),
        ...plan.coolDown.map((e) => _ExerciseTile(
              exercise: e,
              done: completionMap[e.name] == true,
              onToggle: () => notifier.toggle(e.name),
            )),

        const SizedBox(height: 24),

        if (allDone)
          _MarkWorkoutDoneButton(plan: plan),
      ],
    );
  }
}

class _ExerciseSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ExerciseSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: AppTypography.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final WorkoutExercise exercise;
  final bool done;
  final VoidCallback onToggle;

  const _ExerciseTile({
    required this.exercise,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: premiumCardDecoration(),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                done ? LucideIcons.checkCircle2 : LucideIcons.circle,
                size: 20,
                color: done ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                        color: done
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.sets > 1
                          ? '${exercise.sets} sets x ${exercise.reps}'
                          : exercise.reps,
                      style: AppTypography.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkWorkoutDoneButton extends StatelessWidget {
  final WorkoutPlan plan;
  const _MarkWorkoutDoneButton({required this.plan});

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(LucideIcons.checkCircle2, size: 18),
        label: const Text('Workout Complete!'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          disabledBackgroundColor: AppColors.success,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}

// TAB 2: WORKOUT LIBRARY
class _WorkoutLibraryTab extends ConsumerStatefulWidget {
  const _WorkoutLibraryTab();

  @override
  ConsumerState<_WorkoutLibraryTab> createState() => _WorkoutLibraryTabState();
}

class _WorkoutLibraryTabState extends ConsumerState<_WorkoutLibraryTab> {
  String _selectedLevel = 'All';

  static const _levels = ['All', 'Beginner', 'Easy', 'Intermediate', 'Advanced', 'Expert'];

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(workoutPlansProvider);

    return plansAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, __) => Center(child: Text('Error: $e')),
      data: (plans) {
        final filtered = _selectedLevel == 'All'
            ? plans
            : plans.where((p) => p.level == _selectedLevel).toList();

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _levels.map((lvl) {
                  final sel = _selectedLevel == lvl;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(lvl),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedLevel = lvl),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary,
                      labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
                        color: sel ? Colors.white : AppColors.textPrimary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: sel ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final plan = filtered[index];
                  return _LibraryWorkoutCard(plan: plan);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LibraryWorkoutCard extends StatelessWidget {
  final WorkoutPlan plan;
  const _LibraryWorkoutCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: premiumCardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(plan: plan),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.dumbbell,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title,
                        style: AppTypography.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.durationMinutes} min  ${plan.level}  ${plan.focusArea}',
                      style: AppTypography.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// TAB 3: MONTHLY PLAN
class _MonthlyWorkoutTab extends ConsumerWidget {
  const _MonthlyWorkoutTab();

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(monthlyWorkoutPlanProvider);
    final now = DateTime.now();
    final monthLabel = _monthNames[now.month - 1];
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return planAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, __) => Center(child: Text('Error: $e')),
      data: (plan) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '$monthLabel 1 - $daysInMonth',
              style: AppTypography.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: plan.length,
              itemBuilder: (context, index) {
                final day = index + 1;
                final workout = plan[day]!;
                final isToday = day == now.day;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutDetailScreen(plan: workout),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: premiumCardDecoration().copyWith(
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$monthLabel $day',
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isToday
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Today',
                                  style: AppTypography.textTheme.labelSmall
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            workout.focusArea,
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${workout.durationMinutes} min',
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// DETAIL SCREEN
class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutPlan plan;

  const WorkoutDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(plan.title)),
      body: SingleChildScrollView(
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
                    child: const Icon(LucideIcons.dumbbell,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.title,
                            style: AppTypography.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${plan.durationMinutes} min  ${plan.level}  ${plan.focusArea}',
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
            const SizedBox(height: 24),
            _DetailSection(title: plan.warmUpDescription, exercises: plan.warmUp),
            const SizedBox(height: 24),
            _DetailSection(title: 'Main Workout', exercises: plan.mainExercises),
            const SizedBox(height: 24),
            _DetailSection(title: plan.coolDownDescription, exercises: plan.coolDown),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<WorkoutExercise> exercises;
  const _DetailSection({required this.title, required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...exercises.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: premiumCardDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.name,
                        style: AppTypography.textTheme.titleSmall),
                  ),
                  Text(
                    e.sets > 1 ? '${e.sets} sets x ${e.reps}' : e.reps,
                    style: AppTypography.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}