import 'package:intl/intl.dart'; // Import the intl package

class Cycle {
  final int? id;
  final DateTime startDate;
  final DateTime endDate;
  final int userId;
  final String flowLevel;

  Cycle({this.id, required this.startDate, required this.endDate, required this.userId, required this.flowLevel});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      'user_id': userId,
      'flow_level': flowLevel,
    };
  }

  factory Cycle.fromMap(Map<String, dynamic> map) {
    return Cycle(
      id: map['id'],
      startDate: DateFormat('yyyy-MM-dd').parse(map['start_date']),
      endDate: DateFormat('yyyy-MM-dd').parse(map['end_date']),
      userId: map['user_id'],
      flowLevel: map['flow_level'],
    );
  }
}