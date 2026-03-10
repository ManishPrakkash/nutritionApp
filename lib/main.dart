import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'features/auth/screens/logo_screen.dart';
import 'core/theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  ApiService.instance.init();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // FCM on web requires firebase-messaging-sw.js; skip init on web to avoid service worker errors.
    if (!kIsWeb) {
      NotificationService.instance.init();
    }
  } catch (e) {
    debugPrint('Firebase init failed. Run: dart run flutterfire configure');
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }
  runApp(
    const ProviderScope(
      child: HealthNutritionApp(),
    ),
  );
}

class HealthNutritionApp extends StatelessWidget {
  const HealthNutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutriapp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LogoScreen(),
    );
  }
}
