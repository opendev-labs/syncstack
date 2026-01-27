import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The SVG Logo with "Buttery Smooth" Animation
            SvgPicture.asset(
              'assets/icons/logo.svg',
              width: 120,
              height: 120,
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: 2000.ms,
              color: AppTheme.cyanAccent.withOpacity(0.3),
            )
            .scale(
              duration: 2000.ms,
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              curve: Curves.easeInOut,
            )
            .then(delay: 2000.ms),
            
            const SizedBox(height: 40),
            
            // Minimalist Loading Bar
            SizedBox(
              width: 200,
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.cyanAccent.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyanAccent),
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms, duration: 1000.ms),
            
            const SizedBox(height: 20),
            
            Text(
              'INITIALIZING SYNCSTACK',
              style: TextStyle(
                color: AppTheme.cyanAccent.withOpacity(0.5),
                fontSize: 10,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms)
            .shimmer(delay: 2000.ms),
          ],
        ),
      ),
    );
  }
}
