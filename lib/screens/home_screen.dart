import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../logic/prediction_algorithm.dart';
import '../services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';
import './analytics_dashboard.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import '../services/backup_service.dart';
import 'package:provider/provider.dart';
import './notifications_settings_screen.dart';
import '../models/user.dart';
import 'package:period_tracker_app/providers/user_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final BackupService backupService = BackupService();
  final _logger = Logger('HomeScreen');
 BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  
  // Define color scheme for consistency
  static const Color primaryColor = Color(0xFFE91E63); // Pink color
  static const Color accentColor = Color(0xFFF8BBD0); // Light pink
  static const Color highlightedColor = Color(0xFFEC407A); 

  String? _currentMood;
  final Set _selectedSymptoms = {};

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _createBannerAd();
  }

  void _createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _logger.warning('Banner ad failed to load: $error');
        },
      ),
    );
    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsSettingsScreen()),
            );
          },
          tooltip: 'Notifications',
        ),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.black),
            onPressed: () {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              if (userProvider.isLoggedIn) {
                _showUserProfile(context); // You need to implement this method
              } else {
                _showAccountDialog(context);
              }
            },
            tooltip: 'Account',
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
                if (_isBannerAdReady)
                  Container(
                    width: _bannerAd.size.width.toDouble(),
                    height: _bannerAd.size.height.toDouble(),
                    alignment: Alignment.bottomCenter,
                    margin: EdgeInsets.only(top: 20),
                    child: AdWidget(ad: _bannerAd),
                ),
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
  // Capture the necessary data before entering an async block
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(button.size.topRight(Offset.zero), ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  // Use the captured position without context inside the async block
  await showMenu(
    context: context,
    position: position,
    items: [
      PopupMenuItem(
        value: 'backup',
        child: Text('Backup Data'),
      ),
      PopupMenuItem(
        value: 'restore',
        child: Text('Restore Data'),
      ),
    ],
    elevation: 8.0,
  ).then((String? value) {
    if (context.mounted) {  // Check if context is still mounted
      if (value == 'backup') {
        _handleBackup(context);
      } else if (value == 'restore') {
        _handleRestore(context);
      }
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spread items out
          children: [
            // Flow button on the far left with some padding
            Padding(
              padding: const EdgeInsets.only(left: 4.0), // Adjust this value for more or less spacing
              child: _buildQuickLogButton(context, Icons.bloodtype, 'Flow'),
            ),
            // View Full Log button on the right without taking extra space
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
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
            ),
          ],
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
            color: Colors.grey.withValues(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.3 * 255), // Correct use of named arguments
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
            content: SizedBox(
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
          title: Text('Connect Bluetooth device'),
          content: Text('Ensure your Bluetooth printer is paired via your device\'s Bluetooth settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog before proceeding
              await _requestBluetoothPermissionsAndConnect(context);
            },
            child: Text('Proceed'),
          ),
          ],
        ),
      );
    }
      Future<void> _requestBluetoothPermissionsAndConnect(BuildContext context) async {
    // Define required permissions based on Android version
    List<Permission> permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    // Request permissions
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    if (statuses[Permission.bluetooth]!.isDenied ||
        statuses[Permission.bluetoothScan]!.isDenied ||
        statuses[Permission.bluetoothConnect]!.isDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bluetooth permissions are required to connect to the printer.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(), // Open app settings if denied
            ),
          ),
        );
      }
      return;
    }

    // Permissions granted, proceed to connect
    await _connectToThermometer(context);
  }
 Future<void> _connectToThermometer(BuildContext context) async {
    String deviceAddress = "00:11:22:33:44:55"; // Replace with actual address or make configurable

    try {
      bool isConnected = await bluetoothPrint.isConnected ?? false;
      if (!isConnected) {
        await bluetoothPrint.startScan(timeout: Duration(seconds: 4));
        List<BluetoothDevice> devices = await bluetoothPrint.scanResults.first;

        if (devices.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No Bluetooth devices found.')),
            );
          }
          return;
        }

        BluetoothDevice? targetDevice = devices.firstWhere(
          (device) => device.address == deviceAddress,
          orElse: () => devices.first, // Fallback to first device
        );
        _logger.info('Connecting to device: ${targetDevice.name} (${targetDevice.address})');
        await bluetoothPrint.connect(targetDevice);
      }

      if (await bluetoothPrint.isConnected == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to printer.')),
          );
        }
        List<LineText> testPrint = [
          LineText(type: LineText.TYPE_TEXT, content: "Test Print\n", align: LineText.ALIGN_CENTER),
          LineText(type: LineText.TYPE_TEXT, content: "Period Tracker App\n"),
        ];
        await bluetoothPrint.printReceipt({}, testPrint);
      } else {
        throw Exception('Connection failed');
      }
    } catch (e) {
      _logger.warning('Failed to connect to printer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to printer: $e')),
        );
      }
    } finally {
      await bluetoothPrint.stopScan();
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
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  int userId = userProvider.user?.id ?? 0; // Assuming a default or handling no user login

  await dbService.insertDailyLog({
    'temperature': temp,
    'date': DateTime.now().toIso8601String(),
    'user_id': userId,
  });
}

  void _showFlowOptions(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Text('Log Flow Intensity', style: TextStyle(fontFamily: 'Roboto')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.water_drop, color: Colors.lightBlue),
              title: Text('Light', style: TextStyle(fontFamily: 'Roboto')),
              onTap: () => _logFlow(context, 'Light'),
            ),
            ListTile(
              leading: Icon(Icons.water_drop, color: Colors.blue),
              title: Text('Medium', style: TextStyle(fontFamily: 'Roboto')),
              onTap: () => _logFlow(context, 'Medium'),
            ),
            ListTile(
              leading: Icon(Icons.water_drop, color: Colors.deepPurple),
              title: Text('Heavy', style: TextStyle(fontFamily: 'Roboto')),
              onTap: () => _logFlow(context, 'Heavy'),
            ),
          ],
        ),
      );
    },
  );
}
void _logFlow(BuildContext context, String flowLevel) async {
  final dbService = DatabaseService();
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  int userId = userProvider.user?.id ?? 0;

  await dbService.insertDailyLog({
    'flow_level': flowLevel,
    'date': DateTime.now().toIso8601String(),
    'user_id': userId,
  });

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Flow logged as $flowLevel')),
    );
    Navigator.pop(context); // Close the dialog after logging
  }
}

