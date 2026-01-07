import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════
// 🎨 COULEURS CORIDE (du Figma)
// ═══════════════════════════════════════════════
class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF1e3a8a); // Bleu foncé
  static const Color accent = Color(0xFF06b6d4); // Turquoise

  // Couleurs de fond
  static const Color background = Color(0xFFFFFFFF); // Blanc
  static const Color cardBackground = Color(0xFFF8F9FA); // Gris très clair

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF2C2E3E); // Texte principal
  static const Color textSecondary = Color(0xFF6B7280); // Texte secondaire
  static const Color textMuted = Color(0xFF9CA3AF); // Texte discret

  // Couleurs fonctionnelles
  static const Color success = Color(0xFF10B981); // Vert
  static const Color warning = Color(0xFFF59E0B); // Orange
  static const Color error = Color(0xFFEF4444); // Rouge

  // Dégradé principal (bleu foncé → cyan brillant)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1e3a8a), Color(0xFF0891b2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Dégradé header (plus prononcé)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0c2d5a), Color(0xFF06b6d4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════
// 📏 ESPACEMENTS
// ═══════════════════════════════════════════════
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ═══════════════════════════════════════════════
// 🔤 TEXTES (en français)
// ═══════════════════════════════════════════════
class AppStrings {
  // App
  static const String appName = 'CoRide';
  static const String appTagline = 'Connecting your journeys';

  // Onboarding
  static const String onboarding1Title = 'Voyagez autrement';
  static const String onboarding1Subtitle =
      'Covoiturage simple, rapide et économique.';
  static const String onboarding2Title = 'Trouvez votre conducteur';
  static const String onboarding2Subtitle =
      'Connectez-vous en quelques secondes.';
  static const String onboarding3Title = 'Partagez vos trajets';
  static const String onboarding3Subtitle = 'Publiez vos trajets facilement.';

  // Auth
  static const String phoneNumber = 'Numéro de téléphone';
  static const String enterPhoneNumber = 'Entrez votre numéro';
  static const String verifyOTP = 'Vérifier le code';
  static const String otpSent = 'Code envoyé par SMS';

  // Home
  static const String popularRides = 'Trajets populaires';
  static const String searchRide = 'Rechercher un trajet';
  static const String from = 'Départ';
  static const String to = 'Arrivée';
  static const String date = 'Date';

  // Buttons
  static const String next = 'Suivant';
  static const String skip = 'Passer';
  static const String start = 'Commencer';
  static const String search = 'Rechercher';
  static const String publish = 'Publier';
  static const String book = 'Réserver';
  static const String cancel = 'Annuler';
}

// ═══════════════════════════════════════════════
// 🖼️ ASSETS (chemins des images)
// ═══════════════════════════════════════════════
class AppAssets {
  static const String logo = 'assets/images/logo.png';
  static const String widget = 'assets/images/CoRide.png';
}

// ═══════════════════════════════════════════════
// ⏱️ DURÉES
// ═══════════════════════════════════════════════
class AppDurations {
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}

// ═══════════════════════════════════════════════
// 📐 BORDER RADIUS
// ═══════════════════════════════════════════════
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}
