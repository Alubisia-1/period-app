import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Period Tracker', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.pink[200],
        elevation: 0,
      ),
      backgroundColor: Colors.pink[50],
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // Changed to SingleChildScrollView for scrollability
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ensures the Column takes up only the space of its children
              children: [
                // Next Period Card
                _buildNextPeriodCard(),
                SizedBox(height: 20),
                // Quick Log Section
                _buildQuickLogSection(),
                SizedBox(height: 20),
                // Symptom Grid
                _buildSymptomGrid(),
                SizedBox(height: 20),
                // Mood Grid
                _buildMoodGrid(),
                SizedBox(height: 20),
                // Cycle History Card
                _buildCycleHistoryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextPeriodCard() {
    return Card(
      color: Colors.pink[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.pink),
                SizedBox(width: 8),
                Text('Next Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: Text('12', style: TextStyle(fontSize: 32, color: Colors.pink, fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('days away', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        SizedBox(height: 16),
        Card(
          color: Colors.pink[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Temperature', style: TextStyle(color: Colors.black)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[100],
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {},
                  child: Text('Log Now'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomGrid() {
    List<String> symptoms = ['Cramps', 'Headache', 'Fatigue', 'Bloating'];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      padding: EdgeInsets.zero,
      children: symptoms.map((symptom) => 
        Card(
          color: Colors.grey[100],
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(symptom, style: TextStyle(fontSize: 16, color: Colors.black))),
        )
      ).toList(),
    );
  }

  Widget _buildMoodGrid() {
    List<String> moods = ['Happy', 'Sad', 'Irritable', 'Anxious'];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      padding: EdgeInsets.zero,
      children: moods.map((mood) => 
        Card(
          color: Colors.purple[100],
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(mood, style: TextStyle(fontSize: 16, color: Colors.black))),
        )
      ).toList(),
    );
  }

  Widget _buildCycleHistoryCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.green),
                SizedBox(width: 8),
                Text('Cycle History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: Text('Chart will go here', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}