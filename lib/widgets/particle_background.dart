import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class Particle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
  });
}

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 50,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  Offset _mousePosition = Offset.zero;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..addListener(_updateParticles);

    _initializeParticles();
    _controller.repeat();
  }

  void _initializeParticles() {
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        Particle(
          position: Offset(
            _random.nextDouble() * 2000,
            _random.nextDouble() * 2000,
          ),
          velocity: Offset(
            (_random.nextDouble() - 0.5) * 0.5,
            (_random.nextDouble() - 0.5) * 0.5,
          ),
          size: _random.nextDouble() * 2 + 1,
          opacity: _random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        // Update position
        particle.position += particle.velocity;

        // Bounce off edges
        if (particle.position.dx < 0 || particle.position.dx > 2000) {
          particle.velocity = Offset(-particle.velocity.dx, particle.velocity.dy);
        }
        if (particle.position.dy < 0 || particle.position.dy > 2000) {
          particle.velocity = Offset(particle.velocity.dx, -particle.velocity.dy);
        }

        // Mouse interaction (repel)
        final distance = (particle.position - _mousePosition).distance;
        if (distance < 150) {
          final direction = (particle.position - _mousePosition) / distance;
          particle.position += direction * 2;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      child: Stack(
        children: [
          // Particle layer
          Positioned.fill(
            child: CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
              ),
            ),
          ),
          // Content
          widget.child,
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw particles
    for (var particle in particles) {
      paint.color = AppTheme.cyanAccent.withOpacity(particle.opacity);
      canvas.drawCircle(particle.position, particle.size, paint);
    }

    // Draw connections
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final distance = (particles[i].position - particles[j].position).distance;
        if (distance < 120) {
          linePaint.color = AppTheme.cyanAccent.withOpacity(
            (1 - distance / 120) * 0.15,
          );
          canvas.drawLine(
            particles[i].position,
            particles[j].position,
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
