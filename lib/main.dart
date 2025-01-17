import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Add this line to import kIsWeb
import 'services/database_service.dart';
import 'services/shared_preferences.dart'; // Ensure this import is correct
import 'screens/home_screen.dart';
import 'screens/period_tracking_screen.dart';
import 'screens/TrackSymptomMoodScreen.dart'; // Import the FullLogScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        Provider<DatabaseService?>.value(value: databaseService),
        Provider<SharedPreferencesService?>.value(value: sharedPreferencesService),
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
        '/full_log': (context) => TrackSymptomMoodScreen(), // Add the route for Full Log
      },
    );
  }
}
