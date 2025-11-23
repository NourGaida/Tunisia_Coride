import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/constants.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _dotsController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation du logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animation des points (boucle infinie)
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(); // Boucle infinie

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Lancer animation du logo
    _logoController.forward();

    // Navigation vers onboarding après 2.5s
    Timer(AppDurations.splashDuration + const Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animé
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    AppAssets.logo,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Si l'image ne charge pas, afficher une icône
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          size: 100,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Texte CoRide
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                            letterSpacing: 2,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.appTagline,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // Points animés (boucle infinie)
              FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedBuilder(
                  animation: _dotsController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedDot(0),
                        const SizedBox(width: 12),
                        _buildAnimatedDot(1),
                        const SizedBox(width: 12),
                        _buildAnimatedDot(2),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Point animé avec effet de vague
  Widget _buildAnimatedDot(int index) {
    // Délai pour chaque point
    final delay = index * 0.2;

    // Calculer la progression de l'animation avec délai
    double progress = (_dotsController.value - delay) % 1.0;
    if (progress < 0) progress += 1.0;

    // Animation de scale (agrandissement/rétrécissement)
    final scale = 0.6 + (0.4 * (1 - (progress - 0.5).abs() * 2));

    // Animation d'opacité
    final opacity = 0.3 + (0.7 * (1 - (progress - 0.5).abs() * 2));

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: opacity * 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
