import 'package:cloud_functions/cloud_functions.dart';

class BoostService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Boosts a post for a given number of days.
  /// Throws an exception if the post does not meet the engagement threshold.
  Future<void> boostPost(String postId, {int score = 10, int durationDays = 3}) async {
    try {
      final callable = _functions.httpsCallable('boostPost');
      await callable.call({
        'postId': postId,
        'score': score,
        'durationDays': durationDays,
      });
    } catch (e) {
      throw Exception('Failed to boost post: $e');
    }
  }
}
