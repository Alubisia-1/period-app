import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../models/cycle_model.dart';

class PeriodTrackingScreen extends StatefulWidget {
  const PeriodTrackingScreen({super.key});

  @override
  _PeriodTrackingScreenState createState() => _PeriodTrackingScreenState();
}

class _PeriodTrackingScreenState extends State<PeriodTrackingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _flowIntensity;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<Map<String, Color>>> _events = {};

  final List<String> _flowIntensities = ['Light', 'Medium', 'Heavy'];

  @override
  Widget build(BuildContext context) {
    // Use nullable provider and check if it's not null before using
    final databaseService = Provider.of<DatabaseService?>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Period Tracking'),
        backgroundColor: Colors.pink[200],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Button to Start Cycle
                _buildCycleButton('Start Cycle', Icons.calendar_today, Colors.blue[300]!, _startCycle),
                SizedBox(height: 10),
                // Button to End Cycle
                _buildCycleButton('End Cycle', Icons.stop_circle, Colors.green[300]!, _endCycle),
                SizedBox(height: 10),
                // Flow Intensity Dropdown
                DropdownButtonFormField<String>(
                  value: _flowIntensity,
                  items: _flowIntensities.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _flowIntensity = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Flow Intensity',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                // Save Button
                ElevatedButton(
                  onPressed: databaseService != null && _startDate != null && _flowIntensity != null
                      ? () async {
                          if (_startDate != null) {
                            final Cycle cycle = Cycle(
                              startDate: _startDate!,
                              endDate: _endDate ?? _startDate!,
                              userId: 1,
                              flowLevel: _flowIntensity!,
                            );
                            
                            // Here we check if databaseService is not null before calling insertCycle
                            await databaseService.insertCycle(cycle.toMap());
                            
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                              _flowIntensity = null;
                              _events.clear();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Cycle logged successfully')),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('Save Cycle', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 20),
                // Calendar View
                SizedBox(
                  width: double.infinity,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: _getEventsForDay,
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: events.map((event) {
                                // Safe access to color, assuming 'event' might not have 'color'
                                final color = (event as Map<String, dynamic>)['color'] as Color?;
                                if (color != null) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                    width: 8.0,
                                    height: 8.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                    ),
                                  );
                                } else {
                                  return Container(); // Return an empty container if color is null
                                }
                              }).toList(),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.pink[200],
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                    ),
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCycleButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _startCycle() {
    setState(() {
      if (_startDate == null) {
        _startDate = DateTime.now();
        _events[_startDate!] = [{'color': Colors.blue[300]!}];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cycle already started. End the current cycle before starting a new one.')),
        );
      }
    });
  }

  void _endCycle() {
    if (_startDate != null && _endDate == null) {
      setState(() {
        _endDate = DateTime.now();
        _events[_endDate!] = [{'color': Colors.green[300]!}];
      });
    } else if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please start a cycle first.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cycle already ended.')),
      );
    }
  }

  List<Map<String, Color>> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }
}