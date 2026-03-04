import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Neon Green Theme
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF39FF14); // Custom Neon Green
  static const Color primaryDark = Color(0xFF32E512); // Darker Custom Neon Green
  static const Color primaryLight = Color(0xFF6AFF47); // Lighter Custom Neon Green
  static const Color secondary = Color(0xFF1A1A1A); // Dark text/elements
  static const Color accent = Color(0xFF333333); // Dark accent
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF999999);

  // Functional Colors
  static const Color border = Color(0xFFE5E5E5);
  static const Color error = Color(0xFFFF4757);
  static const Color success = Color(0xFF39FF14); // Use custom neon green for success
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Shadows & Overlays
  static const Color shadow = Color(0x0F000000);
  static const Color overlay = Color(0x66000000);
  static const Color glassEffect = Color(0xCCFFFFFF);

  // Custom Neon Green Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF39FF14), Color(0xFF32E512)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0x1A39FF14), Color(0x0A32E512)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
