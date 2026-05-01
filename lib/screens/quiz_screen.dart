import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../models/app_user.dart';

class TravelPersonalityQuizScreen extends StatefulWidget {
  const TravelPersonalityQuizScreen({super.key});

  @override
  State<TravelPersonalityQuizScreen> createState() => _TravelPersonalityQuizScreenState();
}

class _TravelPersonalityQuizScreenState extends State<TravelPersonalityQuizScreen> {
  int _currentQuestionIndex = 0;
  final List<String> _answers = [];
  final FirebaseService _firebaseService = FirebaseService();

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is your ideal vacation?',
      'options': [
        {'text': 'Lounging on a tropical beach', 'trait': 'The Relaxer'},
        {'text': 'Backpacking through mountains', 'trait': 'The Adventurer'},
        {'text': 'Exploring museums and ruins', 'trait': 'The Historian'},
        {'text': 'Partying until sunrise', 'trait': 'The Party Animal'},
      ]
    },
    {
      'question': 'How do you plan your trips?',
      'options': [
        {'text': 'Minute-by-minute itinerary', 'trait': 'The Planner'},
        {'text': 'Go with the flow completely', 'trait': 'The Free Spirit'},
        {'text': 'A loose list of must-dos', 'trait': 'The Balanced'},
        {'text': 'I let my friends decide', 'trait': 'The Follower'},
      ]
    },
    {
      'question': 'What is your travel budget style?',
      'options': [
        {'text': 'Luxury all the way', 'trait': 'The High Roller'},
        {'text': 'Comfort but reasonable', 'trait': 'The Practical'},
        {'text': 'Strictly budget backpacking', 'trait': 'The Scrapper'},
        {'text': 'I will work for accommodation', 'trait': 'The Nomad'},
      ]
    }
  ];

  void _answerQuestion(String trait) async {
    _answers.add(trait);
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Calculate Personality
      final personalityMap = <String, int>{};
      for (var t in _answers) {
        personalityMap[t] = (personalityMap[t] ?? 0) + 1;
      }
      final personality = personalityMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // Update Firebase
      final user = _firebaseService.currentUser;
      if (user != null) {
        final docRef = _firebaseService.getUserProfile(user.uid);
        docRef.first.then((appUser) {
          if (appUser != null) {
            final updatedUser = AppUser(
              uid: appUser.uid,
              displayName: appUser.displayName,
              email: appUser.email,
              photoUrl: appUser.photoUrl,
              bio: appUser.bio,
              tripsCount: appUser.tripsCount,
              followersCount: appUser.followersCount,
              badges: appUser.badges,
              verifiedScore: appUser.verifiedScore,
              gender: appUser.gender,
              dateOfBirth: appUser.dateOfBirth,
              locality: appUser.locality,
              isIdentityVerified: appUser.isIdentityVerified,
              isOnlyGirlsMode: appUser.isOnlyGirlsMode,
              following: appUser.following,
              isPrivate: appUser.isPrivate,
              statusEmoji: appUser.statusEmoji,
              hasAcceptedTerms: appUser.hasAcceptedTerms,
              reputationScore: appUser.reputationScore,
              totalReviews: appUser.totalReviews,
              responseTime: appUser.responseTime,
              pastTrips: appUser.pastTrips,
              wishlist: appUser.wishlist,
              travelPersonality: personality,
              isBanned: appUser.isBanned,
              reportedUsers: appUser.reportedUsers,
            );
            _firebaseService.updateUserProfile(updatedUser);
          }
        });
      }

      // Show Result Dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 60),
              const SizedBox(height: 20),
              Text('You are...', style: GoogleFonts.poppins(fontSize: 16)),
              Text(personality, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber[800])),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dismiss dialog
                  Navigator.of(context).pop(); // dismiss screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Awesome!'),
              )
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentQuestionIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Travel Personality Quiz', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: Colors.grey[200],
                color: Colors.amber,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 40),
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: GoogleFonts.poppins(color: Colors.grey[500], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                q['question'],
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ).animate(key: ValueKey(_currentQuestionIndex)).fadeIn().slideX(begin: 0.1),
              const SizedBox(height: 40),
              ...(q['options'] as List<Map<String, String>>).map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(opt['trait']!),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      backgroundColor: Colors.grey[50],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      opt['text']!,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ).animate(key: ValueKey('${_currentQuestionIndex}_${opt['text']}')).fadeIn(delay: 200.ms).slideY(begin: 0.2),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
