import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_preferences.dart';
import '../providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/profile_setup_screen.dart';
import 'onboarding_screen.dart';
import '../../home/screens/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _progressWidth;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.4, 1, curve: Curves.easeOut)),
    );
    _progressWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _logoController.forward();
    _progressController.forward();

    Timer(const Duration(milliseconds: 2500), () => _navigate());
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    
    // Wait for the animation to finish
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      // Wait for Firebase to properly restore authentication state
      User? auth = await AuthService.instance.authStateChanges.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => AuthService.instance.currentUser,
      );

      if (!mounted) return;
      
      if (auth != null) {
        // User is authenticated, check profile and setup completion
        try {
          final profile = await ref.read(profileFutureProvider.future);
          if (!mounted) return;
          
          if (profile != null) {
            // Profile exists, check if user has completed setup
            final prefs = await ref.read(preferencesFutureProvider.future);
            final hasCompletedSetup = _isSetupComplete(prefs);
            
            if (hasCompletedSetup) {
              // User is fully set up, go to home
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            } else {
              // Profile exists but setup not complete
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
                (route) => false,
              );
            }
          } else {
            // Authenticated but no profile found - need to complete setup
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              (route) => false,
            );
          }
        } catch (e) {
          debugPrint('Profile loading error: $e');
          // Error loading profile data - user might be new or having connection issues
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
            (route) => false,
          );
        }
      } else {
        // Not authenticated, go to onboarding
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback to onboarding on any error
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    }
  }

  /// Determines if user has completed the initial setup process
  bool _isSetupComplete(UserPreferences? prefs) {
    if (prefs == null) return false;
    
    // User has completed setup if they have:
    // 1. Selected a health goal (required field from step 1)
    // 2. Selected an activity level (step 2, defaults to 'moderate')
    return prefs.healthGoal.isNotEmpty && 
           prefs.activityLevel.isNotEmpty;
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAFAFA), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Animated Logo with Neon Green Background
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_menu_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // App Name
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _taglineOpacity.value,
                    child: Column(
                      children: [
                        Text(
                          'Nutriapp',
                          style: AppTypography.textTheme.displaySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PREMIUM NUTRITION',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(flex: 3),
              // Loading Progress Section
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  final progressValue = _progressWidth.value;
                  return Column(
                    children: [
                      Text(
                        'INITIALIZING',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: (MediaQuery.of(context).size.width * 0.6) * progressValue,
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(progressValue * 100).round()}%',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
