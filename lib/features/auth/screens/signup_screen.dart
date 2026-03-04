import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_nutrition_app/core/icons/lucide_fallback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/auth_error_messages.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../../profile/screens/profile_setup_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _gender = 'Male';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double get _passwordStrength =>
      Validators.passwordStrength(_passwordController.text);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final profile = UserProfile(
        uid: '',
        fullName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        heightCm: double.parse(_heightController.text.trim()),
        weightKg: double.parse(_weightController.text.trim()),
        email: _emailController.text.trim(),
        photoUrl: null,
        createdAt: DateTime.now(),
      );
      await signUpWithEmail(
        ref,
        _emailController.text.trim(),
        _passwordController.text,
        profile,
        null,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const ProfileSetupScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = AuthErrorMessages.forException(e);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      // Account may have been created but profile save failed (e.g. Firestore not configured)
      final msg = e.toString().replaceFirst('Exception: ', '').split('\n').first;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created. $msg')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const ProfileSetupScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Credentials'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join the Elite',
                  style: AppTypography.textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to start your personalized wellness journey.',
                  style: AppTypography.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Alexander Pierce',
                  ),
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Age', hintText: '25'),
                        validator: Validators.age,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                        ),
                        dropdownColor: AppColors.surface,
                        items: ['Male', 'Female', 'Other']
                            .map((s) => DropdownMenuItem(
                                value: s, 
                                child: Text(s, style: AppTypography.textTheme.bodyMedium)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _gender = v ?? 'Male'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Height (cm)', hintText: '170'),
                        validator: Validators.height,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Weight (kg)', hintText: '70'),
                        validator: Validators.weight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'alexander@example.com',
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Security Code',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? LucideIcons.eyeOff
                            : LucideIcons.eye,
                        size: 18,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: _passwordController,
                  builder: (context, _) {
                    final s = _passwordStrength;
                    final segments = 4;
                    final activeSegments = (s * segments).round();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(segments, (i) {
                            final isActive = i < activeSegments;
                            Color color = AppColors.border;
                            if (isActive) {
                              if (activeSegments <= 1) color = AppColors.error;
                              else if (activeSegments <= 3) color = AppColors.warning;
                              else color = AppColors.success;
                            }
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(right: i < segments - 1 ? 4 : 0),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Security Strength: ${s < 0.3 ? 'Weak' : s < 0.7 ? 'Standard' : 'Fortified'}',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: s < 0.3 ? AppColors.error : s < 0.7 ? AppColors.textSecondary : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? LucideIcons.eyeOff
                            : LucideIcons.eye,
                        size: 18,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => Validators.confirmPassword(
                      v, _passwordController.text),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: GoogleFonts.poppins(
                        color: AppColors.error,
                        fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already a member? ',
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Sign In',
                        style: AppTypography.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
