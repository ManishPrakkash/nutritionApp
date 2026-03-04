class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) return 'Enter age 1–120';
    return null;
  }

  static String? height(String? value) {
    if (value == null || value.isEmpty) return 'Height is required';
    final h = double.tryParse(value);
    if (h == null || h < 100 || h > 250) return 'Enter height 100–250 cm';
    return null;
  }

  static String? weight(String? value) {
    if (value == null || value.isEmpty) return 'Weight is required';
    final w = double.tryParse(value);
    if (w == null || w < 20 || w > 200) return 'Enter weight 20–200 kg';
    return null;
  }

  /// Returns 0-1 for password strength (0=weak, 1=strong)
  static double passwordStrength(String password) {
    if (password.isEmpty) return 0;
    double score = 0;
    if (password.length >= 8) score += 0.25;
    if (password.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.2;
    return score.clamp(0.0, 1.0);
  }
}
