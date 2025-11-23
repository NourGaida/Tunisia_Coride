import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';

void main() {
  // Configuration avant de lancer l'app
  WidgetsFlutterBinding.ensureInitialized();

  // Forcer l'orientation portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Lancer l'app
  runApp(const CoRideApp());
}

class CoRideApp extends StatelessWidget {
  const CoRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Configuration générale
      title: 'Tunisia CoRide', // ← Nom affiché dans l'émulateur
      debugShowCheckedModeBanner: false,

      // Thème
      theme: AppTheme.lightTheme,

      // Premier écran
      home: const SplashScreen(),
    );
  }
}