void _showAccountDialog(BuildContext context) {
  bool isLogin = true;
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isLogin ? 'Login' : 'Register', style: TextStyle(fontFamily: 'Roboto')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show Full Name field for both login and register
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(isLogin ? 'Switch to Register' : 'Switch to Login', style: TextStyle(fontFamily: 'Roboto')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isLogin) {
                      _login(fullNameController.text, passwordController.text);
                    } else {
                      _register(passwordController.text, fullNameController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isLogin ? 'Login' : 'Register', style: TextStyle(fontFamily: 'Roboto')),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
void _login(String fullName, String password) async {
  final dbService = DatabaseService();
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  try {
    // Await the database Future to get the Database object, then call query
    final db = await dbService.database; // Resolve the Future<Database>
    final users = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: [fullName],
    );

    if (users.isNotEmpty) {
      final userId = users.first['id'] as int?; // Use int? to match the updated User model
      if (userId != null) {
        // Use verifyUserPassword to securely verify the password
        bool isPasswordValid = await dbService.verifyUserPassword(userId.toString(), password);
        if (isPasswordValid) {
          User user = User(
            id: userId, // Use the int ID directly
            fullName: fullName,
          );

          userProvider.login(user); // Update the UserProvider with the logged-in user
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login successful! Welcome, ${user.fullName}')),
            );
            Navigator.of(context).pop(); // Close dialog
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login failed. Incorrect name or password.')),
            );
          }
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed. User not found.')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during login: $e')),
      );
    }
  }
}
void _register(String password, String fullName) async {
  final dbService = DatabaseService();
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  try {
    final db = await dbService.database;
    List<Map<String, dynamic>> existingUsers = await db.query('users', where: 'name = ?', whereArgs: [fullName]);

    if (existingUsers.isEmpty) {
      await dbService.insertUser({
        'password': password,
        'name': fullName,
        'date_of_birth': '1900-01-01',
        'cycle_average': 28,
      });

      // Query the newly inserted user to get the ID
      final newUsers = await db.query('users', where: 'name = ?', whereArgs: [fullName]);
      if (newUsers.isNotEmpty) {
        final userId = newUsers.first['id'] as int?;
        if (userId != null) {
          User newUser = User(
            id: userId,
            fullName: fullName,
          );

          userProvider.login(newUser); // Log the new user in immediately after registration

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registration successful! You can now log in.')),
            );
            Navigator.of(context).pop(); // Close dialog
          }
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed. User already exists.')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during registration: $e')),
      );
    }
  }
}
void _showUserProfile(BuildContext context) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Profile'),
        content: Text('Welcome, ${userProvider.user?.fullName}'),
        actions: <Widget>[
          TextButton(
            child: Text('Logout'),
            onPressed: () {
              userProvider.logout();
              Navigator.of(context).pop(); // Close dialog
            },
          ),
        ],
      );
    },
  );
}

Widget _buildQuickLogButton(BuildContext context, IconData icon, String label) => ElevatedButton(
      onPressed: () {
        if (label == 'Flow') {
          _showFlowOptions(context);
        } else {
          // If it's not Flow, handle other buttons here if needed
        }
      },
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

Widget _buildSymptomColumn() {
  return _buildColumnSection('Symptoms', ['Headache', 'Cramps', 'Nausea', 'Bloating'], 
      onItemTap: (item) => _toggleSymptom(item));
}

void _toggleSymptom(String symptom) async {
  setState(() {
    if (_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      _selectedSymptoms.add(symptom);
    }
  });

  final dbService = DatabaseService();
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  int userId = userProvider.user?.id ?? 0;

  await dbService.insertSymptom({
    'date': DateTime.now().toIso8601String(),
    'symptom_name': symptom,
    'severity': 1,
    'user_id': userId,
  });

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_selectedSymptoms.contains(symptom) ? 'Logged $symptom' : 'Removed $symptom')),
    );
  }
}

Widget _buildMoodColumn() {
  return _buildColumnSection('Mood', ['Happy', 'Sad', 'Irritable', 'Anxious'], 
      onItemTap: (item) => _logMood(context, item));
}

void _logMood(BuildContext context, String mood) async {
  setState(() {
    _currentMood = mood;
  });
  final dbService = DatabaseService();
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  int userId = userProvider.user?.id ?? 0;

  await dbService.updateDailyLog({
    'date': DateTime.now().toIso8601String(),
    'mood': mood,
    'user_id': userId,
  });

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged mood: $mood')),
    );
  }
}
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

  Widget _buildColumnSection(String title, List<String> items, {Function(String)? onItemTap}) => Column(
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
                    onPressed: () => onItemTap?.call(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: title == 'Mood' 
                        ? (_currentMood == item ? highlightedColor : accentColor)
                        : (_selectedSymptoms.contains(item) ? highlightedColor : accentColor),
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
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  int userId = userProvider.user?.id ?? 0;
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
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(fontFamily: 'Roboto')),
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