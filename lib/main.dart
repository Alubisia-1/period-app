import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'services/database_service.dart';
import 'services/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/period_tracking_screen.dart';
import 'screens/TrackSymptomMoodScreen.dart';
import 'services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// AuthScreen implementation
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              if (!_isLogin)
                TextFormField(
                  controller: _dobController,
                  decoration: InputDecoration(labelText: 'Date of Birth (e.g., DD/MM/YYYY)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your date of birth';
                    }
                    // You might want to add date validation here
                    return null;
                  },
                ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Handle login or registration
                    if (_isLogin) {
                      print('Login: Name: ${_nameController.text}, Password: ${_passwordController.text}');
                      // Add login logic here
                    } else {
                      print('Register: Name: ${_nameController.text}, DoB: ${_dobController.text}, Password: ${_passwordController.text}');
                      // Add registration logic here
                    }
                  }
                },
                child: Text(_isLogin ? 'Login' : 'Register'),
              ),
              TextButton(
                onPressed: _toggleAuthMode,
                child: Text(_isLogin ? 'Need an account? Register' : 'Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite
  if (kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize TimeZone for scheduling notifications
  tz.initializeTimeZones();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize database or shared preferences
  DatabaseService? databaseService;
  SharedPreferencesService? sharedPreferencesService;

  if (kIsWeb) {
    sharedPreferencesService = await SharedPreferencesService.getInstance();
    // For web, we'll use a dummy DatabaseService or handle notifications without it
    databaseService = null;
  } else {
    databaseService = await DatabaseService.getInstance();
  }

  // Create NotificationService instance, handling the case where databaseService might be null
  final NotificationService notificationService;
  if (databaseService != null) {
    notificationService = NotificationService(flutterLocalNotificationsPlugin, databaseService);
  } else {
    // Here, we need to decide how to handle the case when databaseService is null.
    // One option is to create a version of NotificationService that doesn't require a DatabaseService.
    // For simplicity, let's assume NotificationService can work without DatabaseService on web.
    notificationService = NotificationService(flutterLocalNotificationsPlugin, null);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService?>(create: (_) => databaseService),
        Provider<SharedPreferencesService?>(create: (_) => sharedPreferencesService),
        Provider<FlutterLocalNotificationsPlugin>(create: (_) => flutterLocalNotificationsPlugin),
        Provider<NotificationService>(create: (_) => notificationService),
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
        '/registration': (context) => AuthScreen(),
      },
    );
  }
}