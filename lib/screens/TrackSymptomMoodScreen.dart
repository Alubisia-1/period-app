import 'package:flutter/material.dart';

class TrackSymptomMoodScreen extends StatefulWidget {
  const TrackSymptomMoodScreen({super.key});

  @override
  _TrackSymptomMoodScreenState createState() => _TrackSymptomMoodScreenState();
}

class _TrackSymptomMoodScreenState extends State<TrackSymptomMoodScreen> {
  // Variables to track the selected symptoms and mood
  List<String> selectedSymptoms = [];
  String selectedMood = "Neutral";

  // Sample list of symptoms
  final List<String> symptoms = [
    'Headache', 'Cramps', 'Nausea', 'Acne', 'Fatigue'
  ];

  // Sample list of moods
  final List<String> moods = ['Happy', 'Sad', 'Tired', 'Anxious', 'Neutral'];

  // Method to update the selected symptoms
  void _toggleSymptom(String symptom) {
    setState(() {
      if (selectedSymptoms.contains(symptom)) {
        selectedSymptoms.remove(symptom);
      } else {
        selectedSymptoms.add(symptom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Symptoms and Mood'),
        backgroundColor: Colors.pink[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text('Symptoms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // Display symptom checkboxes
            ...symptoms.map((symptom) {
              return CheckboxListTile(
                title: Text(symptom),
                value: selectedSymptoms.contains(symptom),
                onChanged: (bool? value) {
                  _toggleSymptom(symptom);
                },
              );
            }),

            SizedBox(height: 20),

            // Title for Mood
            Text('Mood', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // Display mood selection dropdown
            DropdownButton<String>(
              value: selectedMood,
              onChanged: (String? newMood) {
                setState(() {
                  selectedMood = newMood!;
                });
              },
              items: moods.map((String mood) {
                return DropdownMenuItem<String>(
                  value: mood,
                  child: Text(mood),
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Save or process the selected symptoms and mood
                  print('Selected Symptoms: $selectedSymptoms');
                  print('Selected Mood: $selectedMood');
                  // Optionally, navigate back to the previous screen or show a confirmation message
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, // Updated parameter
                ),
                child: Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
