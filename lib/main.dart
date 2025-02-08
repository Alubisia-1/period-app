import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

setupLogging();

  if (kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  DatabaseService? databaseService;
  SharedPreferencesService? sharedPreferencesService;

  if (kIsWeb) {
    sharedPreferencesService = await SharedPreferencesService.getInstance();
    // For web, we'll initialize the database service, but it will use in-memory database
    databaseService = DatabaseService();
  } else {
    databaseService = await DatabaseService.getInstance();
  }

  final userProvider = UserProvider(); // Create UserProvider instance

  // Create NotificationService instance
  final NotificationService notificationService = NotificationService(flutterLocalNotificationsPlugin, databaseService, userProvider);

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService?>(create: (_) => databaseService),
        Provider<SharedPreferencesService?>(create: (_) => sharedPreferencesService),
        Provider<FlutterLocalNotificationsPlugin>(create: (_) => flutterLocalNotificationsPlugin),
        Provider<NotificationService>(create: (_) => notificationService),
        ChangeNotifierProvider(create: (_) => userProvider),
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