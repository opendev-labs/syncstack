import 'package:flutter/material.dart';
import 'dart:math' as math;

class GitHubLogoPainter extends CustomPainter {
  final double glowIntensity;
  final Color color;

  GitHubLogoPainter({
    this.glowIntensity = 0.5,
    this.color = const Color(0xFF00FF41),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glowIntensity)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 100;

    // Draw glow
    canvas.drawCircle(center, 40 * scale, glowPaint);

    // Precise Official-style GitHub Octocat silhouette
    final path = Path();
    
    // Top head curve and ears
    path.moveTo(center.dx, center.dy - 48 * scale);
    path.cubicTo(
      center.dx + 26.5 * scale, center.dy - 48 * scale,
      center.dx + 48 * scale, center.dy - 26.5 * scale,
      center.dx + 48 * scale, center.dy
    );
    path.cubicTo(
      center.dx + 48 * scale, center.dy + 21.2 * scale,
      center.dx + 34.3 * scale, center.dy + 39.2 * scale,
      center.dx + 15.4 * scale, center.dy + 45.4 * scale
    );
    path.cubicTo(
      center.dx + 12.8 * scale, center.dy + 46.2 * scale,
      center.dx + 12.1 * scale, center.dy + 45.1 * scale,
      center.dx + 12.1 * scale, center.dy + 43.1 * scale
    );
    path.lineTo(center.dx + 12.1 * scale, center.dy + 31.3 * scale);
    
    // Ears/Top of head transition
    path.cubicTo(
      center.dx + 12.1 * scale, center.dy + 26.7 * scale,
      center.dx + 10.5 * scale, center.dy + 23.8 * scale,
      center.dx + 8.7 * scale, center.dy + 22.3 * scale
    );
    
    // Right side of face complex curve
    path.cubicTo(
       center.dx + 20 * scale, center.dy + 21.1 * scale,
       center.dx + 31.9 * scale, center.dy + 17.1 * scale,
       center.dx + 31.9 * scale, center.dy - 1.2 * scale
    );
    path.cubicTo(
       center.dx + 31.9 * scale, center.dy - 6.4 * scale,
       center.dx + 30 * scale, center.dy - 10.7 * scale,
       center.dx + 26.9 * scale, center.dy - 14.1 * scale
    );
    
    // Ear spike right
    path.cubicTo(
       center.dx + 27.4 * scale, center.dy - 15.3 * scale,
       center.dx + 29.1 * scale, center.dy - 20.2 * scale,
       center.dx + 26.4 * scale, center.dy - 26.8 * scale
    );
    
    // Head top dip
    path.cubicTo(
       center.dx + 22.4 * scale, center.dy - 28.1 * scale,
       center.dx + 13.2 * scale, center.dy - 21.8 * scale,
       center.dx, center.dy - 21.8 * scale
    );
    
    // Symmetry to left side
    path.cubicTo(
       center.dx - 13.2 * scale, center.dy - 21.8 * scale,
       center.dx - 22.4 * scale, center.dy - 28.1 * scale,
       center.dx - 26.4 * scale, center.dy - 26.8 * scale
    );
    
    // Ear spike left
    path.cubicTo(
       center.dx - 29.1 * scale, center.dy - 20.2 * scale,
       center.dx - 27.4 * scale, center.dy - 15.3 * scale,
       center.dx - 26.9 * scale, center.dy - 14.1 * scale
    );
    
    path.cubicTo(
       center.dx - 30 * scale, center.dy - 6.4 * scale,
       center.dx - 31.9 * scale, center.dy - 1.2 * scale,
       center.dx - 31.9 * scale, center.dy - 1.2 * scale
    );
    
    // Left side of face complex curve
    path.cubicTo(
       center.dx - 31.9 * scale, center.dy + 17.1 * scale,
       center.dx - 20 * scale, center.dy + 21.1 * scale,
       center.dx - 8.7 * scale, center.dy + 22.3 * scale
    );
    
    // Bottom left transition
    path.cubicTo(
       center.dx - 10.5 * scale, center.dy + 23.8 * scale,
       center.dx - 12.1 * scale, center.dy + 26.7 * scale,
       center.dx - 12.1 * scale, center.dy + 31.3 * scale
    );
    
    path.lineTo(center.dx - 12.1 * scale, center.dy + 43.1 * scale);
    path.cubicTo(
       center.dx - 12.1 * scale, center.dy + 45.1 * scale,
       center.dx - 12.8 * scale, center.dy + 46.2 * scale,
       center.dx - 15.4 * scale, center.dy + 45.4 * scale
    );
    
    // Finishing the circle
    path.cubicTo(
       center.dx - 34.3 * scale, center.dy + 39.2 * scale,
       center.dx - 48 * scale, center.dy + 21.2 * scale,
       center.dx - 48 * scale, center.dy
    );
    path.cubicTo(
       center.dx - 48 * scale, center.dy - 26.5 * scale,
       center.dx - 26.5 * scale, center.dy - 48 * scale,
       center.dx, center.dy - 48 * scale
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(GitHubLogoPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.color != color;
  }
}

class AnimatedGitHubLogo extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedGitHubLogo({
    super.key,
    this.size = 64,
    this.color = const Color(0xFF00FF41),
  });

  @override
  State<AnimatedGitHubLogo> createState() => _AnimatedGitHubLogoState();
}

class _AnimatedGitHubLogoState extends State<AnimatedGitHubLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: GitHubLogoPainter(
            glowIntensity: _glowAnimation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}
