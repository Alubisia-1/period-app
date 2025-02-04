import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/user_provider.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  @override
  _NotificationsSettingsScreenState createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _periodReminderEnabled = true;
  bool _dailyLogReminderEnabled = true;
  bool _temperatureReminderEnabled = true;
  TimeOfDay _temperatureReminderTime = TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int? userId = userProvider.user?.id;
    
    // Get the screen width to adjust padding based on screen size
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = screenWidth > 600 ? 32.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings', style: TextStyle(color: Colors.black, fontFamily: 'Roboto')),
        backgroundColor: Colors.pink[50],
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600), // Limits the width to 600 or less
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSettingSwitch('Period Reminder', 'Get reminders for your next period.', _periodReminderEnabled, (value) {
                  setState(() {
                    _periodReminderEnabled = value;
                  });
                }),
                SizedBox(height: 20),
                _buildSettingSwitch('Daily Log Reminder', 'Remind me to log symptoms and mood daily.', _dailyLogReminderEnabled, (value) {
                  setState(() {
                    _dailyLogReminderEnabled = value;
                  });
                }),
                SizedBox(height: 20),
                _buildTimePicker('Temperature Reminder Time', 'Set the time for your daily temperature reminder.', _temperatureReminderTime, (time) {
                  setState(() {
                    _temperatureReminderTime = time;
                  });
                }),
                SizedBox(height: 20),
                // Display Notifications Section
                if (userId != null)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: notificationService.fetchNotifications(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No notifications yet.'));
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recent Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                var notification = snapshot.data![index];
                                return ListTile(
                                  title: Text(notification['title'], style: TextStyle(fontWeight: notification['is_read'] == 0 ? FontWeight.bold : FontWeight.normal)),
                                  subtitle: Text(notification['body']),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await notificationService.deleteNotification(notification['id']);
                                      setState(() {});
                                    },
                                  ),
                                  onTap: () async {
                                    await notificationService.markAsRead(notification['id']);
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      }
                    },
                  )
                else
                  Center(child: Text('Please log in to view notifications.')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontFamily: 'Roboto')),
      subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Roboto', color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.pink,
    );
  }

  Widget _buildTimePicker(String title, String subtitle, TimeOfDay initialTime, Function(TimeOfDay) onTimeSelected) {
    return ListTile(
      title: Text(title, style: TextStyle(fontFamily: 'Roboto')),
      subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Roboto', color: Colors.grey[600])),
      trailing: Text(
        _temperatureReminderTime.format(context),
        style: TextStyle(fontFamily: 'Roboto'),
      ),
      onTap: () async {
        TimeOfDay? newTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (newTime != null) {
          onTimeSelected(newTime);
        }
      },
    );
  }
}