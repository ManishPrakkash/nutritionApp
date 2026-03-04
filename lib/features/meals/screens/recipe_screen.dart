import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/meal.dart';
import '../../../services/api_service.dart';
import 'recipe_detail_screen.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  final _ingredients = <String>[];
  final _searchController = TextEditingController();
  List<Meal> _results = [];
  bool _loading = false;

  Future<void> _engineerRecipes() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await ApiService.instance.searchRecipes(_ingredients);
      if (mounted) {
        setState(() {
          _results = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch recipes')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Culinary Intelligence'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by ingredient...',
                  prefixIcon: Icon(LucideIcons.search, size: 18),
                ),
              ),
              const SizedBox(height: 24),
              Text('Inventory Analysis', style: AppTypography.textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._ingredients.map((i) => Chip(
                        label: Text(i),
                        onDeleted: () => setState(() => _ingredients.remove(i)),
                        deleteIcon: const Icon(LucideIcons.x, size: 14),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        labelStyle: AppTypography.textTheme.bodySmall,
                      )),
                  ActionChip(
                    label: const Text('ADD'),
                    onPressed: () {
                      final t = _searchController.text.trim();
                      if (t.isNotEmpty && !_ingredients.contains(t)) {
                        setState(() {
                          _ingredients.add(t);
                          _searchController.clear();
                        });
                      }
                    },
                    avatar: const Icon(LucideIcons.plus, size: 14),
                    backgroundColor: AppColors.primary,
                    labelStyle: AppTypography.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _engineerRecipes,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(LucideIcons.chefHat, size: 18),
                  label: Text(_loading ? 'Searching…' : 'Engineer Recipes'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _results.isEmpty ? 'Curated Suggestions' : 'Recipes (${_results.length})',
                    style: AppTypography.textTheme.titleMedium,
                  ),
                  const Icon(LucideIcons.sparkles, size: 18, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 16),
              if (_results.isEmpty) ...[
                const _RecipeCard(meal: null, name: 'Saffron Grilled Salmon', time: 25, cal: 420),
                const SizedBox(height: 16),
                const _RecipeCard(meal: null, name: 'Truffle Quinoa Bowl', time: 15, cal: 350),
                const SizedBox(height: 16),
                const _RecipeCard(meal: null, name: 'Mediterranean Salad', time: 10, cal: 280),
              ] else
                ..._results.map((meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _RecipeCard(meal: meal, name: meal.name, time: meal.prepMinutes, cal: meal.calories),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Meal? meal;
  final String name;
  final int time;
  final int cal;

  const _RecipeCard({this.meal, required this.name, required this.time, required this.cal});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: meal != null
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(meal: meal!),
                ),
              )
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: premiumCardDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    Text(name, style: AppTypography.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.timer, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('$time min', style: AppTypography.textTheme.bodySmall),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.flame, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('$cal kcal', style: AppTypography.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
