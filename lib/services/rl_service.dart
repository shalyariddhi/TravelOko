import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class RLService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Updates the user's embedding vector towards the interacted post's embedding.
  Future<void> updateUserEmbedding(List<double> postEmbedding) async {
    if (postEmbedding.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final snap = await userRef.get();
      
      if (!snap.exists) return;
      
      final current = (snap.data()?['embedding'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [];

      List<double> updated = [];

      // If user has no existing embedding, initialize with the post's embedding
      if (current.isEmpty || current.length != postEmbedding.length) {
        updated = List<double>.from(postEmbedding);
      } else {
        // Shift user embedding towards the post embedding
        for (int i = 0; i < current.length; i++) {
          updated.add((current[i] * 0.9) + (postEmbedding[i] * 0.1));
        }
      }

      await userRef.update({
        "embedding": updated,
      });
    } catch (e) {
      appLogger.e("Error updating user embedding: $e");
    }
  }

  /// Logs a user interaction, calculates the reward, and updates the user's dynamic feed weights.
  Future<void> logInteraction(String postId, String action, {String? sessionId}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Define reward scale
    double reward = 0;
    switch (action) {
      case 'like':
        reward = 2.0;
        break;
      case 'comment':
        reward = 3.0;
        break;
      case 'save':
        reward = 5.0;
        break;
      case 'skip':
        reward = -1.0;
        break;
      default:
        reward = 0.0;
    }

    if (reward == 0) return;

    try {
      // 1. Log interaction
      final String sid = sessionId ?? 'default_session';
      final logRef = _firestore.collection('feed_logs').doc(sid).collection('interactions').doc();
      
      await logRef.set({
        'userId': user.uid,
        'postId': postId,
        'action': action,
        'reward': reward,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Adjust dynamic weights
      final userRef = _firestore.collection('users').doc(user.uid);
      final snap = await userRef.get();
      
      if (!snap.exists) return;
      
      final currentWeights = (snap.data()?['feedWeights'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {
        'w1': 0.4, 'w2': 0.3, 'w3': 2.0, 'w4': 0.1
      };

      // Increase similarity weight (w1) when interacting positively
      // In a more complex setup, you'd track *why* they interacted (was it trending? was it a follower?)
      // Here we assume positive interaction means they like content matching their embedding.
      if (reward > 0) {
        currentWeights['w1'] = currentWeights['w1']! + (0.01 * reward);
      } else if (reward < 0) {
        // If they skip, reduce similarity weight slightly
        currentWeights['w1'] = currentWeights['w1']! + (0.01 * reward);
      }

      // Bound weights so they don't explode or drop below 0
      currentWeights['w1'] = currentWeights['w1']!.clamp(0.0, 5.0);

      await userRef.update({
        'feedWeights': currentWeights,
      });

    } catch (e) {
      appLogger.e("Error logging interaction: $e");
    }
  }
}
