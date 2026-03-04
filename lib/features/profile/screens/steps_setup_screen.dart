import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import 'package:health_nutrition_app/core/theme/app_colors.dart';
import 'package:health_nutrition_app/core/theme/app_typography.dart';
import 'package:health_nutrition_app/features/profile/screens/profile_setup_screen.dart';

class StepsSetupScreen extends ConsumerStatefulWidget {
  const StepsSetupScreen({super.key});

  @override
  ConsumerState<StepsSetupScreen> createState() => _StepsSetupScreenState();
}

class _StepsSetupScreenState extends ConsumerState<StepsSetupScreen> {
  final _stepsController = TextEditingController(text: '10000');

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Step 1 of 4'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const LinearProgressIndicator(
              value: 1 / 4,
              minHeight: 2,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Step Goal",
                      style: AppTypography.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Set a daily step goal to stay active.",
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _stepsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Steps Goal',
                        hintText: 'e.g. 10000',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: ElevatedButton(
                onPressed: () {
                  final steps = int.tryParse(_stepsController.text) ?? 10000;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileSetupScreen(
                        initialStep: 0,
                        stepsGoal: steps,
                      ),
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
