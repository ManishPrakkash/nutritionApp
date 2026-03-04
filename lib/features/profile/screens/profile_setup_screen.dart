import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_preferences.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../home/screens/home_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final int initialStep;
  final int stepsGoal;
  /// When true, load existing preferences and on Finish pop back instead of going to Home.
  final bool editMode;

  const ProfileSetupScreen({super.key, this.initialStep = 0, this.editMode = false, this.stepsGoal = 10000});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late int _step;
  List<String> _dietTypes = [];
  List<String> _allergies = [];
  String _healthGoal = '';
  List<String> _medicalHistory = [];
  String _activityLevel = 'moderate';
  List<String> _preferredCuisine = [];
  bool _isFinishing = false;
  bool _prefsLoaded = false;

  static const List<String> dietOptions = [
    'Vegetarian',
    'Vegan',
    'Non-Veg',
    'Keto',
    'Paleo',
    'Mediterranean',
    'Gluten-Free',
    'Dairy-Free',
  ];
  static const List<String> allergyOptions = [
    'Dairy',
    'Gluten',
    'Nuts',
    'Shellfish',
    'Eggs',
    'None',
  ];
  static const List<String> goalOptions = [
    'Weight Loss',
    'Muscle Gain',
    'Maintain Weight',
    'General Health',
    'Improve Stamina',
    'Reduce Stress',
  ];
  static const List<String> medicalOptions = [
    'Diabetes',
    'Hypertension',
    'PCOD',
    'Thyroid',
    'None',
    'Other',
  ];
  static const List<String> activityLevels = [
    'sedentary',
    'light',
    'moderate',
    'active',
    'extreme',
  ];
  static const List<String> activityLabels = [
    'Sedentary',
    'Light',
    'Moderate',
    'Active',
    'Extreme',
  ];
  static const List<String> cuisineOptions = [
    'Indian',
    'Mediterranean',
    'Asian',
    'Continental',
    'Mexican',
  ];

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  void _loadExistingPreferences(WidgetRef ref) {
    if (!widget.editMode || _prefsLoaded) return;
    _prefsLoaded = true;
    ref.read(preferencesFutureProvider.future).then((prefs) {
      if (!mounted || prefs == null) return;
      setState(() {
        _dietTypes = List.from(prefs.dietTypes);
        _allergies = List.from(prefs.allergies);
        _healthGoal = prefs.healthGoal;
        _medicalHistory = List.from(prefs.medicalHistory);
        _activityLevel = prefs.activityLevel;
        _preferredCuisine = List.from(prefs.preferredCuisine);
      });
    });
  }

  bool get _canProceed {
    if (_step == 0) return _dietTypes.isNotEmpty;
    if (_step == 1) return _healthGoal.isNotEmpty;
    if (_step == 2) return _preferredCuisine.isNotEmpty;
    return true;
  }

  Future<void> _finish() async {
    if (!mounted || _isFinishing) return;
    setState(() => _isFinishing = true);
    final uid = ref.read(authUserIdProvider);
    if (uid == null) {
      if (mounted) {
        setState(() => _isFinishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in again and complete setup.')),
        );
      }
      return;
    }
    final prefs = UserPreferences(
      dietTypes: _dietTypes,
      allergies: _allergies,
      healthGoal: _healthGoal,
      medicalHistory: _medicalHistory,
      activityLevel: _activityLevel,
      preferredCuisine: _preferredCuisine,
      stepsGoal: widget.stepsGoal,
    );
    try {
      await savePreferences(ref, uid, prefs);
      
      // Mark setup as completed in SharedPreferences for faster future checks
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setBool('setup_completed', true);
      await sharedPrefs.setString('user_uid', uid);
      
    } catch (e) {
      if (mounted) {
        setState(() => _isFinishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save to database. Check your internet and try again.',
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.primary,
              onPressed: () => _finish(),
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    if (widget.editMode) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences updated')),
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadExistingPreferences(ref);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.editMode ? 'Edit Preferences' : 'Step ${_step + 1} of 3'),
        centerTitle: true,
        leading: _step > 0 
          ? IconButton(
              icon: const Icon(LucideIcons.arrowLeft, size: 20),
              onPressed: () => setState(() => _step--),
            )
          : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              minHeight: 2,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: _step == 0 ? _buildStep0() : _step == 1 ? _buildStep1() : _buildStep2(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: ElevatedButton(
                onPressed: _canProceed && !_isFinishing
                    ? () {
                        if (_step < 2) {
                          setState(() => _step++);
                        } else {
                          _finish();
                        }
                      }
                    : null,
                child: _isFinishing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_step < 2 ? 'Continue' : 'Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Personalized Palette",
          style: AppTypography.textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        Text(
          "Select your dietary preferences and any known allergies for a curated experience.",
          style: AppTypography.textTheme.bodyMedium,
        ),
        const SizedBox(height: 48),
        Text(
          "Dietary Preference",
          style: AppTypography.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: dietOptions.map((d) {
            final selected = _dietTypes.contains(d);
            return FilterChip(
              label: Text(d),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  _dietTypes
                    ..clear()
                    ..addAll(v ? [d] : []);
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        Text(
          'Known Allergies',
          style: AppTypography.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: allergyOptions.map((a) {
            final selected = _allergies.contains(a);
            return FilterChip(
              label: Text(a),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) _allergies.add(a);
                  else _allergies.remove(a);
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Target Vision",
          style: AppTypography.textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        Text(
          "Define your primary health objective to tailor your recommendations.",
          style: AppTypography.textTheme.bodyMedium,
        ),
        const SizedBox(height: 48),
        ...goalOptions.map((g) {
          final selected = _healthGoal == g;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _healthGoal = g),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: premiumCardDecoration().copyWith(
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? LucideIcons.circleCheck : LucideIcons.circle,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      g, 
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 48),
        Text('Medical History (Optional)', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: medicalOptions.map((m) {
            final selected = _medicalHistory.contains(m);
            return FilterChip(
              label: Text(m),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) _medicalHistory.add(m);
                  else _medicalHistory.remove(m);
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vigor Analysis',
          style: AppTypography.textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Define your typical daily activity and culinary preferences.',
          style: AppTypography.textTheme.bodyMedium,
        ),
        const SizedBox(height: 48),
        Text(
          'Daily Activity Level',
          style: AppTypography.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...List.generate(5, (i) {
          final selected = _activityLevel == activityLevels[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _activityLevel = activityLevels[i]),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: premiumCardDecoration().copyWith(
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? LucideIcons.circleCheck : LucideIcons.circle,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      activityLabels[i], 
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 48),
        Text('Preferred Cuisine', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cuisineOptions.map((c) {
            final selected = _preferredCuisine.contains(c);
            return FilterChip(
              label: Text(c),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  _preferredCuisine
                    ..clear()
                    ..addAll(v ? [c] : []);
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}
