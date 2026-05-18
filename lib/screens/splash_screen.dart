import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'identification_screen.dart';
import 'terms_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _navigateToLogin();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    Widget nextScreen = const LoginScreen();

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5));
        if (doc.exists && doc.data()!['isIdentityVerified'] == true) {
          if (doc.data()!['hasAcceptedTerms'] == true) {
            nextScreen = const MainShell();
          } else {
            nextScreen = const TermsScreen();
          }
        } else {
          nextScreen = const IdentificationScreen();
        }
      } catch (_) {
        nextScreen = const MainShell();
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => nextScreen,
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Warm light gradient background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFBF5),
                  Color(0xFFF8F4EF),
                  Color(0xFFFFF3E4),
                ],
              ),
            ),
          ),

          // ── Amber glow blob top-left ──
          Positioned(
            top: -100,
            left: -80,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF8C00).withValues(
                          alpha: 0.14 + 0.06 * _pulseController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Purple glow blob bottom-right ──
          Positioned(
            bottom: -120,
            right: -90,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C3AED).withValues(
                          alpha: 0.08 + 0.04 * _pulseController.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Floating travel icons ──
          ..._buildFloatingIcons(),

          // ── Center content ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing logo orb
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) => Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C00).withValues(
                              alpha: 0.22 + 0.12 * _pulseController.value),
                          blurRadius: 50 + 10 * _pulseController.value,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    size: 56,
                    color: Color(0xFFFF8C00),
                  ),
                )
                    .animate()
                    .scale(
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.4, 0.4),
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 32),

                // GO-Trivo gradient wordmark
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
                  ).createShader(bounds),
                  child: Text(
                    'GO-Trivo',
                    style: GoogleFonts.outfit(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 300.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 700.ms,
                      delay: 300.ms,
                      curve: Curves.easeOutQuart,
                    ),

                const SizedBox(height: 8),

                Text(
                  'DISCOVER  ·  CONNECT  ·  EXPLORE',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB0AEA8),
                    letterSpacing: 3.5,
                  ),
                ).animate().fadeIn(duration: 800.ms, delay: 600.ms),

                const SizedBox(height: 56),

                // Loading dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    )
                        .animate(delay: Duration(milliseconds: 800 + i * 150))
                        .fadeIn(duration: 400.ms)
                        .then()
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                          begin: 1.0,
                          end: 1.6,
                          duration: 600.ms,
                          delay: Duration(milliseconds: i * 200),
                        );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingIcons() {
    final icons = [
      (Icons.luggage_rounded, 0.12, 0.25, 0.0),
      (Icons.beach_access_rounded, 0.82, 0.18, 0.5),
      (Icons.photo_camera_rounded, 0.08, 0.68, 1.0),
      (Icons.map_rounded, 0.88, 0.72, 1.5),
      (Icons.restaurant_rounded, 0.75, 0.45, 0.8),
      (Icons.hiking_rounded, 0.20, 0.50, 0.3),
    ];

    return icons.map((data) {
      final (icon, xFrac, yFrac, delayS) = data;
      return Positioned(
        left: MediaQuery.of(context).size.width * xFrac,
        top: MediaQuery.of(context).size.height * yFrac,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -6 + 12 * _floatController.value),
            child: child,
          ),
          child: Icon(
            icon,
            size: 28,
            color: const Color(0xFFFF8C00).withValues(alpha: 0.12),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 1.seconds, delay: Duration(milliseconds: (delayS * 1000).toInt()));
    }).toList();
  }
}
