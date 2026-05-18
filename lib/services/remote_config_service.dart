import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Call once during app startup to initialize remote config.
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        // In development, fetch frequently. In production, every 12 hours is fine.
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 5)
            : const Duration(hours: 12),
      ));

      // ── DEFAULT VALUES ──────────────────────────────────────────────────────
      // These are used if the device is offline or the fetch fails.
      // Change the value in Firebase Console -> Remote Config to override live.
      await _remoteConfig.setDefaults({
        'free_trip_limit': 3,
        'affiliate_vendor_name': 'Booking.com',
        'show_export_feature': true,
      });

      await _remoteConfig.fetchAndActivate();
      debugPrint('[RemoteConfig] Initialized. free_trip_limit = $freeTripLimit');
    } catch (e) {
      // Non-fatal: defaults will be used.
      debugPrint('[RemoteConfig] Init failed (using defaults): $e');
    }
  }

  /// The maximum number of AI trips a free user can generate.
  /// Override this via Firebase Console: Remote Config → free_trip_limit
  int get freeTripLimit => _remoteConfig.getInt('free_trip_limit');

  /// The affiliate vendor name displayed on booking buttons.
  String get affiliateVendorName =>
      _remoteConfig.getString('affiliate_vendor_name');

  /// Whether the "Export to Story" feature is enabled.
  bool get showExportFeature => _remoteConfig.getBool('show_export_feature');
}
