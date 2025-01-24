import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/database_service.dart';
import 'services/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/period_tracking_screen.dart';
import 'screens/TrackSymptomMoodScreen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for appropriate platform
  if (kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize local notifications
  if (!kIsWeb) { // Local notifications are not supported on web
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Replace 'app_icon' with your drawable resource
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Initialize database or shared preferences based on the platform
  DatabaseService? databaseService;
  SharedPreferencesService? sharedPreferencesService;

  if (kIsWeb) {
    sharedPreferencesService = await SharedPreferencesService.getInstance();
  } else {
    databaseService = await DatabaseService.getInstance();
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService?>(create: (_) => databaseService),
        Provider<SharedPreferencesService?>(create: (_) => sharedPreferencesService),
        Provider<FlutterLocalNotificationsPlugin>(create: (_) => flutterLocalNotificationsPlugin),
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