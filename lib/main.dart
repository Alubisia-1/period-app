import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:period_tracker_app/services/database_service.dart';
import 'package:period_tracker_app/services/shared_preferences.dart';
import 'package:period_tracker_app/screens/home_screen.dart';
import 'package:period_tracker_app/screens/period_tracking_screen.dart';
import 'package:period_tracker_app/screens/TrackSymptomMoodScreen.dart';
import 'package:period_tracker_app/services/notification_service.dart';
import 'package:period_tracker_app/providers/user_provider.dart';
import 'package:period_tracker_app/services/logging_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Minimal blocking initialization
  setupLogging();
  tz.initializeTimeZones();

  // Non-blocking initializations (fire and forget)
  MobileAds.instance.initialize(); // Runs in background
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  flutterLocalNotificationsPlugin.initialize(initializationSettings); // Runs in background

  // Start app immediately, initialize services lazily
  runApp(
    MultiProvider(
      providers: [
        FutureProvider<DatabaseService?>(
          create: (_) => DatabaseService.getInstance(),
          initialData: null, // Database will be null until ready
        ),
        FutureProvider<SharedPreferencesService?>(
          create: (_) => SharedPreferencesService.getInstance(),
          initialData: null,
        ),
        Provider<FlutterLocalNotificationsPlugin>(create: (_) => flutterLocalNotificationsPlugin),
        Provider(create: (context) => NotificationService(
          flutterLocalNotificationsPlugin,
          context.read<DatabaseService?>(), // Will be null initially
          UserProvider(),
        )),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Period Tracker',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
      routes: {
        '/period_tracking': (context) => PeriodTrackingScreen(),
        '/full_log': (context) => TrackSymptomMoodScreen(),
      },
    );
  }
}