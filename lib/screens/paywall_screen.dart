import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaywallScreen extends StatefulWidget {
  final bool isDismissible;
  const PaywallScreen({super.key, this.isDismissible = true});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  Future<void> _purchasePro() async {
    setState(() => _isLoading = true);
    
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = _firebaseService.currentUser;
      if (user != null) {
        // Here we simulate the purchase by directly updating the isPro field.
        // In a real app, this would be handled by RevenueCat/Stripe webhooks.
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isPro': true});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome to GO-Trivo Pro! 👑', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true indicating successful purchase
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1C),
      body: Stack(
        children: [
          // Background Gradient & Image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1C), Color(0xFF000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: Image.network(
                'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Close button
                if (widget.isDismissible)
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: widget.isDismissible ? 80 : 120),
                        
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'GO-TRIVO PRO',
                            style: GoogleFonts.outfit(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          'Unlock Your\nUltimate Journey',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 40),
                        
                        // Features List
                        _buildFeatureItem(Icons.auto_awesome, 'Unlimited AI Trip Plans', 'Generate endless personalized itineraries'),
                        const SizedBox(height: 20),
                        _buildFeatureItem(Icons.map, 'Offline Maps & Guides', 'Access your plans anywhere, no internet needed'),
                        const SizedBox(height: 20),
                        _buildFeatureItem(Icons.diamond, 'Hidden Gem Recommendations', 'Exclusive access to highly-rated local spots'),
                        const SizedBox(height: 20),
                        _buildFeatureItem(Icons.block, 'Ad-Free Experience', 'Zero interruptions while you plan'),
                        
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
                
                // Purchase Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1C),
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '₹499 / month • Cancel anytime',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _purchasePro,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: Colors.amber.withValues(alpha: 0.5),
                          ),
                          child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                              : Text('Subscribe Now', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(end: 1.02, duration: 1000.ms),
                    ],
                  ),
                ).animate().slideY(begin: 1.0, duration: 500.ms, curve: Curves.easeOutQuart),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.amber, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2, end: 0);
  }
}
