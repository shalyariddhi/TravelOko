import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import 'main_shell.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);
    await _firebaseService.acceptTerms();
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Safety & Guidelines', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(Icons.security, size: 80, color: Colors.amber[700])
                  .animate().scale(duration: 500.ms).then().shake(),
              ),
              const SizedBox(height: 32),
              Text(
                'Before you explore...',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 200.ms).slideX(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Go-Trivo is a platform to connect travelers. We are NOT responsible for what happens during your trips. Please exercise extreme caution, verify who you are traveling with, and do not trust anyone blindly. Safety is your own responsibility.',
                  style: GoogleFonts.poppins(fontSize: 16, height: 1.5, color: Colors.black87),
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _acceptTerms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        'I Understand & Agree',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

