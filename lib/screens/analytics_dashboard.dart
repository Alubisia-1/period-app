import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Analytics Dashboard', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.pink[200],
          elevation: 0,
        ),
        body: Center(
          child: Text('Please log in to view your analytics.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Analytics Dashboard', style: TextStyle(color: Colors.black)),
            IconButton(
              icon: Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        actions: [],
        backgroundColor: Colors.pink[200],
        elevation: 0,
      ),
      backgroundColor: Colors.pink[50],
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: fetchAnalyticsData(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      final data = snapshot.data!;
                      return Column(
                        children: [
                          _buildMetricCard('Average Cycle Length', '${data['avgCycleLength']?.toStringAsFixed(2) ?? "--"} days'),
                          SizedBox(height: 20),
                          _buildMetricCard('Average Period Length', '${data['avgPeriodLength']?.toStringAsFixed(2) ?? "--"} days'),
                          SizedBox(height: 20),
                          _buildSymptomFrequencyChart(data['symptomFrequency'] ?? []),
                          SizedBox(height: 20),
                          _buildMoodPatternChart(data['moodPatterns'] ?? []),
                          SizedBox(height: 20),
                          _buildTemperatureTrendChart(data['tempTrends'] ?? []),
                          SizedBox(height: 20),
                          _buildFlowTrendChart(data['flowTrends'] ?? []),
                        ],
                      );
                    } else {
                      return Text('No data available');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value) => _buildCard(
        icon: Icons.timeline,
        title: title,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildSymptomFrequencyChart(List<Map<String, dynamic>> symptoms) {
    List<BarChartGroupData> barGroups = symptoms.map((symptom) {
      return BarChartGroupData(
        x: symptoms.indexOf(symptom),
        barRods: [
          BarChartRodData(
            toY: symptom['frequency'].toDouble(),
            color: Colors.pink,
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    return _buildCard(
      icon: Icons.healing,
      title: 'Symptom Frequency',
      content: Container(
        height: 200, 
        child: symptoms.isEmpty 
          ? Center(child: Text('No data available'))
          : BarChart(
              BarChartData(
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < symptoms.length) {
                          return Text(symptoms[value.toInt()]['symptom_name']);
                        }
                        return Text('');
                      },
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildMoodPatternChart(List<Map<String, dynamic>> moods) {
    List<PieChartSectionData> sections = moods.map((mood) {
      final isLarge = mood['frequency'].toDouble() > 10; // Just for demonstration; adjust threshold as needed
      return PieChartSectionData(
        color: Colors.pinkAccent.withOpacity(isLarge ? 1.0 : 0.7),
        value: mood['frequency'].toDouble(),
        title: mood['mood'],
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
        ),
        radius: isLarge ? 60 : 50,
      );
    }).toList();

    return _buildCard(
      icon: Icons.mood,
      title: 'Mood Patterns',
      content: Container(
        height: 200, 
        child: moods.isEmpty 
          ? Center(child: Text('No data available'))
          : PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
            ),
          ),
      ),
    );
  }

  Widget _buildTemperatureTrendChart(List<Map<String, dynamic>> temps) {
    List<FlSpot> spots = temps.map((temp) {
      DateTime date = DateTime.parse(temp['date']);
      return FlSpot(date.millisecondsSinceEpoch.toDouble(), temp['temperature'].toDouble());
    }).toList();

    return _buildCard(
      icon: Icons.thermostat,
      title: 'Temperature Trends',
      content: Container(
        height: 200, 
        child: temps.isEmpty 
          ? Center(child: Text('No data available'))
          : LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildFlowTrendChart(List<Map<String, dynamic>> flows) {
    List<BarChartGroupData> barGroups = flows.map((flow) {
      DateTime date = DateTime.parse(flow['date']);
      double flowValue = 0.0;
      switch (flow['flow_level']) {
        case 'light':
          flowValue = 1.0;
          break;
        case 'medium':
          flowValue = 2.0;
          break;
        case 'heavy':
          flowValue = 3.0;
          break;
        default:
          flowValue = 0.0; // Unknown or no flow
      }

      return BarChartGroupData(
        x: date.millisecondsSinceEpoch ~/ 86400000, // Convert to days since epoch for x-axis
        barRods: [
          BarChartRodData(
            toY: flowValue,
            color: _getFlowColor(flow['flow_level']),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    return _buildCard(
      icon: Icons.bloodtype,
      title: 'Flow Trends',
      content: Container(
        height: 200,
        child: flows.isEmpty 
          ? Center(child: Text('No data available'))
          : BarChart(
            BarChartData(
              barGroups: barGroups,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (flows.isNotEmpty && value.toInt() >= 0 && value.toInt() < flows.length) {
                        DateTime date = DateTime.parse(flows[value.toInt()]['date']);
                        return Text('${date.month}/${date.day}');
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == 1) return Text('Light');
                      if (value == 2) return Text('Medium');
                      if (value == 3) return Text('Heavy');
                      return Text('');
                    },
                  ),
                ),
              ),
            ),
          ),
      ),
    );
  }

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
                  Icon(icon, color: Colors.pink),
                  SizedBox(width: 8),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                ],
              ),
              SizedBox(height: 16),
              content,
            ],
          ),
        ),
      );

  Color _getFlowColor(String? flowLevel) {
    switch (flowLevel) {
      case 'light':
        return Colors.lightBlue;
      case 'medium':
        return Colors.blue;
      case 'heavy':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}

Future<Map<String, dynamic>> fetchAnalyticsData(int userId) async {
  final dbService = DatabaseService();
  final db = await dbService.database;

  try {
    // Average Cycle Length
    final avgCycleLength = await db.rawQuery('''
      SELECT AVG(julianday(end_date) - julianday(start_date)) as avg_cycle_length
      FROM cycles WHERE user_id = ?
    ''', [userId]);

    // Average Period Length
    final avgPeriodLength = await db.rawQuery('''
      SELECT AVG(julianday(end_date) - julianday(start_date)) as avg_period_length
      FROM cycles WHERE user_id = ?
    ''', [userId]);

    // Symptom Frequency
    final symptomFrequency = await db.rawQuery('''
      SELECT symptom_name, COUNT(*) as frequency 
      FROM symptoms 
      WHERE user_id = ? 
      GROUP BY symptom_name
    ''', [userId]);

    // Mood Patterns - Ensure each entry has 'mood' and 'frequency'
    final moodPatterns = await db.rawQuery('''
      SELECT mood, COUNT(*) as frequency 
      FROM daily_logs 
      WHERE user_id = ? AND mood IS NOT NULL
      GROUP BY mood
    ''', [userId]);
    // Filter out entries with missing data
    List<Map<String, dynamic>> filteredMoodPatterns = moodPatterns.where((mood) {
      return mood['mood'] != null && mood['frequency'] != null;
    }).toList();

    // Temperature Trends (simplified)
    final tempTrends = await db.rawQuery('''
      SELECT date, temperature 
      FROM daily_logs 
      WHERE user_id = ? AND temperature IS NOT NULL
      ORDER BY date ASC
    ''', [userId]);

    // Flow Intensity Trends - Ensure each entry has 'date' and 'flow_level'
    final flowTrends = await db.rawQuery('''
      SELECT date, flow_level 
      FROM daily_logs 
      WHERE user_id = ? AND flow_level IS NOT NULL AND date IS NOT NULL
      ORDER BY date ASC
    ''', [userId]);
    // Filter out entries with missing data
    List<Map<String, dynamic>> filteredFlowTrends = flowTrends.where((flow) {
      return flow['date'] != null && flow['flow_level'] != null;
    }).toList();

    return {
      'avgCycleLength': avgCycleLength.first['avg_cycle_length'] ?? 0,
      'avgPeriodLength': avgPeriodLength.first['avg_period_length'] ?? 0,
      'symptomFrequency': symptomFrequency,
      'moodPatterns': filteredMoodPatterns,
      'tempTrends': tempTrends,
      'flowTrends': filteredFlowTrends,
    };
  } catch (e) {
    print('Error fetching analytics data: $e');
    return {};
  }
}