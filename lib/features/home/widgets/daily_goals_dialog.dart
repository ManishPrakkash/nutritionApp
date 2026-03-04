import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/firestore_service.dart';

/// A dialog that asks the user to enter their daily water, steps, and sleep
/// goals. Shown once per day; if not submitted it keeps appearing.
class DailyGoalsDialog extends StatefulWidget {
  final String uid;
  final double defaultWater;
  final int defaultSteps;
  final double defaultSleep;

  const DailyGoalsDialog({
    super.key,
    required this.uid,
    required this.defaultWater,
    required this.defaultSteps,
    required this.defaultSleep,
  });

  /// Shows the dialog. Returns `true` when goals were saved, `null` if dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required String uid,
    required double defaultWater,
    required int defaultSteps,
    required double defaultSleep,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DailyGoalsDialog(
        uid: uid,
        defaultWater: defaultWater,
        defaultSteps: defaultSteps,
        defaultSleep: defaultSleep,
      ),
    );
  }

  @override
  State<DailyGoalsDialog> createState() => _DailyGoalsDialogState();
}

class _DailyGoalsDialogState extends State<DailyGoalsDialog> {
  late TextEditingController _waterCtrl;
  late TextEditingController _stepsCtrl;
  late TextEditingController _sleepCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _waterCtrl =
        TextEditingController(text: widget.defaultWater.toStringAsFixed(1));
    _stepsCtrl = TextEditingController(text: widget.defaultSteps.toString());
    _sleepCtrl =
        TextEditingController(text: widget.defaultSleep.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _waterCtrl.dispose();
    _stepsCtrl.dispose();
    _sleepCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final water = double.tryParse(_waterCtrl.text.trim());
    final steps = int.tryParse(_stepsCtrl.text.trim());
    final sleep = double.tryParse(_sleepCtrl.text.trim());

    if (water == null || steps == null || sleep == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    setState(() => _saving = true);
    final today = DateTime.now().toIso8601String().split('T').first;
    await FirestoreService.instance.saveDailyGoals(
      widget.uid, today, water, steps, sleep,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: 32, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              "Set Today's Goals",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your daily targets',
              style: AppTypography.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            _GoalField(
              controller: _waterCtrl,
              icon: LucideIcons.droplets,
              label: 'Water (liters)',
              suffix: 'L',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
              ],
            ),
            const SizedBox(height: 16),
            _GoalField(
              controller: _stepsCtrl,
              icon: LucideIcons.running,
              label: 'Steps',
              suffix: 'steps',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            _GoalField(
              controller: _sleepCtrl,
              icon: LucideIcons.moon,
              label: 'Sleep (hours)',
              suffix: 'h',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Goals'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  const _GoalField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.suffix,
    required this.keyboardType,
    required this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: premiumCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: AppTypography.textTheme.titleSmall,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: AppTypography.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                suffixText: suffix,
                suffixStyle: AppTypography.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
