import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

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
    final notificationService = Provider.of<FlutterLocalNotificationsPlugin>(context, listen: false);
    
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
                // Test Notification Button
                ElevatedButton(
                  onPressed: () async {
                    await _showTestNotification(notificationService);
                  },
                  child: Text('Test Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                // Schedule Notification Button
                ElevatedButton(
                  onPressed: () async {
                    await _scheduleTestNotification(notificationService);
                  },
                  child: Text('Schedule Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
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

  Future<void> _showTestNotification(FlutterLocalNotificationsPlugin notificationService) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await notificationService.show(
      3, // id
      'Test Notification', // title
      'This is a test notification to check if notifications are working.', // body
      platformChannelSpecifics, // details
      payload: 'test_notification', // payload
    );
  }

  Future<void> _scheduleTestNotification(FlutterLocalNotificationsPlugin notificationService) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'scheduled_test_channel',
      'Scheduled Test Channel',
      channelDescription: 'Channel for scheduled test notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await notificationService.zonedSchedule(
      4, // id
      'Scheduled Test', // title
      'This is a scheduled test notification.', // body
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)), // Scheduled time, 1 minute from now
      platformChannelSpecifics, // details
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}