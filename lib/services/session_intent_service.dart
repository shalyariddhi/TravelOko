import 'dart:async';

class SessionIntentService {
  // Singleton pattern
  static final SessionIntentService _instance = SessionIntentService._internal();
  factory SessionIntentService() => _instance;
  SessionIntentService._internal();

  final Map<String, int> _sessionInterests = {};
  Timer? _inactivityTimer;

  // Expire session after 45 minutes of inactivity
  static const Duration _expirationDuration = Duration(minutes: 45);

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_expirationDuration, _clearSession);
  }

  void _clearSession() {
    _sessionInterests.clear();
  }

  /// Tracks a tag viewed or clicked during the current session
  void trackTag(String tag) {
    if (tag.isEmpty) return;
    _resetTimer();
    final lowerTag = tag.toLowerCase();
    _sessionInterests[lowerTag] = (_sessionInterests[lowerTag] ?? 0) + 1;
  }

  /// Tracks multiple tags from a post or trip
  void trackTags(List<String> tags) {
    for (var t in tags) {
      trackTag(t);
    }
  }

  /// Calculates a temporary score boost based on the current session's short-term intent
  double getSessionBoost(List<String> tags) {
    if (_sessionInterests.isEmpty || tags.isEmpty) return 0.0;
    
    double boost = 0;
    for (var t in tags) {
      boost += _sessionInterests[t.toLowerCase()] ?? 0;
    }
    
    // Cap the max session boost to prevent it from completely overriding long-term preference
    if (boost > 5.0) return 5.0;
    return boost;
  }

  // Get current intent for debugging/analytics
  Map<String, int> getCurrentIntent() => Map.unmodifiable(_sessionInterests);
}
