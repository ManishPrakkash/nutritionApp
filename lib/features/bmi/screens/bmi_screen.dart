import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

class BmiScreen extends ConsumerStatefulWidget {
  const BmiScreen({super.key});

  @override
  ConsumerState<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends ConsumerState<BmiScreen> {
  double _weight = 70;
  double _height = 170;
  String _activityLevel = 'moderate';
  bool _saving = false;

  double get _bmi => _weight / ((_height / 100) * (_height / 100));
  int get _age => ref.read(profileProvider).valueOrNull?.age ?? 30;
  
  double get _bmr {
    final base = 10 * _weight + 6.25 * _height - 5 * _age;
    return ref.read(profileProvider).valueOrNull?.gender?.toLowerCase() == 'female'
        ? base - 161
        : base + 5;
  }

  double get _tdee {
    const factors = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'extreme': 1.9,
    };
    return _bmr * (factors[_activityLevel] ?? 1.55);
  }

  Map<String, dynamic> get _macronutrients {
    // Standard macronutrient distribution: 20% protein, 50% carbs, 30% fat
    final proteinCalories = _tdee * 0.20;
    final carbCalories = _tdee * 0.50;
    final fatCalories = _tdee * 0.30;
    
    return {
      'protein': (proteinCalories / 4).round(), // 4 calories per gram
      'carbs': (carbCalories / 4).round(),      // 4 calories per gram
      'fat': (fatCalories / 9).round(),         // 9 calories per gram
      'proteinPercent': 20,
      'carbsPercent': 50,
      'fatPercent': 30,
    };
  }

  Color get _bmiColor {
    if (_bmi < 18.5) return AppColors.info;
    if (_bmi <= 25) return AppColors.success;
    if (_bmi <= 30) return AppColors.warning;
    return AppColors.error;
  }

  String get _bmiCategory {
    if (_bmi < 18.5) return 'Underweight';
    if (_bmi <= 25) return 'Optimal';
    if (_bmi <= 30) return 'Overweight';
    return 'Obese';
  }

  Future<void> _saveToDb() async {
    final uid = ref.read(authUserIdProvider);
    final profile = await ref.read(profileFutureProvider.future);
    if (uid == null || profile == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await FirestoreService.instance.addWeightLog(uid, DateTime.now(), _weight);
      final updated = profile.copyWith(
        weightKg: _weight,
        heightCm: _height,
        bmi: _bmi,
        bmr: _bmr,
        tdee: _tdee,
      );
      await saveProfile(ref, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intelligence profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Biometric Analysis'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              premiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Current BMI Index',
                        style: AppTypography.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 24),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 1000),
                            builder: (context, value, child) {
                              return SizedBox(
                                width: 160,
                                height: 160,
                                child: CircularProgressIndicator(
                                  value: (_bmi / 40).clamp(0, 1) * value,
                                  strokeWidth: 12,
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(_bmiColor),
                                  strokeCap: StrokeCap.round,
                                ),
                              );
                            },
                          ),
                          Column(
                            children: [
                              Text(
                                _bmi.toStringAsFixed(1),
                                style: AppTypography.numbers(36).copyWith(color: AppColors.textPrimary),
                              ),
                              Text(
                                _bmiCategory,
                                style: AppTypography.textTheme.bodySmall?.copyWith(
                                  color: _bmiColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'BMR',
                      value: _bmr.round().toString(),
                      unit: 'kcal',
                      icon: LucideIcons.zap,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      label: 'TDEE',
                      value: _tdee.round().toString(),
                      unit: 'kcal',
                      icon: LucideIcons.flame,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              premiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.barChart3, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text('Daily Macronutrient Target', style: AppTypography.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _MacroCard(
                              label: 'Protein',
                              value: _macronutrients['protein'].toString(),
                              unit: 'g',
                              percentage: _macronutrients['proteinPercent'].toString(),
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MacroCard(
                              label: 'Carbs',
                              value: _macronutrients['carbs'].toString(),
                              unit: 'g',
                              percentage: _macronutrients['carbsPercent'].toString(),
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MacroCard(
                              label: 'Fat',
                              value: _macronutrients['fat'].toString(),
                              unit: 'g',
                              percentage: _macronutrients['fatPercent'].toString(),
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              premiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Intelligence Inputs', style: AppTypography.textTheme.titleMedium),
                      const SizedBox(height: 20),
                      _buildSlider('Weight', _weight, 30, 150, 'kg', (v) => setState(() => _weight = v)),
                      const SizedBox(height: 16),
                      _buildSlider('Height', _height, 100, 220, 'cm', (v) => setState(() => _height = v)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _activityLevel,
                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                        decoration: const InputDecoration(
                          labelText: 'Activity Velocity',
                        ),
                        items: ['sedentary', 'light', 'moderate', 'active', 'extreme']
                            .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e[0].toUpperCase() + e.substring(1), style: AppTypography.textTheme.bodyMedium)))
                            .toList(),
                        onChanged: (v) => setState(() => _activityLevel = v ?? 'moderate'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saving ? null : _saveToDb,
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('UPDATE BIOMETRICS'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.textTheme.bodySmall),
            Text('${value.toStringAsFixed(1)} $unit', style: AppTypography.textTheme.titleSmall?.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.unit, required this.icon});

  @override
  Widget build(BuildContext context) {
    return premiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.numbers(20)),
            Text(unit, style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String percentage;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.numbers(18).copyWith(color: AppColors.textPrimary)),
          Text(unit, style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text('($percentage%)', style: AppTypography.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          )),
        ],
      ),
    );
  }
}
