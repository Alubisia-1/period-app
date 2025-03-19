import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../models/cycle_model.dart';
import '../providers/user_provider.dart';

class PeriodTrackingScreen extends StatefulWidget {
  const PeriodTrackingScreen({super.key});

  @override
  PeriodTrackingScreenState createState() => PeriodTrackingScreenState();
}

class PeriodTrackingScreenState extends State<PeriodTrackingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _flowIntensity;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<Map<String, Color>>> _events = {};

  final List<String> _flowIntensities = ['Light', 'Medium', 'Heavy'];

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService?>(
      builder: (context, databaseService, child) {
        if (databaseService == null) {
          // Show loading while DatabaseService is initializing
          return Scaffold(
            appBar: AppBar(  // Removed 'const' here
              title: const Text('Period Tracking'),  // Text can remain const
              backgroundColor: Colors.pink,
            ),
            body: const Center(child: CircularProgressIndicator()),  // Center can remain const
          );
        }

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        int? userId = userProvider.user?.id;

        if (userId == null) {
          return Scaffold(
            appBar: AppBar(  // Removed 'const' here
              title: const Text('Period Tracking'),  // Text can remain const
              backgroundColor: Colors.pink[200],
            ),
            body: const Center(
              child: Text('Please log in to track your periods.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(  // Removed 'const' here
            title: const Text('Period Tracking'),  // Text can remain const
            backgroundColor: Colors.pink[200],
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),  // Constraints can remain const
              padding: const EdgeInsets.all(16.0),  // Padding can remain const
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildCycleButton(
                      'Start Cycle',
                      Icons.calendar_today,
                      Colors.blue[300]!,
                      _startCycle,
                    ),
                    const SizedBox(height: 10),  // SizedBox can remain const
                    _buildCycleButton(
                      'End Cycle',
                      Icons.stop_circle,
                      Colors.green[300]!,
                      _endCycle,
                    ),
                    const SizedBox(height: 10),  // SizedBox can remain const
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
                      decoration: const InputDecoration(
                        labelText: 'Flow Intensity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),  // SizedBox can remain const
                    ElevatedButton(
                      onPressed: _startDate != null && _flowIntensity != null
                          ? () => _saveCycle(databaseService, userId)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Save Cycle', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),  // SizedBox can remain const
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
                                      return Container();
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
                          selectedDecoration: const BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
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
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
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
          const SnackBar(content: Text('Cycle already started. End the current cycle before starting a new one.')),
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
        const SnackBar(content: Text('Please start a cycle first.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle already ended.')),
      );
    }
  }

  void _saveCycle(DatabaseService databaseService, int userId) {
    if (_startDate != null && _flowIntensity != null) {
      final Cycle cycle = Cycle(
        startDate: _startDate!,
        endDate: _endDate ?? _startDate!,
        userId: userId,
        flowLevel: _flowIntensity!,
      );

      if (mounted) {
        databaseService.insertCycle(cycle.toMap()).then((value) {
          if (mounted) {
            setState(() {
              _startDate = null;
              _endDate = null;
              _flowIntensity = null;
              _events.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cycle logged successfully')),
            );
          }
        }).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save cycle: $error')),
            );
          }
        });
      }
    }
  }

  List<Map<String, Color>> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }
}