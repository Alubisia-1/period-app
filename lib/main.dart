import 'package:flutter/material.dart';
import 'package:period_tracker_app/screens/home_screen.dart'; // Adjust the import path if necessary

void main() {
  runApp(const MyApp()); // Keep 'const' here
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // Add 'const' to the constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Period Tracker',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: HomeScreen(),
    );
  }
}