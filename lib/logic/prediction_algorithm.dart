// File: lib/logic/prediction_algorithm.dart
import '../services/database_service.dart';
class PredictionAlgorithm {
  final DatabaseService _dbService = DatabaseService();

  /// Predicts the next period start date based on historical cycle data.
  /// 
  /// [userId] The ID of the user for whom the prediction is being made.
  /// 
  /// Returns a [Future] of [DateTime] representing the predicted start date of the next period,
  /// or [null] if there isn't enough data to make a prediction.
  Future<DateTime?> predictNextPeriod(int userId) async {
    // Fetch all cycles for the user
    final db = await _dbService.database;
    List<Map<String, dynamic>> cycles = await db.query('cycles', where: 'user_id = ?', whereArgs: [userId]);

    if (cycles.isEmpty) {
      return null; // No data to predict from
    }

    // Convert string dates to DateTime objects
    List<DateTime> startDates = cycles.map((cycle) => DateTime.parse(cycle['start_date'])).toList();
    startDates.sort((a, b) => b.compareTo(a)); // Sort by most recent first

    // Calculate average cycle length
    List<int> cycleLengths = [];
    for (int i = 0; i < startDates.length - 1; i++) {
      cycleLengths.add(startDates[i].difference(startDates[i + 1]).inDays);
    }

    if (cycleLengths.isEmpty) {
      return null; // Not enough data to calculate average
    }

    int averageCycleLength = cycleLengths.reduce((a, b) => a + b) ~/ cycleLengths.length;

    // Predict next period based on the last cycle start date
    DateTime lastCycleStart = startDates.first;
    DateTime now = DateTime.now();
    DateTime predictedDate = lastCycleStart.add(Duration(days: averageCycleLength));

    // Adjust prediction if it's in the past
    while (predictedDate.isBefore(now)) {
      predictedDate = predictedDate.add(Duration(days: averageCycleLength));
    }

    return predictedDate;
  }
}