import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: AppTheme.deepBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SvgPicture.asset(
                  'assets/icons/logo.svg',
                  height: 48,
                  width: 48,
                  colorFilter: const ColorFilter.mode(AppTheme.cyanAccent, BlendMode.srcIn),
                ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 24),

                Text(
                  'Sign in to SyncStack',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Main Login Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBlack,
                    border: Border.all(color: AppTheme.borderGlow.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGitHubField(
                        controller: _usernameController,
                        label: 'Username or email address',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Personal Access Token', style: TextStyle(fontSize: 14, color: Colors.white)),
                          Text('Forgot token?', style: TextStyle(fontSize: 12, color: AppTheme.infoBlue.withOpacity(0.8))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildGitHubField(
                        controller: _tokenController,
                        label: '',
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      border: Border.all(color: AppTheme.errorRed.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                    ),
                  ).animate().shake(),
                ],

                const SizedBox(height: 24),

                // Register Link Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderGlow.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('New to SyncStack? ', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                      Text('Create an account.', style: TextStyle(color: AppTheme.infoBlue, fontSize: 14)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                Text('Quantum Engine v2.0 • PRO Edition', style: TextStyle(color: AppTheme.textDimmed, fontSize: 11, letterSpacing: 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGitHubField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
          ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.elevatedSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppTheme.borderGlow.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppTheme.borderGlow.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.cyanAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cyanAccent.withOpacity(0.02)
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
