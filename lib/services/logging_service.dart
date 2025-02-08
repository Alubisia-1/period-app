// lib/services/logging_service.dart
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void setupLogging() async {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) async {
    if (record.level >= Level.WARNING) {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/app.log');
      if (!await logFile.exists()) {
        await logFile.create();
      }
      await logFile.writeAsString('${record.level.name}: ${record.time}: ${record.message}\n', mode: FileMode.append);
    }
  });
}

Future manageLogSize() async {
  final dir = await getApplicationDocumentsDirectory();
  final logFile = File('${dir.path}/app.log');
  if (await logFile.exists()) {
    final size = await logFile.length();
    if (size > 1024 * 1024) { // If file is over 1MB
      await logFile.writeAsString('', mode: FileMode.write); // Clear the log
    }
  }
}