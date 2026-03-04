import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/icons/lucide_fallback.dart';
import '../../../models/meal.dart';
import '../providers/meal_provider.dart';
import '../../../core/theme/app_theme.dart';

class MealDetailScreen extends ConsumerWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alternativesAsync = ref.watch(mealAlternativesProvider({
      'mealId': meal.id,
      'mealType': meal.mealType,
    }));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                meal.name,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 10)],
                ),
              ),
              background: meal.imageUrl != null
                  ? Image.network(meal.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(LucideIcons.chefHat, size: 80, color: Colors.white),
                    ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNutritionRow(),
                    const SizedBox(height: 32),
                    Text('Ingredients', style: AppTypography.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    ...meal.ingredients.map((ing) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(child: Text(ing, style: AppTypography.textTheme.bodyMedium)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 32),
                    Text('Preparation', style: AppTypography.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    ...meal.steps.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Text(entry.value, style: AppTypography.textTheme.bodyMedium)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 32),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NutrientItem(label: 'Calories', value: '${meal.calories}', unit: 'kcal'),
          _NutrientItem(label: 'Protein', value: '${meal.protein}', unit: 'g'),
          _NutrientItem(label: 'Carbs', value: '${meal.carbs}', unit: 'g'),
          _NutrientItem(label: 'Fats', value: '${meal.fat}', unit: 'g'),
        ],
      ),
    );
  }
}

class _NutrientItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _NutrientItem({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.textTheme.headlineSmall?.copyWith(fontSize: 18)),
        Text(unit, style: AppTypography.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _AlternativeMealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;

  const _AlternativeMealCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: premiumCardDecoration().copyWith(
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: meal.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(meal.imageUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(LucideIcons.chefHat, size: 24, color: AppColors.textMuted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: AppTypography.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meal.calories} kcal • ${meal.prepMinutes} min',
                    style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniNutrient(label: 'P', value: '${meal.protein}g'),
                      const SizedBox(width: 12),
                      _MiniNutrient(label: 'C', value: '${meal.carbs}g'),
                      const SizedBox(width: 12),
                      _MiniNutrient(label: 'F', value: '${meal.fat}g'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MiniNutrient extends StatelessWidget {
  final String label;
  final String value;

  const _MiniNutrient({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.textTheme.labelSmall?.copyWith(fontSize: 9),
      ),
    );
  }
}
