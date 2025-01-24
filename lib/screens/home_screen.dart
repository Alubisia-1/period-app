import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../logic/prediction_algorithm.dart';
import '../services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';
import './analytics_dashboard.dart';
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import '../services/backup_service.dart';

class HomeScreen extends StatelessWidget {
  final BackupService backupService = BackupService();
  
  // Define color scheme for consistency
  static const Color primaryColor = Color(0xFFE91E63); // Pink color
  static const Color accentColor = Color(0xFFF8BBD0); // Light pink

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = screenWidth > 600 ? 32.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Period Tracker', style: TextStyle(color: Colors.black, fontFamily: 'Roboto')),
            IconButton(
              icon: Icon(Icons.add_circle, color: primaryColor, size: 30),
              onPressed: () => _navigateToPeriodTracking(context),
              tooltip: 'Add New Period Entry',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              // Handle notification action
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              _showBackupMenu(context);
            },
            tooltip: 'More Options',
          ),
        ],
        backgroundColor: accentColor,
        elevation: 0,
      ),
      backgroundColor: Colors.pink[50],
      body: Center(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          constraints: BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 500),
                  child: _buildNextPeriodCard(),
                ),
                SizedBox(height: 20),
                _buildQuickLogSection(context),
                SizedBox(height: 20),
                _buildSymptomColumn(),
                SizedBox(height: 20),
                _buildMoodColumn(),
                SizedBox(height: 20),
                _buildCycleHistoryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPeriodTracking(BuildContext context) {
    Navigator.pushNamed(context, '/period_tracking').whenComplete(() {
      // Refresh data or UI if needed after navigation back
    });
  }

  void _showBackupMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.topRight(Offset.zero), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'backup',
          child: Text('Backup Data'),
        ),
        PopupMenuItem<String>(
          value: 'restore',
          child: Text('Restore Data'),
        ),
      ],
      elevation: 8.0,
    ).then((String? value) {
      if (value == 'backup') {
        _handleBackup(context);
      } else if (value == 'restore') {
        _handleRestore(context);
      }
    });
  }

  void _handleBackup(BuildContext context) async {
    try {
      await backupService.backupDatabase();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup successful')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  void _handleRestore(BuildContext context) async {
    try {
      await backupService.restoreDatabase();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore successful')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  Widget _buildNextPeriodCard() => _buildCard(
        icon: Icons.calendar_today,
        title: 'Next Period',
        content: FutureBuilder<DateTime?>(
          future: PredictionAlgorithm().predictNextPeriod(1),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Date: ${DateFormat('MMMM d, yyyy').format(snapshot.data!)}',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Text(
                    'Days Until: ${snapshot.data!.difference(DateTime.now()).inDays}',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.info, color: primaryColor, size: 18),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'This is an estimate based on your cycle history.',
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Text('No data available to predict.');
            }
          },
        ),
      );

  Widget _buildQuickLogSection(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto')),
          SizedBox(height: 10),
          _buildTemperatureLogButton(context),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickLogButton(Icons.mood, 'Mood'),
              _buildQuickLogButton(Icons.bloodtype, 'Flow'),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/full_log');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text('View Full Log'),
          ),
        ],
      );

  Widget _buildTemperatureLogButton(BuildContext context) => Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.pink[50],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat, color: primaryColor, size: 24),
                SizedBox(width: 8),
                Text('Temperature', style: TextStyle(fontSize: 16, fontFamily: 'Roboto')),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                _showTemperatureOptions(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Log Now', style: TextStyle(fontSize: 14, fontFamily: 'Roboto')),
            ),
          ],
        ),
      );

  void _showTemperatureOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.bluetooth),
                  title: Text('Smart Thermometer'),
                  onTap: () {
                    _showTemperatureManualPairPrompt(context);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Manual Entry'),
                  onTap: () {
                    _showTemperaturePrompt(context);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTemperatureManualPairPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect Thermometer'),
        content: Text('Ensure your thermometer is paired via your device\'s Bluetooth settings. Look for devices like "Smart Thermometer" or similar.'),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _connectToThermometer(context);
            },
            child: Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _connectToThermometer(BuildContext context) async {
    String deviceAddress = "00:11:22:33:44:55"; // Replace with actual device address
    String? connectionResult = await BluetoothThermalPrinter.connect(deviceAddress);
    
    if (connectionResult == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to thermometer.'))
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to thermometer. Error: $connectionResult'))
        );
      }
    }
  }

  void _showTemperaturePrompt(BuildContext context) {
    TextEditingController temperatureController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Temperature'),
        content: TextField(
          controller: temperatureController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Enter Temperature (°C)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String temperature = temperatureController.text;
              if (temperature.isNotEmpty && isNumeric(temperature)) {
                double temp = double.parse(temperature);
                saveTemperature(temp);
                if (context.mounted) Navigator.pop(context);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid temperature.'))
                  );
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  bool isNumeric(String s) => double.tryParse(s) != null;

  void saveTemperature(double temp) async {
    final dbService = DatabaseService();
    await dbService.insertDailyLog({
      'temperature': temp,
      'date': DateTime.now().toIso8601String(),
      'user_id': 1, // Assuming user ID, replace with actual logic
    });
  }

  Widget _buildQuickLogButton(IconData icon, String label) => ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          shape: CircleBorder(),
          padding: EdgeInsets.all(15),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30),
            SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 12, fontFamily: 'Roboto')),
          ],
        ),
      );

  Widget _buildSymptomColumn() => _buildColumnSection('Symptoms', ['Headache', 'Cramps', 'Nausea', 'Acne', 'Fatigue']);

  Widget _buildMoodColumn() => _buildColumnSection('Mood', ['Happy', 'Sad', 'Tired', 'Anxious', 'Neutral']);

  Widget _buildCycleHistoryCard() => _buildCard(
        icon: Icons.history,
        title: 'Cycle History',
        content: FutureBuilder<Widget>(
          future: _buildCycleHistoryChart(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last Period: January 1 - January 5, 2025', style: TextStyle(fontSize: 14, color: Colors.black54, fontFamily: 'Roboto')),
                  Text('Cycle Length: 28 days', style: TextStyle(fontSize: 14, color: Colors.black54, fontFamily: 'Roboto')),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => AnalyticsDashboard(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            var begin = Offset(1.0, 0.0);
                            var end = Offset.zero;
                            var curve = Curves.ease;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Text('View More', style: TextStyle(color: primaryColor, fontFamily: 'Roboto')),
                  ),
                  SizedBox(height: 20),
                  snapshot.data!,
                ],
              );
            } else {
              return Text('No chart data available.', style: TextStyle(fontFamily: 'Roboto'));
            }
          },
        ),
      );

  Widget _buildCard({required IconData icon, required String title, required Widget content}) => Card(
        color: Colors.pink[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: primaryColor),
                  SizedBox(width: 8),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black, fontFamily: 'Roboto')),
                ],
              ),
              SizedBox(height: 16),
              content,
            ],
          ),
        ),
      );

  Widget _buildColumnSection(String title, List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto')),
          SizedBox(height: 10),
          ...List.generate(
            (items.length / 2).ceil(),
            (index) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: items
                  .sublist(index * 2, (index * 2) + 2 > items.length ? items.length : (index * 2) + 2)
                  .map((item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(item, style: TextStyle(fontFamily: 'Roboto')),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      );

  Future<Widget> _buildCycleHistoryChart() async {
    int userId = 1; // Replace with actual user ID fetch logic
    final List<FlSpot> temperatureSpots = await fetchTemperatureDataForChart(userId);

    return AspectRatio(
      aspectRatio: 2.2,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: temperatureSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: false),
            )
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              axisNameWidget: Text('Days', style: TextStyle(fontFamily: 'Roboto')),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text('Day ${value.toInt()}', style: TextStyle(fontFamily: 'Roboto')),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: TextStyle(fontFamily: 'Roboto')),
                reservedSize: 30,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: true, drawHorizontalLine: true),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey, width: 1)),
          minX: 1,
          maxX: DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day.toDouble(),
          minY: 35,
          maxY: 38,
        ),
      ),
    );
  }

  Future<List<FlSpot>> fetchTemperatureDataForChart(int userId) async {
    final dbService = DatabaseService();
    final db = await dbService.database;
    
    final List<Map<String, dynamic>> logs = await db.query(
      'daily_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    List<FlSpot> spots = [];
    for (var log in logs) {
      DateTime logDate = DateTime.parse(log['date']);
      if (logDate.month == DateTime.now().month && logDate.year == DateTime.now().year) {
        double? temperature = log['temperature']?.toDouble();
        if (temperature != null) {
          spots.add(FlSpot(logDate.day.toDouble(), temperature));
        }
      }
    }
    
    return spots;
  }
}