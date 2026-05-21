import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terms_screen.dart';

class IdentificationScreen extends StatefulWidget {
  const IdentificationScreen({super.key});

  @override
  State<IdentificationScreen> createState() => _IdentificationScreenState();
}

class _IdentificationScreenState extends State<IdentificationScreen> {
  final _nameController = TextEditingController();
  final _localityController = TextEditingController();
  
  String _selectedGender = 'female';
  String _selectedEmoji = '✈️';
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

  bool _isLoading = false;

  final List<int> _days = List.generate(31, (index) => index + 1);
  final List<int> _months = List.generate(12, (index) => index + 1);
  final List<int> _years = List.generate(100, (index) => DateTime.now().year - index);
  final List<String> _emojis = ['✈️', '🌴', '🏔️', '🏖️', '🏕️', '🎒', '📸', '🗺️', '🏄‍♂️', '🚗', '🛵', '🧭'];

  Future<void> _submitIdentity() async {
    if (_nameController.text.trim().isEmpty ||
        _localityController.text.trim().isEmpty ||
        _selectedDay == null ||
        _selectedMonth == null ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all compulsory fields.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dob = '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'displayName': _nameController.text.trim(),
          'dateOfBirth': dob,
          'locality': _localityController.text.trim(),
          'gender': _selectedGender,
          'statusEmoji': _selectedEmoji,
          'isIdentityVerified': true,
        });

        if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _localityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent going back
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.badge_outlined, size: 60, color: Colors.amber)
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  Text(
                    'Identity Verification',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Please provide your details below to continue.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 24),
                  
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'These details are compulsory and cannot be changed in the future. Please fill them out accurately.',
                            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 32),

                  // Full Name
                  _buildLabel('Full Name'),
                  _buildTextField(_nameController, 'Enter your legal name', Icons.person_outline)
                      .animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 20),

                  // Date of Birth
                  _buildLabel('Date of Birth'),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown('Day', _days, _selectedDay, (val) => setState(() => _selectedDay = val))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDropdown('Month', _months, _selectedMonth, (val) => setState(() => _selectedMonth = val))),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildDropdown('Year', _years, _selectedYear, (val) => setState(() => _selectedYear = val))),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 20),

                  // Locality
                  _buildLabel('Locality (City/State)'),
                  _buildTextField(_localityController, 'e.g., Mumbai, Maharashtra', Icons.location_city_outlined)
                      .animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 20),

                  // Gender
                  _buildLabel('Gender'),
                  Row(
                    children: [
                      _buildGenderTab('Female', 'female'),
                      const SizedBox(width: 16),
                      _buildGenderTab('Male', 'male'),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 20),

                  // Emoji Palette
                  _buildLabel('Travel Status Emoji'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _emojis.map((emoji) {
                      final isSelected = _selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedEmoji = emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.amber.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.amber : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 850.ms),

                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitIdentity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
                            )
                          : Text(
                              'Complete Profile',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        cursorColor: Colors.amber,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<int> items, int? value, ValueChanged<int?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          hint: Text(hint, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
          dropdownColor: const Color(0xFF1E1E1E),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          isExpanded: true,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGenderTab(String label, String value) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.amber : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value == 'female' ? Icons.female : Icons.male,
                color: isSelected ? Colors.amber : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected ? Colors.amber : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
