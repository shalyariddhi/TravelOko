import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Community Guidelines', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield, color: Colors.blue, size: 64),
            const SizedBox(height: 20),
            Text(
              'Our Commitment to Safety',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Go-Trivo is built on trust, respect, and mutual understanding. To ensure everyone has a safe and enjoyable experience, we strictly enforce the following rules.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildRule(
              icon: Icons.person_off,
              title: 'No Harassment or Bullying',
              description: 'We have a zero-tolerance policy for harassment, hate speech, threats, or any abusive behavior towards other travelers.',
            ),
            _buildRule(
              icon: Icons.verified_user,
              title: 'Authentic Profiles Only',
              description: 'Fake profiles, impersonation, and fraudulent activities will result in an immediate and permanent ban.',
            ),
            _buildRule(
              icon: Icons.report_problem,
              title: 'No Spam or Scams',
              description: 'Do not use the platform to solicit money, sell products, or spam users with promotional links.',
            ),
            _buildRule(
              icon: Icons.female,
              title: 'Respect Girliees Mode',
              description: 'Girliees Mode is strictly for female travelers. Men attempting to bypass this using false information will be permanently banned.',
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gavel, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Enforcement', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red[900])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Violating these rules will result in strikes, temporary suspensions, or permanent bans. If you are banned, you may appeal the decision via the Appeal System.',
                    style: GoogleFonts.poppins(color: Colors.red[800], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRule({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber[700], size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

