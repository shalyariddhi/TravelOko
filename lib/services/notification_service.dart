import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Singleton notification service.
/// Responsibilities:
///   1. Request FCM permission & save device tokens (multi-device safe).
///   2. Track active hours for AI send-time optimization.
///   3. Track engagement score for priority-based delivery.
///   4. Show a visible in-app banner for foreground FCM messages.
///   5. Refresh tokens automatically on token rotation.
///   6. Clean up token on sign-out.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // â”€â”€ Local notifications (foreground banners) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'Go-Trivo_high_importance',
    'Go-Trivo Notifications',
    description: 'New trips, posts, and follower alerts',
    importance: Importance.high,
    playSound: true,
  );

  // â”€â”€ Public API â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Call once from [main.dart] before runApp().
  Future<void> initialize() async {
    // 1. Request OS permission
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return; // User denied â€” nothing to set up
    }

    // 2. Save device token & listen for rotations
    await saveDeviceToken();
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // 3. Set up flutter_local_notifications for foreground banners
    await _initLocalNotifications();

    // 4. Show a banner for messages received while app is in foreground
    FirebaseMessaging.onMessage.listen(_showForegroundBanner);

    // 5. Track user activity for smart timing + engagement
    await updateLastActiveAt();
    await trackAppOpen();
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // ðŸ§  SMART TIMING: Track active hours for AI send-time optimization
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Records the current hour as an active period.
  /// Call on: app startup, resume from background.
  /// Builds a histogram: activity.activeHours.{"9": 12, "21": 20}
  Future<void> trackAppOpen() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final hour = DateTime.now().hour.toString();
      await _firestore.collection('users').doc(user.uid).set({
        'activity': {
          'activeHours': {
            hour: FieldValue.increment(1),
          },
          'lastOpenedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      debugPrint('Tracked app open at hour: $hour');
    } catch (e) {
      debugPrint('trackAppOpen error: $e');
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // ðŸ”¥ ENGAGEMENT TRACKING: Score user actions for priority filtering
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Increment the engagement score based on user action.
  /// Weights:
  ///   - notification opened: +5
  ///   - like:                +3
  ///   - comment:             +5
  ///   - share:               +4
  ///   - notification ignored: -2 (handled server-side)
  Future<void> incrementEngagement(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'engagementScore': FieldValue.increment(amount),
      });
      debugPrint('Engagement score updated by $amount');
    } catch (e) {
      debugPrint('incrementEngagement error: $e');
    }
  }

  /// Convenience methods for common engagement actions
  Future<void> trackLike() => incrementEngagement(3);
  Future<void> trackComment() => incrementEngagement(5);
  Future<void> trackShare() => incrementEngagement(4);
  Future<void> trackNotificationOpened() => incrementEngagement(5);

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // ðŸ“Œ TOPIC PREFERENCES: Save what the user cares about
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Save user's notification topic preferences.
  /// These are matched against trip tags on the backend before sending.
  Future<void> updateNotificationTopics(List<String> topics) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'notificationTopics': topics,
      }, SetOptions(merge: true));
      debugPrint('Notification topics updated: $topics');
    } catch (e) {
      debugPrint('updateNotificationTopics error: $e');
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // ðŸ”§ CORE TOKEN & ACTIVITY MANAGEMENT
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Call on every meaningful app-open / user action to keep lastActiveAt fresh.
  Future<void> updateLastActiveAt() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'lastActiveAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('updateLastActiveAt error: $e');
    }
  }

  /// Saves the current FCM token to Firestore under users/{uid}/tokens/{token}.
  Future<void> saveDeviceToken() async {
    final token = await _fcm.getToken();
    if (token != null) await _saveTokenToFirestore(token);
  }

  /// Remove this device's token on sign-out so stale tokens don't accumulate.
  Future<void> removeDeviceToken() async {
    final token = await _fcm.getToken();
    final user = _auth.currentUser;
    if (token != null && user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc(token)
          .delete();
      await _fcm.deleteToken();
    }
  }

  // â”€â”€ Private helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc(token)
          .set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      });
      debugPrint('FCM token saved: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('_saveTokenToFirestore error: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  /// Shows a local notification banner when a push arrives in the foreground.
  Future<void> _showForegroundBanner(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('Foreground FCM: ${notification.title}');

    // Track that user saw a notification (engagement signal)
    await incrementEngagement(2);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFED8F03),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}

