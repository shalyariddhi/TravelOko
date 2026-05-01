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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 3000), () {});
    if (!mounted) return;
    
    // Check if user is already logged in
    final user = FirebaseAuth.instance.currentUser;
    Widget nextScreen = const LoginScreen();
    
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 5));
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
        // If it times out or fails (e.g. firewall blocking), just let them into the app to explore mock data
        nextScreen = const MainShell();
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFB75E), // Vibrant orange
              Color(0xFFED8F03), // Deep amber
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  size: 64,
                  color: Color(0xFFED8F03),
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .then()
                  .shimmer(duration: 1200.ms, color: Colors.amber[200]),
              
              const SizedBox(height: 24),
              
              // App Name
              Text(
                'TravelOco',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4.0,
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOutQuad),
              
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Discover your next adventure',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 600.ms)
                  .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOutQuad),
            ],
          ),
        ),
      ),
    );
  }
}
