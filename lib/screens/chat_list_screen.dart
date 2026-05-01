import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = _firebaseService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text('Chats', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: currentUserId == null
          ? const Center(child: Text('Log in to view chats'))
          : StreamBuilder<AppUser?>(
              stream: _firebaseService.getUserProfile(currentUserId),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }

                final currentUser = userSnap.data;
                if (currentUser == null || currentUser.following.isEmpty) {
                  return _buildEmptyState('Follow some travelers to start chatting!');
                }

                return StreamBuilder<List<AppUser>>(
                  stream: _firebaseService.getUsersStream(),
                  builder: (context, usersSnap) {
                    if (usersSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }

                    final allUsers = usersSnap.data ?? [];
                    // Mutual follow logic
                    final mutualFollowers = allUsers.where((u) => 
                      currentUser.following.contains(u.uid) && u.following.contains(currentUserId)
                    ).toList();

                    if (mutualFollowers.isEmpty) {
                      return _buildEmptyState('No mutual followers yet.\nPeople you follow must follow you back to chat.');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: mutualFollowers.length,
                      itemBuilder: (context, index) {
                        final user = mutualFollowers[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUser: user)));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: NetworkImage(
                                    (user.photoUrl.isNotEmpty && !user.photoUrl.contains('pravatar'))
                                        ? user.photoUrl
                                        : 'https://api.dicebear.com/9.x/avataaars/png?seed=${user.uid}'
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.displayName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text('Tap to view messages', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey[300]),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideX(begin: 0.05);
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, size: 64, color: Colors.amber[600]),
          ),
          const SizedBox(height: 20),
          Text('Your Inbox is Empty', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).scaleXY(begin: 0.95),
    );
  }
}
