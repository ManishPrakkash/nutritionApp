import 'package:flutter/material.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';

class StressScreen extends StatelessWidget {
  const StressScreen({super.key});

  static const List<Map<String, String>> _tips = [
    {'title': 'Breathing exercises', 'body': 'Try 4-7-8 breathing: inhale 4 sec, hold 7 sec, exhale 8 sec. Repeat 3–4 times.'},
    {'title': 'Short walks', 'body': 'A 10–15 minute walk can lower cortisol and improve mood.'},
    {'title': 'Sleep routine', 'body': 'Keep a fixed bedtime and avoid screens 1 hour before sleep.'},
    {'title': 'Mindfulness', 'body': 'Spend 5–10 minutes daily on meditation or body-scan relaxation.'},
    {'title': 'Stay hydrated', 'body': 'Dehydration can increase stress; aim for 2–2.5 L of water per day.'},
    {'title': 'Set boundaries', 'body': 'Learn to say no and block time for rest and hobbies.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stress Management'),
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
                    Icon(LucideIcons.heart, size: 40, color: AppColors.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manage stress for better health', style: AppTypography.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Small daily habits can reduce stress and improve sleep and focus.',
                            style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Recommendations', style: AppTypography.textTheme.titleMedium),
              const SizedBox(height: 16),
              ..._tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: premiumCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.checkCircle2, size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(
                            t['title']!,
                            style: AppTypography.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t['body']!,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
