import 'package:flutter/material.dart';

class TrackSymptomMoodScreen extends StatefulWidget {
  const TrackSymptomMoodScreen({super.key});

  @override
  _TrackSymptomMoodScreenState createState() => _TrackSymptomMoodScreenState();
}

class _TrackSymptomMoodScreenState extends State<TrackSymptomMoodScreen> {
  // Variables to track the selected symptoms and mood
  Set<String> selectedSymptoms = {};
  String? selectedMood;

  // Sample list of symptoms
  final List<String> symptoms = [
    'Headache', 'Cramps', 'Nausea', 'Acne', 'Fatigue', 'Joint Pain'
  ];

  // Sample list of moods
  final List<String> moods = ['Happy', 'Sad', 'Tired', 'Anxious', 'Mood swings', 'Depressed'];

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

  // Method to update the selected mood
  void _selectMood(String mood) {
    setState(() {
      selectedMood = mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;
    // Define a maximum width, for example, 600
    double maxWidth = screenWidth > 600 ? 600 : screenWidth * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Symptoms and Mood'),
        backgroundColor: Colors.pink[200],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Symptoms', symptoms, _toggleSymptom),
                SizedBox(height: 20),
                _buildSection('Mood', moods, _selectMood),
                SizedBox(height: 20),
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
                      backgroundColor: Colors.pink,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Save', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, Function(String) onItemTap) {
    return Column(
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
                      onPressed: () => onItemTap(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: title == 'Mood' 
                          ? (selectedMood == item ? Color(0xFFEC407A) : Colors.pink[100])
                          : (selectedSymptoms.contains(item) ? Color(0xFFEC407A) : Colors.pink[100]),
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
  }
}