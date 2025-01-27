import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  Database? _database;

  DatabaseService._internal();

  /// Singleton pattern to ensure only one instance of DatabaseService is created.
  static Future<DatabaseService> getInstance() async {
    return _instance;
  }

  /// Getter for the database instance, initializes if not already done.
  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB();
      return _database!;
    } catch (e) {
      print('Error getting database: $e');
      throw Exception('Failed to get database: $e');
    }
  }

  /// Initializes the database by creating it if it doesn't exist and setting up the schema.
  Future<Database> _initDB() async {
    if (kIsWeb) {
      // For web, use in-memory database
      return await databaseFactory.openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createTables,
      ));
    } else {
      // For mobile, use file-based storage
      String path = join(await getDatabasesPath(), 'period_tracker.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
      );
    }
  }

  /// Creates all necessary tables for the application.
  Future<void> _createTables(Database db, int version) async {
    try {
      await db.execute(
        "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, date_of_birth DATE, cycle_average INTEGER)",
      );
      await db.execute(
        "CREATE TABLE cycles (id INTEGER PRIMARY KEY, start_date DATE, end_date DATE, user_id INTEGER, FOREIGN KEY (user_id) REFERENCES users(id))",
      );
      await db.execute(
        "CREATE TABLE daily_logs (id INTEGER PRIMARY KEY, date DATE, temperature REAL, mood TEXT, flow_level TEXT, user_id INTEGER, FOREIGN KEY (user_id) REFERENCES users(id))",
      );
      await db.execute(
        "CREATE TABLE symptoms (id INTEGER PRIMARY KEY, date DATE, symptom_name TEXT, severity INTEGER, user_id INTEGER, FOREIGN KEY (user_id) REFERENCES users(id))",
      );
    } catch (e) {
      print('Error creating tables: $e');
      throw Exception('Failed to create database schema: $e');
    }
  }

  /// Inserts a cycle into the cycles table. Uses REPLACE conflict algorithm to handle duplicates.
  Future<void> insertCycle(Map<String, dynamic> cycle) async {
    final db = await database;
    try {
      await db.insert('cycles', cycle, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error inserting cycle: $e');
      throw Exception('Failed to insert cycle: $e');
    }
  }

  /// Inserts a daily log into the daily_logs table. Uses REPLACE conflict algorithm to handle duplicates.
  Future<void> insertDailyLog(Map<String, dynamic> log) async {
    final db = await database;
    try {
      await db.insert('daily_logs', log, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error inserting daily log: $e');
      throw Exception('Failed to insert daily log: $e');
    }
  }

  /// Inserts a symptom into the symptoms table. Uses REPLACE conflict algorithm to handle duplicates.
  Future<void> insertSymptom(Map<String, dynamic> symptom) async {
    final db = await database;
    try {
      await db.insert('symptoms', symptom, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error inserting symptom: $e');
      throw Exception('Failed to insert symptom: $e');
    }
  }

  /// Updates or inserts a mood into the daily_logs table. 
  Future<void> updateDailyLog(Map<String, dynamic> log) async {
    final db = await database;
    try {
      // First, check if there's an existing entry for the date
      var existingLog = await db.query(
        'daily_logs',
        where: 'date = ? AND user_id = ?',
        whereArgs: [log['date'], log['user_id']],
      );

      if (existingLog.isNotEmpty) {
        // Update the existing log
        await db.update(
          'daily_logs',
          log,
          where: 'date = ? AND user_id = ?',
          whereArgs: [log['date'], log['user_id']],
        );
      } else {
        // Insert a new log if none exists
        await db.insert('daily_logs', log, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Error updating or inserting daily log: $e');
      throw Exception('Failed to update or insert daily log: $e');
    }
  }

  // Add more methods for CRUD operations as needed (e.g., delete, fetch, update others)
}