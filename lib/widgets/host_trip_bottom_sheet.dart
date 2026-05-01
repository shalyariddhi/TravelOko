import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HostTripBottomSheet extends StatefulWidget {
  const HostTripBottomSheet({super.key});

  @override
  State<HostTripBottomSheet> createState() => _HostTripBottomSheetState();
}

class _HostTripBottomSheetState extends State<HostTripBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _seatsController = TextEditingController(text: '4');
  
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _startDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.amber,
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a start date')));
      return;
    }

    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) return;

    final trip = Trip(
      id: '', // Firestore will generate
      title: _titleController.text.trim(),
      destination: _destinationController.text.trim(),
      imageUrl: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', // Default generic travel image
      organizerId: user.uid,
      organizerName: user.displayName ?? 'Traveler',
      organizerAvatar: user.photoURL ?? 'https://api.dicebear.com/9.x/avataaars/png?seed=${user.uid}',
      budget: int.parse(_budgetController.text.trim()),
      durationDays: 5, // Default duration
      startDate: _startDate!,
      totalSeats: int.parse(_seatsController.text.trim()),
      seatsLeft: int.parse(_seatsController.text.trim()),
      description: _descriptionController.text.trim(),
      tags: ['Hosted', 'Community'],
    );

    final newId = await _firebaseService.createTrip(trip);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (newId != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip Hosted Successfully! 🎉', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to host trip', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Host Your Trip', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Create a trip and let other amazing people join you!', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                decoration: _buildInputDeco('Trip Title', 'e.g. Weekend getaway to Goa'),
              ),
              const SizedBox(height: 16),

              // Destination
              TextFormField(
                controller: _destinationController,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.toLowerCase().contains('india')) return 'Only India locations allowed';
                  return null;
                },
                decoration: _buildInputDeco('Destination (India Only)', 'e.g. Goa, India', icon: Icons.location_on_outlined),
              ),
              const SizedBox(height: 16),

              // Date & Seats
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.amber, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              _startDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_startDate!),
                              style: GoogleFonts.poppins(color: _startDate == null ? Colors.grey[400] : Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _seatsController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      decoration: _buildInputDeco('Seats', 'Max pax'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                decoration: _buildInputDeco('Budget per person', 'e.g. 15000').copyWith(prefixText: '₹ '),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _buildInputDeco('Description', 'Tell people what the trip is about...'),
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                      : Text('Publish Trip', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDeco(String label, String hint, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
      prefixIcon: icon != null ? Icon(icon, color: Colors.amber) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.amber, width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
