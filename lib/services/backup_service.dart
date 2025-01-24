import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;

  BackupService._internal();

  Future<void> backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/period_tracker.db');
      final backupPath = await _getBackupPath();
      await dbFile.copy(backupPath);
      print('Database backed up to: $backupPath');
    } catch (e) {
      print('Backup failed: $e');
      throw Exception('Failed to backup database: $e');
    }
  }

  Future<void> restoreDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final backupPath = await _getBackupPath();
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        final dbFile = File('$dbPath/period_tracker.db');
        await dbFile.delete(); // Delete current database
        await backupFile.copy(dbFile.path);
        print('Database restored from: $backupPath');
      } else {
        throw Exception('Backup file does not exist');
      }
    } catch (e) {
      print('Restore failed: $e');
      throw Exception('Failed to restore database: $e');
    }
  }

  Future<String> _getBackupPath() async {
    final backupDir = await getApplicationDocumentsDirectory();
    return '${backupDir.path}/period_tracker_backup.db';
  }
}