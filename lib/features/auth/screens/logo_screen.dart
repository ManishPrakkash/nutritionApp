import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_nutrition_app/features/auth/screens/onboarding_screen.dart';
import 'package:health_nutrition_app/features/home/screens/home_screen.dart';
import 'package:health_nutrition_app/services/auth_service.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show logo for at least 2 seconds while we check auth state
    final minSplash = Future.delayed(const Duration(seconds: 2));

    // Wait for Firebase to restore any persisted session
    final user = await AuthService.instance.firstAuthState;

    // Check if setup was completed previously
    final prefs = await SharedPreferences.getInstance();
    final setupDone = prefs.getBool('setup_completed') ?? false;

    await minSplash; // ensure logo is visible long enough
    if (!mounted) return;

    if (user != null && setupDone) {
      // Already signed in & setup completed → go straight to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // First launch or not signed in → onboarding / login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/images/logo.jpeg'),
      ),
    );
  }
}
