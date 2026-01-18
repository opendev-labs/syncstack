import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/github_logo_painter.dart';
import '../widgets/particle_background.dart';
import '../widgets/premium_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    if (username.isEmpty || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and token';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.login(username, token);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] != true) {
          setState(() => _errorMessage = result['message'] ?? 'Authentication failed. Check your credentials.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ParticleBackground(
        particleCount: 40,
        child: Container(
          color: AppTheme.deepBlack,
          child: Stack(
            children: [
              // Grid lines
              CustomPaint(
                painter: GridPainter(),
                child: Container(),
              ),

              // Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        const AnimatedGitHubLogo(size: 80)
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'GITHUB SYNC',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            letterSpacing: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 800.ms)
                            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),

                        const SizedBox(height: 12),

                        Text(
                          'QUANTUM ENGINE • v1.0.0',
                          style: GoogleFonts.ibmPlexMono(
                            color: AppTheme.neonGreen,
                            letterSpacing: 4,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 800.ms),

                        const SizedBox(height: 32),

                        // Login Card - Matt Style
                        Container(
                          decoration: AppTheme.mattBox(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 40,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'SECURE AUTHENTICATION',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Username Field
                                _buildTextField(
                                  controller: _usernameController,
                                  label: 'OPERATOR ID',
                                  icon: Icons.person_outline,
                                ),
                            
                                const SizedBox(height: 24),
                            
                                // Token Field
                                _buildTextField(
                                  controller: _tokenController,
                                  label: 'ACCESS TOKEN',
                                  icon: Icons.security_outlined,
                                  obscureText: true,
                                ),

                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed.withOpacity(0.1),
                                      border: Border.all(
                                        color: AppTheme.errorRed,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: AppTheme.errorRed,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: AppTheme.errorRed,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      .animate()
                                      .shake(duration: 400.ms)
                                      .fadeIn(),
                                ],

                                const SizedBox(height: 32),

                                // Login Button
                                PremiumButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  isLoading: _isLoading,
                                  child: const Text(
                                    'ESTABLISH UPLINK',
                                    style: TextStyle(
                                      letterSpacing: 3,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 600.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.neonGreen.withOpacity(0.5),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.security,
                                    size: 14,
                                    color: AppTheme.neonGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SECURE CONNECTION',
                                    style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1,
                                      color: AppTheme.neonGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 800.ms, duration: 600.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            color: AppTheme.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.ibmPlexMono(
            color: Colors.white,
            fontSize: 15,
            letterSpacing: 1,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppTheme.neonGreen),
            filled: true,
            fillColor: AppTheme.elevatedSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.neonGreen.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.neonGreen.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.neonGreen,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          onSubmitted: (_) => _handleLogin(),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.neonGreen.withOpacity(0.02)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
