import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  final int caloriesConsumed;
  final int caloriesTarget;
  final double waterLiters;
  final int steps;
  final double sleepHours;

  // Per-day goals
  final double waterTargetLiters;
  final int stepsTarget;
  final double sleepTargetHours;

  const SummaryCard({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.waterLiters,
    required this.steps,
    required this.sleepHours,
    required this.waterTargetLiters,
    required this.stepsTarget,
    required this.sleepTargetHours,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDFF9D5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Control Center",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D312E),
                  ),
                ),
                Icon(LucideIcons.running, size: 18, color: const Color(0xFF19FF00)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "${Formatters.calories(caloriesTarget)} kcal",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D312E),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  icon: LucideIcons.droplets,
                  label: 'Water Goal',
                  value: '${waterTargetLiters.toStringAsFixed(1)}L',
                ),
                _MiniStat(
                  icon: LucideIcons.running,
                  label: 'Steps Goal',
                  value: Formatters.steps(stepsTarget),
                ),
                _MiniStat(
                  icon: LucideIcons.moon,
                  label: 'Sleep Goal',
                  value: "${sleepTargetHours.toStringAsFixed(1)}h",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF19FF00)),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D312E),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFA2AAA4),
          ),
        ),
      ],
    );
  }
}
