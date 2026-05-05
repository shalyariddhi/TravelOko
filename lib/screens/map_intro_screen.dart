import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/custom_trip_bottom_sheet.dart';

class MapIntroScreen extends StatefulWidget {
  const MapIntroScreen({super.key});

  @override
  State<MapIntroScreen> createState() => _MapIntroScreenState();
}

class _MapIntroScreenState extends State<MapIntroScreen> {
  @override
  void initState() {
    super.initState();
    // After 2.5 seconds, pop this intro and show the bottom sheet on the previous screen
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const CustomTripBottomSheet(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Dark elegant background
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Map Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.network(
                'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&q=80', // Working Map Image
                fit: BoxFit.contain,
              ).animate()
                .scaleXY(begin: 1.2, end: 1.0, duration: 2500.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 800.ms),
            ),
          ),
          
          // Glowing overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scaleXY(begin: 0.9, end: 1.1, duration: 1200.ms),

          // Text overlay
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.travel_explore,
                size: 80,
                color: Colors.amber,
              ).animate()
               .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
               .fadeIn(),
              const SizedBox(height: 20),
              Text(
                'Mapping your journey...',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ).animate()
               .fadeIn(delay: 300.ms)
               .shimmer(duration: 1500.ms, color: Colors.amber),
            ],
          ),
        ],
      ),
    );
  }
}
