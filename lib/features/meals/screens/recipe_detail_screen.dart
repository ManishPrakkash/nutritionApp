import 'package:flutter/material.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/meal.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Meal meal;

  const RecipeDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(meal.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: premiumCardDecoration(),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.utensils, size: 28, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.timer, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text('${meal.prepMinutes} min', style: AppTypography.textTheme.bodySmall),
                              const SizedBox(width: 16),
                              const Icon(LucideIcons.flame, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text('${meal.calories} kcal', style: AppTypography.textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Nutrition per serving', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _NutrientChip(label: 'P', value: '${meal.protein.toInt()}g'),
                              const SizedBox(width: 8),
                              _NutrientChip(label: 'C', value: '${meal.carbs.toInt()}g'),
                              const SizedBox(width: 8),
                              _NutrientChip(label: 'F', value: '${meal.fat.toInt()}g'),
                              if (meal.fiber > 0) ...[
                                const SizedBox(width: 8),
                                _NutrientChip(label: 'Fiber', value: '${meal.fiber.toInt()}g'),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (meal.ingredients.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Ingredients', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...meal.ingredients.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.circle, size: 6, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(i, style: AppTypography.textTheme.bodyMedium)),
                    ],
                  ),
                )),
              ],
              if (meal.steps.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Steps', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...meal.steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('${e.key + 1}', style: AppTypography.textTheme.titleSmall?.copyWith(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.value, style: AppTypography.textTheme.bodyMedium)),
                    ],
                  ),
                )),
              ],
              if (meal.ingredients.isEmpty && meal.steps.isEmpty) ...[
                const SizedBox(height: 16),
                Text('No ingredients or steps available for this recipe.', style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text('$label: $value', style: AppTypography.textTheme.bodySmall),
    );
  }
}
