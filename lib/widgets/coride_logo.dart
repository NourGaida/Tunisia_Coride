import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CoRideLogo extends StatelessWidget {
  final double size;
  final bool withBackground;

  const CoRideLogo({
    super.key,
    this.size = 100,
    this.withBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) =>
          Icon(Icons.directions_car, size: size, color: AppColors.primary),
    );

    if (withBackground) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: image,
      );
    }
    return image;
  }
}
