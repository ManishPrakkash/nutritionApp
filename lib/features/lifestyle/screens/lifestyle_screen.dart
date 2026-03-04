import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/theme/app_colors.dart';
import 'package:health_nutrition_app/core/theme/app_typography.dart';

class LifestyleTip {
  final String title;
  final String content;

  LifestyleTip({required this.title, required this.content});

  factory LifestyleTip.fromJson(Map<String, dynamic> json) {
    return LifestyleTip(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

class LifestyleCategory {
  final String title;
  final List<LifestyleTip> tips;

  LifestyleCategory({required this.title, required this.tips});

  factory LifestyleCategory.fromJson(Map<String, dynamic> json) {
    var tipsList = json['tips'] as List? ?? [];
    return LifestyleCategory(
      title: json['title'] ?? '',
      tips: tipsList.map((t) => LifestyleTip.fromJson(t)).toList(),
    );
  }
}

final lifestyleProvider = FutureProvider<Map<String, LifestyleCategory>>((ref) async {
  final String response = await rootBundle.loadString('assets/data/lifestyle_data.json');
  final data = await json.decode(response) as Map<String, dynamic>;

  return {
    'water': LifestyleCategory.fromJson(data['water_intake']),
    'sleep': LifestyleCategory.fromJson(data['sleep_improvement']),
    'stress': LifestyleCategory.fromJson(data['stress_management']),
  };
});

class LifestyleScreen extends ConsumerWidget {
  const LifestyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifestyleAsync = ref.watch(lifestyleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lifestyle Guide'),
      ),
      body: lifestyleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (categories) {
          final water = categories['water']!;
          final sleep = categories['sleep']!;
          final stress = categories['stress']!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildCategoryCard(context, water, Icons.local_drink),
              const SizedBox(height: 16),
              _buildCategoryCard(context, sleep, Icons.bedtime),
              const SizedBox(height: 16),
              _buildCategoryCard(context, stress, Icons.self_improvement),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, LifestyleCategory category, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(category.title, style: AppTypography.textTheme.titleMedium),
        children: category.tips.map((tip) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            title: Text(tip.title, style: AppTypography.textTheme.titleSmall),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(tip.content, style: AppTypography.textTheme.bodyMedium),
            ),
          );
        }).toList(),
      ),
    );
  }
}
