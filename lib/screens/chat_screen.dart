import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';


class ChatScreen extends StatefulWidget {
  final AppUser targetUser;
  const ChatScreen({super.key, required this.targetUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final currentUserId = _firebaseService.currentUser?.uid;
    if (currentUserId == null) return;



    // Mock send message - in reality, save to Firebase
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.targetUser.displayName, style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text('Chat messages will appear here.', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
