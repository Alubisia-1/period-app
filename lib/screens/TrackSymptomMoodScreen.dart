import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../providers/user_provider.dart';

class TrackSymptomMoodScreen extends StatefulWidget {
  const TrackSymptomMoodScreen({super.key});

  @override
  _TrackSymptomMoodScreenState createState() => _TrackSymptomMoodScreenState();
}

class _TrackSymptomMoodScreenState extends State<TrackSymptomMoodScreen> {
  // Variables to track the selected symptoms and mood
  Set<String> selectedSymptoms = {};
  String? selectedMood;

  // Lists for custom items
  List<String> defaultSymptoms = ['Headache', 'Cramps', 'Nausea', 'Acne', 'Fatigue', 'Joint Pain'];
  List<String> defaultMoods = ['Happy', 'Sad', 'Tired', 'Anxious', 'Mood swings', 'Depressed'];
  List<String> customSymptoms = [];
  List<String> customMoods = [];

  // Method to add custom symptom
  void _addCustomSymptom(String newSymptom) {
    setState(() {
      if (!customSymptoms.contains(newSymptom.toLowerCase())) {
        customSymptoms.add(newSymptom.toLowerCase());
      }
    });
  }

  // Method to add custom mood
  void _addCustomMood(String newMood) {
    setState(() {
      if (!customMoods.contains(newMood.toLowerCase())) {
        customMoods.add(newMood.toLowerCase());
      }
    });
  }

  // Method to remove custom symptom
  void _removeCustomSymptom(String symptom) {
    setState(() {
      customSymptoms.remove(symptom);
      selectedSymptoms.remove(symptom);
    });
  }

  // Method to remove custom mood
  void _removeCustomMood(String mood) {
    setState(() {
      customMoods.remove(mood);
      if (selectedMood == mood) selectedMood = null;
    });
  }

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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
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
                _buildSection('Symptoms', [...defaultSymptoms, ...customSymptoms], _toggleSymptom, maxWidth, onAdd: _addCustomSymptom, onRemove: _removeCustomSymptom),
                SizedBox(height: 20),
                _buildSection('Mood', [...defaultMoods, ...customMoods], _selectMood, maxWidth, onAdd: _addCustomMood, onRemove: _removeCustomMood),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _saveData(userProvider);
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

  void _saveData(UserProvider userProvider) async {
    int? userId = userProvider.user?.id;

    if (userId != null) {
      final DatabaseService databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Save symptoms
      for (var symptom in selectedSymptoms) {
        await databaseService.insertSymptom({
          'date': DateTime.now().toIso8601String(),
          'symptom_name': symptom,
          'severity': 1, // You might want to allow for different severity levels
          'user_id': userId,
        });
      }

      // Save mood in daily_log
      await databaseService.updateDailyLog({
        'date': DateTime.now().toIso8601String(),
        'mood': selectedMood,
        'user_id': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to save data')),
      );
    }
  }

  Widget _buildSection(String title, List<String> items, Function(String) onItemTap, double maxWidth, {Function(String)? onAdd, Function(String)? onRemove}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto')),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                String newItem = '';
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Add New $title'),
                      content: TextField(
                        onChanged: (value) => newItem = value,
                        decoration: InputDecoration(hintText: "Enter new $title"),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Add'),
                          onPressed: () {
                            if (newItem.isNotEmpty) {
                              if (title == 'Symptoms') {
                                onAdd?.call(newItem);
                              } else if (title == 'Mood') {
                                onAdd?.call(newItem);
                              }
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8.0, // space between items horizontally
          runSpacing: 8.0, // space between items vertically
          children: items.map((item) {
            return SizedBox(
              width: (maxWidth - 32) / 2, // Subtracting padding and spacing
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item, style: TextStyle(fontFamily: 'Roboto')),
                    ),
                    if (title == 'Symptoms' && customSymptoms.contains(item) || title == 'Mood' && customMoods.contains(item))
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => onRemove?.call(item),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.close, color: Colors.red, size: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}