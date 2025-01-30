import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  DateTime _dateOfBirth = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _dateOfBirth,
        firstDate: DateTime(1900, 1, 1),
        lastDate: DateTime.now());
    if (picked != null && picked != _dateOfBirth)
      setState(() {
        _dateOfBirth = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    // Use Provider.of<DatabaseService?> to allow for null values
    final databaseService = Provider.of<DatabaseService?>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Registration', style: TextStyle(color: Colors.black, fontFamily: 'Roboto')),
        backgroundColor: Colors.pink[50],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(_dateOfBirth)),
                    validator: (value) {
                      if (_dateOfBirth == DateTime.now()) {
                        return 'Please select your date of birth';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // Check if databaseService is not null before using it
                      if (databaseService != null) {
                        await databaseService.insertUser({
                          'name': _name,
                          'date_of_birth': DateFormat('yyyy-MM-dd').format(_dateOfBirth),
                          'cycle_average': 28, // Default value, can be adjusted later
                        });
                        // Navigate to the home screen or show a success message
                        Navigator.of(context).pushReplacementNamed('/home');
                      } else {
                        // Handle case where databaseService is null, for example, show an error or use another method for web
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registration failed: Database service unavailable.')),
                        );
                      }
                    }
                  },
                  child: Text('Register'),
                  style: ElevatedButton.styleFrom(
                    // Replace 'primary' with 'backgroundColor'
                    backgroundColor: Colors.pink,
                    // Replace 'onPrimary' with 'foregroundColor'
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}