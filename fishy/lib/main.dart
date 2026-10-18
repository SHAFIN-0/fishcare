import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/tflite_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Preload the on-device model in the background so the first detection
  // isn't slowed down by asset loading + interpreter initialization.
  // predict() also lazy-loads if this hasn't finished yet, so this is
  // purely a warm-up and not required for correctness.
  TfliteService.instance.load();
  runApp(const FishCareApp());
}

class FishCareApp extends StatelessWidget {
  const FishCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FishCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
