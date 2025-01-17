import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Period Tracker', style: TextStyle(color: Colors.black)),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.pink, size: 30),
              onPressed: () => Navigator.pushNamed(context, '/period_tracking'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              // Handle notification action
            },
          ),
        ],
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
                _buildNextPeriodCard(),
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

  Widget _buildNextPeriodCard() => _buildCard(
        icon: Icons.calendar_today,
        title: 'Next Period',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated Date: January 20, 2025',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            Text(
              'Days Until: 28',
              style: TextStyle(
                fontSize: 14,
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info, color: Colors.pink, size: 18),
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
        ),
      );

  Widget _buildQuickLogSection(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 10),
          _buildQuickLogButton(Icons.thermostat, 'Temperature'),
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
              Navigator.pushNamed(context, '/full_log'); // Navigate to Full Log Screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[200],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text('View Full Log'),
          ),
        ],
      );

  Widget _buildQuickLogButton(IconData icon, String label) {
    if (label == 'Temperature') {
      return Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.pink[50], // Changed to match app background
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
                Icon(icon, color: Colors.pink, size: 24),
                SizedBox(width: 8),
                Text('Temperature', style: TextStyle(fontSize: 16)),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Handle the 'Log Now' action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Log Now', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
    } else {
      // For other buttons like Mood, Flow, keep the original design
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink[100],
          foregroundColor: Colors.black,
          shape: CircleBorder(),
          padding: EdgeInsets.all(15),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30),
            SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
  }

  Widget _buildSymptomColumn() => _buildColumnSection('Symptoms', ['Headache', 'Cramps', 'Nausea', 'Acne', 'Fatigue']);

  Widget _buildMoodColumn() => _buildColumnSection('Mood', ['Happy', 'Sad', 'Tired', 'Anxious', 'Neutral']);

  Widget _buildCycleHistoryCard() => _buildCard(
        icon: Icons.history,
        title: 'Cycle History',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last Period: January 1 - January 5, 2025', style: TextStyle(fontSize: 14, color: Colors.black54)),
            Text('Cycle Length: 28 days', style: TextStyle(fontSize: 14, color: Colors.black54)),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Navigate to detailed history
              },
              child: Text('View More', style: TextStyle(color: Colors.pink)),
            ),
          ],
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

  Widget _buildColumnSection(String title, List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 10),
          ...List.generate(
            (items.length / 2).ceil(),
            (index) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: items.sublist(index * 2, (index * 2) + 2 > items.length ? items.length : (index * 2) + 2).map(
                (item) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[100],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(item, style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      );
}