import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'identification_screen.dart';
import 'main_shell.dart';
import 'terms_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _auth = FirebaseService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isSeeding = false;
  bool _isLogin = true;
  bool _obscurePassword = true;

  // Background slideshow
  final List<String> _bgImages = [
    'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?ixlib=rb-4.0.3&auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1548013146-72479768bada?ixlib=rb-4.0.3&auto=format&fit=crop&w=1400&q=80',
  ];
  final List<String> _captions = [
    'Taj Mahal, Agra',
    'Goa Beaches',
    'Swiss Alps',
    'Hawa Mahal, Jaipur',
  ];
  int _currentBgIndex = 0;
  Timer? _bgTimer;

  @override
  void initState() {
    super.initState();
    _bgTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _bgImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Future<void> _checkIdentityAndNavigate() async {
    if (!mounted) return;
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Check if identity is verified
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    if (doc.exists) {
      final data = doc.data()!;
      final isVerified = data['isIdentityVerified'] ?? false;
      if (isVerified) {
        final hasAcceptedTerms = data['hasAcceptedTerms'] ?? false;
        if (hasAcceptedTerms) {
          _navigateToHome();
        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const TermsScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      } else {
        // Route to identification page
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const IdentificationScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } else {
      _navigateToHome(); // Fallback if no user doc yet
    }
  }

  Future<void> _submitEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields.',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _auth.signInWithEmail(email, password);
      } else {
        await _auth.signUpWithEmail(email, password);
      }
      if (!mounted) return;
      await _checkIdentityAndNavigate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        await _checkIdentityAndNavigate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in cancelled.', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Error: ${e.toString()}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // â”€â”€ 1. Animated background â”€â”€
          AnimatedSwitcher(
            duration: const Duration(seconds: 2),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Container(
              key: ValueKey<int>(_currentBgIndex),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_bgImages[_currentBgIndex]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // â”€â”€ 2. Dark gradient â”€â”€
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0xBB000000),
                  Color(0xF5000000),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // â”€â”€ 3. Content â”€â”€
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Dot indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: List.generate(
                            _bgImages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              margin: const EdgeInsets.only(left: 5),
                              width: _currentBgIndex == i ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentBgIndex == i
                                    ? Colors.amber
                                    : Colors.white38,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const Spacer(),

                        // Location pill
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                _captions[_currentBgIndex],
                                key: ValueKey(_currentBgIndex),
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 10),

                        // Brand name
                        Text(
                          'Go-Trivo',
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.2),

                        Text(
                          'Find your tribe. Explore together.',
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 14),
                        ).animate().fadeIn(duration: 700.ms, delay: 100.ms),

                        const SizedBox(height: 28),

                        // â”€â”€ Login / Signup toggle tabs â”€â”€
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _buildTab('Log In', isSelected: _isLogin,
                                  onTap: () =>
                                      setState(() => _isLogin = true)),
                              _buildTab('Sign Up', isSelected: !_isLogin,
                                  onTap: () =>
                                      setState(() => _isLogin = false)),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

                        const SizedBox(height: 20),

                        // â”€â”€ Email field â”€â”€
                        _buildInputField(
                          controller: _emailController,
                          hint: 'Email address',
                          icon: Icons.email_outlined,
                        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                        const SizedBox(height: 14),

                        // â”€â”€ Password field â”€â”€
                        _buildInputField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ).animate().fadeIn(duration: 500.ms, delay: 380.ms),

                        const SizedBox(height: 22),

                        // â”€â”€ Submit button â”€â”€
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _submitEmailPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.black54,
                                        strokeWidth: 2.5),
                                  )
                                : Text(
                                    _isLogin ? 'Log In' : 'Create Account',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 450.ms),

                        const SizedBox(height: 20),

                        // â”€â”€ OR divider â”€â”€
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(
                                    color: Colors.white24, thickness: 1)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white38, fontSize: 12)),
                            ),
                            const Expanded(
                                child: Divider(
                                    color: Colors.white24, thickness: 1)),
                          ],
                        ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

                        const SizedBox(height: 16),

                        // â”€â”€ Google button â”€â”€
                        GestureDetector(
                          onTap: _isGoogleLoading ? null : _signInWithGoogle,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: _isGoogleLoading
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _isGoogleLoading
                                ? const Center(
                                    child: SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.amber,
                                          strokeWidth: 2.5),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CustomPaint(
                                            painter: _GoogleLogoPainter()),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF1F1F1F),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 550.ms),

                        const SizedBox(height: 20),

                        // Terms
                        Center(
                          child: Text(
                            'By continuing, you agree to our Terms & Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                color: Colors.white30, fontSize: 11),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 650.ms),

                        const SizedBox(height: 14),

                        // â”€â”€ Dev Seed button â”€â”€
                        Center(
                          child: GestureDetector(
                            onTap: _isSeeding
                                ? null
                                : () async {
                                    setState(() => _isSeeding = true);
                                    await FirebaseService().seedDatabase();
                                    if (!context.mounted) return;
                                    setState(() => _isSeeding = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('âœ… Database seeded!',
                                            style: GoogleFonts.poppins()),
                                        backgroundColor: Colors.green[700],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSeeding)
                                  const SizedBox(
                                    height: 12,
                                    width: 12,
                                    child: CircularProgressIndicator(
                                        color: Colors.white30,
                                        strokeWidth: 2),
                                  )
                                else
                                  const Icon(Icons.cloud_upload_outlined,
                                      color: Colors.white30, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  _isSeeding
                                      ? 'Seeding...'
                                      : 'ðŸ›  Seed Database (Dev)',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white30, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 750.ms),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label,
      {required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isSelected ? Colors.black87 : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        cursorColor: Colors.amber,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// Multicolour Google G logo via CustomPainter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.28
      ..strokeCap = StrokeCap.butt;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - size.width * 0.14;

    p.color = const Color(0xFF4285F4); // Blue
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -0.3, 2.6, false, p);

    p.color = const Color(0xFFEA4335); // Red
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 3.5, 1.5, false, p);

    p.color = const Color(0xFFFBBC05); // Yellow
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 2.3, 1.3, false, p);

    p.color = const Color(0xFF34A853); // Green
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 1.3, 1.1, false, p);

    // White crossbar
    p
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(c.dx - size.width * 0.02, c.dy - size.height * 0.15,
          r + size.width * 0.16, size.height * 0.3),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

