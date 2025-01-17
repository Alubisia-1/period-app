// File: services/shared_preferences_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesService {
  static final SharedPreferencesService _instance = SharedPreferencesService._internal();
  factory SharedPreferencesService() => _instance;

  late SharedPreferences _prefs;

  SharedPreferencesService._internal();

  static Future<SharedPreferencesService> getInstance() async {
    _instance._prefs = await SharedPreferences.getInstance();
    return _instance;
  }

  // Helper method to save cycle data
  Future<void> saveCycle(String key, Map<String, dynamic> cycle) async {
    String cycleJson = jsonEncode(cycle);
    await _prefs.setString(key, cycleJson);
  }

  // Helper method to retrieve cycle data
  Map<String, dynamic> getCycle(String key) {
    String? cycleJson = _prefs.getString(key);
    if (cycleJson != null) {
      return jsonDecode(cycleJson);
    }
    return {};
  }

  // Add more methods for other CRUD operations as needed
}