import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('fr_FR', null);
  // orientation portrait
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
      title: 'Tunisia CoRide',
      debugShowCheckedModeBanner: false,

      // Thème
      theme: AppTheme.lightTheme,

      // Premier écran
      home: const SplashScreen(),
    );
  }
}
