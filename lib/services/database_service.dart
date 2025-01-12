import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  // Singleton pattern to ensure only one instance of the database is created
  static final DatabaseService _instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  factory DatabaseService() => _instance;

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('period_tracker.db');
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create Users table
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            name TEXT,
            date_of_birth DATE,
            cycle_average INTEGER
          )
        ''');

        // Create Cycles table
        await db.execute('''
          CREATE TABLE cycles (
            id INTEGER PRIMARY KEY,
            start_date DATE,
            end_date DATE,
            user_id INTEGER,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');

        // Create Daily Logs table
        await db.execute('''
          CREATE TABLE daily_logs (
            id INTEGER PRIMARY KEY,
            date DATE,
            temperature REAL,
            mood TEXT,
            flow_level TEXT,
            user_id INTEGER,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');

        // Create Symptoms table
        await db.execute('''
          CREATE TABLE symptoms (
            id INTEGER PRIMARY KEY,
            date DATE,
            symptom_name TEXT,
            severity INTEGER,
            user_id INTEGER,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
      },
    );
  }

  // Example method to insert a user
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await DatabaseService().database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Example method to query all users
  Future<List<Map<String, dynamic>>> queryAllUsers() async {
    final db = await DatabaseService().database;
    return await db.query('users');
  }

  // Example method to insert a cycle
  Future<void> insertCycle(Map<String, dynamic> cycle) async {
    final db = await DatabaseService().database;
    await db.insert('cycles', cycle, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Example method to query all cycles for a user
  Future<List<Map<String, dynamic>>> queryAllCycles(int userId) async {
    final db = await DatabaseService().database;
    return await db.query('cycles', where: 'user_id = ?', whereArgs: [userId]);
  }

  // Example method to insert a daily log
  Future<void> insertDailyLog(Map<String, dynamic> dailyLog) async {
    final db = await DatabaseService().database;
    await db.insert('daily_logs', dailyLog, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Example method to query daily logs for a specific date and user
  Future<List<Map<String, dynamic>>> queryDailyLogsByDateAndUser(DateTime date, int userId) async {
    final db = await DatabaseService().database;
    return await db.query('daily_logs', where: 'date = ? AND user_id = ?', whereArgs: [date.toIso8601String(), userId]);
  }

  // Example method to insert a symptom
  Future<void> insertSymptom(Map<String, dynamic> symptom) async {
    final db = await DatabaseService().database;
    await db.insert('symptoms', symptom, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Example method to query symptoms for a user on a specific date
  Future<List<Map<String, dynamic>>> querySymptomsByDateAndUser(DateTime date, int userId) async {
    final db = await DatabaseService().database;
    return await db.query('symptoms', where: 'date = ? AND user_id = ?', whereArgs: [date.toIso8601String(), userId]);
  }
}