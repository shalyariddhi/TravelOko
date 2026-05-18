import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'models/trip.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'screens/trip_detail_screen.dart';
import 'screens/social_feed_screen.dart';
import 'screens/collaborative_trip_screen.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // Group independent heavy initializations
  await Future.wait([
    dotenv.load(fileName: '.env'),
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) async {
      // Initialize Analytics so Remote Config ABT experiments work correctly
      FirebaseAnalytics.instance;

      // Crashlytics — catch all uncaught Flutter errors
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      debugPrint('Firebase initialized successfully');
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Initialize push notifications BEFORE runApp
      await NotificationService().initialize();

      // Initialize Remote Config (fetches live tuneable values)
      await RemoteConfigService().initialize();
    }).catchError((e) {
      debugPrint('Firebase initialization error: $e');
    }),
    Hive.initFlutter().then((_) => Hive.openBox('trips_cache')),
  ]);

  // Defer FMTC init to not block the first frame
  Future.microtask(() async {
    try {
      await FMTCObjectBoxBackend().initialise();
      await const FMTCStore('osmTiles').manage.create();
    } catch (e) {
      debugPrint('FMTC init: $e');
    }
  });

  // Always use light theme
  themeNotifier.value = ThemeMode.light;

  runApp(const GoTrivoApp());
}

class GoTrivoApp extends StatefulWidget {
  const GoTrivoApp({super.key});

  @override
  State<GoTrivoApp> createState() => _GoTrivoAppState();
}

class _GoTrivoAppState extends State<GoTrivoApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupPushNotifications();
    _setupDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever the app lifecycle changes.
  /// Refreshes lastActiveAt and tracks active hour for smart send-time.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService().updateLastActiveAt();
      NotificationService().trackAppOpen();
    }
  }

  Future<void> _setupPushNotifications() async {
    // Deep-link: app opened via a notification tap (background -> foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);

    // Deep-link: app launched cold from a notification tap
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _handleNotificationNavigation(initialMessage);
      });
    }
  }

  /// Deep links via app_links (for universal / custom-scheme links)
  void _setupDeepLinks() {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
    // Handle cold-start deep link
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    // Handle /trip/{tripId}
    if (pathSegments[0] == 'trip' && pathSegments.length > 1) {
      final tripId = pathSegments[1];
      try {
        final doc = await FirebaseFirestore.instance.collection('trips').doc(tripId).get();
        if (doc.exists) {
          final trip = Trip.fromMap(doc.data()!, doc.id);
          final isCollab = trip.isCollaborative;
          navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (_) => isCollab
                ? CollaborativeTripScreen(tripId: tripId, tripTitle: trip.title)
                : TripDetailScreen(trip: trip),
          ));
        }
      } catch (e) {
        debugPrint('Deep link trip error: $e');
      }
    }
  }
  void _handleNotificationNavigation(RemoteMessage message) async {
    // Track that user engaged with this notification (+5 engagement)
    await NotificationService().trackNotificationOpened();

    final tripId = message.data['tripId'];
    final postId = message.data['postId'];

    if (tripId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('trips')
            .doc(tripId)
            .get();
        if (doc.exists) {
          final trip = Trip.fromMap(doc.data()!, doc.id);
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => TripDetailScreen(trip: trip)),
          );
        }
      } catch (e) {
        debugPrint("Error fetching trip for notification: $e");
      }
    } else if (postId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const SocialFeedScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Go-Trivo',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F6FA),
            shadowColor: Colors.black,
            primaryColor: const Color(0xFFFF8C00),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF8C00),
              primary: const Color(0xFFFF8C00),
              secondary: const Color(0xFF7C3AED),
              surface: Colors.white,
            ),
            textTheme: GoogleFonts.outfitTextTheme(),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleTextStyle: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0A0A1A),
              ),
              iconTheme: const IconThemeData(color: Color(0xFF0A0A1A)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
              ),
              hintStyle: GoogleFonts.outfit(color: const Color(0xFFAAAAAA)),
            ),
            dividerTheme: const DividerThemeData(color: Color(0xFFEEEEEE)),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFFF8C00),
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0A1A),
            shadowColor: Colors.transparent,
            primaryColor: const Color(0xFFFF8C00),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF8C00),
              secondary: Color(0xFF7C3AED),
              surface: Color(0xFF141428),
              onSurface: Colors.white,
              onPrimary: Colors.white,
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
              bodyLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
              bodyMedium: GoogleFonts.outfit(color: const Color(0xFF9999BB)),
              bodySmall: GoogleFonts.outfit(color: const Color(0xFF666688)),
              titleLarge: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900),
              titleMedium: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF141428),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFF1E1E3A), width: 1),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleTextStyle: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF141428),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF1E1E3A)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF1E1E3A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
              ),
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF666688)),
            ),
            dividerTheme: const DividerThemeData(color: Color(0xFF1E1E3A)),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFFF8C00),
              foregroundColor: Colors.white,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}


