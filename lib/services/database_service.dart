import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'dart:convert'; 
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:pointycastle/key_derivators/api.dart' as pointycastle;
import 'package:pointycastle/key_derivators/pbkdf2.dart' as pointycastle;
import 'package:pointycastle/digests/sha256.dart' as pointycastle;
import 'package:pointycastle/macs/hmac.dart' as pointycastle;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  final _storage = FlutterSecureStorage();
  final _logger = Logger('DatabaseService');

  Database? _database;

  DatabaseService._internal();

  /// Singleton pattern to ensure only one instance of DatabaseService is created.
  static Future<DatabaseService> getInstance() async {
    if (_instance._database == null) {
      // Only initialize if it hasn't been done yet
      await _instance._initDB();
    }
    return _instance;
  }

  /// Getter for the database instance, initializes if not already done.
  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB();
      return _database!;
    } catch (e, stackTrace) {
      _logger.severe('Error getting database', e, stackTrace);
      throw Exception('Failed to get database: $e');
    }
  }

  /// Initializes the database by creating it if it doesn't exist and setting up the schema.
  Future _initDB() async {
    String? password = await _storage.read(key: 'user_password'); // Assume this is the login password
    if (password == null) {
      _logger.severe('No password set for user');
      throw Exception('No password set for user');
    }

    // PBKDF2 Key Derivation
    final salt = utf8.encode('some_salt_value'); // Use a fixed salt or generate one per user
    final iterations = 10000; // Higher number for production to slow down key derivation
    final keyLength = 32; // 32 bytes = 256 bits for AES-256 in SQLCipher

    // Setup PBKDF2 with HMAC-SHA256
    final pbkdf2 = pointycastle.PBKDF2KeyDerivator(pointycastle.HMac(pointycastle.SHA256Digest(), 64));
    pbkdf2.init(pointycastle.Pbkdf2Parameters(salt, iterations, keyLength));

    final key = pbkdf2.process(utf8.encode(password));
    final encryptionKey = key.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    if (kIsWeb) {
      _logger.severe('Encryption not supported on web');
      throw Exception('Encryption not supported on web');
    } else {
      String path = p.join(await sqflite.getDatabasesPath(), 'period_tracker_encrypted.db');      
      try {
        _database = await sqlcipher.openDatabase(
          path,
          version: 2,
          onCreate: _createTables,
          onUpgrade: _onUpgrade,
          password: encryptionKey, // Use the derived key
        );
      } catch (e, stackTrace) {
        _logger.severe('Error initializing database', e, stackTrace);
        throw Exception('Failed to initialize database: $e');
      }
    }
    return _database!;
  }

  /// Creates all necessary tables for the application.
  Future<void> _createTables(Database db, int version) async {
    try {
      await db.execute(
        "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, date_of_birth DATE, cycle_average INTEGER, password TEXT)",
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
      await db.execute(
        "CREATE TABLE notifications (id INTEGER PRIMARY KEY, title TEXT, body TEXT, is_read INTEGER DEFAULT 0, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, user_id INTEGER, FOREIGN KEY (user_id) REFERENCES users(id))",
      );
      _logger.info('Tables created successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error creating tables', e, stackTrace);
      throw Exception('Failed to create database schema: $e');
    }
  }

  /// Handles database upgrades.
  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE users ADD COLUMN password TEXT");
      } catch (e, stackTrace) {
        _logger.warning('Error upgrading database from $oldVersion to $newVersion', e, stackTrace);
      }
    }
  }

  /// Inserts a cycle into the cycles table. Uses REPLACE conflict algorithm to handle duplicates.
  Future<void> insertCycle(Map<String, dynamic> cycle) async {
    final db = await database;
    await db.transaction((txn) async {
      try {
        await txn.insert('cycles', cycle, conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (e, stackTrace) {
        _logger.warning('Error inserting cycle within transaction', e, stackTrace);
        throw Exception('Failed to insert cycle: $e');
      }
    });
  }

Future<void> insertDailyLog(Map<String, Object?> log) async {
  final db = await database;
  try {
    await db.insert('daily_logs', log, conflictAlgorithm: ConflictAlgorithm.replace);
  } catch (e, stackTrace) {
    _logger.warning('Failed to insert daily log', e, stackTrace);
    throw Exception('Failed to insert daily log: $e');
  }
}

/// Updates or inserts a mood into the daily_logs table using a transaction.
Future<void> updateDailyLog(Map<String, dynamic> log) async {
  final db = await database;
  await db.transaction((txn) async {
    try {
      // First, check if there's an existing entry for the date
      var existingLog = await txn.query(
        'daily_logs',
        where: 'date = ? AND user_id = ?',
        whereArgs: [log['date'], log['user_id']],
      );

      if (existingLog.isNotEmpty) {
        // Update the existing log
        await txn.update(
          'daily_logs',
          log,
          where: 'date = ? AND user_id = ?',
          whereArgs: [log['date'], log['user_id']],
        );
      } else {
        // Insert a new log if none exists
        await txn.insert('daily_logs', log, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e, stackTrace) {
      _logger.warning('Error updating or inserting daily log within transaction', e, stackTrace);
      throw Exception('Failed to update or insert daily log: $e');
    }
  });
}

  /// Inserts a user into the users table. Uses REPLACE conflict algorithm to handle duplicates.
  Future<void> insertUser(Map<String, dynamic> userData) async {
    final db = await database;
    try {
      await db.insert('users', userData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e, stackTrace) {
      _logger.warning('Failed to insert user', e, stackTrace);
      throw Exception('Failed to insert user: $e');
    }
  }

  /// Inserts a symptom into the symptoms table. Uses REPLACE conflict algorithm to handle duplicates.
  Future<void> insertSymptom(Map<String, dynamic> symptom) async {
    final db = await database;
    try {
      await db.insert('symptoms', symptom, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e, stackTrace) {
      _logger.warning('Error to insert symptom', e, stackTrace);
      throw Exception('Failed to insert symptom: $e');
    }
  }
  /// Inserts a notification into the notifications table.
  Future<void> insertNotification(Map<String, dynamic> notificationData) async {
    final db = await database;
    try {
      await db.insert('notifications', notificationData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e, stackTrace) {
       _logger.warning('Failed to insert notification', e, stackTrace);
      throw Exception('Failed to insert notification: $e');
    }
  }

  /// Fetches all notifications for a specific user, ordered by timestamp.
  Future<List<Map<String, dynamic>>> fetchNotifications(int userId) async {
    final db = await database;
    try {
      return await db.query('notifications', where: 'user_id = ?', whereArgs: [userId], orderBy: 'timestamp DESC');
    } catch (e, stackTrace) {
       _logger.warning('Failed to fetch notifications', e, stackTrace);
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Deletes a notification from the database.
  Future<void> deleteNotification(int notificationId) async {
    final db = await database;
    try {
      await db.delete('notifications', where: 'id = ?', whereArgs: [notificationId]);
    } catch (e, stackTrace) {
       _logger.warning('Failed to delete notification', e, stackTrace);
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Marks a notification as read by updating its status.
  Future<void> markNotificationAsRead(int notificationId) async {
    final db = await database;
    try {
      await db.update('notifications', {'is_read': 1}, where: 'id = ?', whereArgs: [notificationId]);
    } catch (e, stackTrace) {
       _logger.warning('Failed to mark notification as read', e, stackTrace);
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}