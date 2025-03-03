import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/database_service.dart';
import '../providers/user_provider.dart'; 

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final DatabaseService? _databaseService;
  final UserProvider? _userProvider;

  NotificationService(this._flutterLocalNotificationsPlugin, this._databaseService, this._userProvider);

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showPeriodReminderNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'period_channel',
      'Period Notifications',
      channelDescription: 'Notifications related to your menstrual cycle',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Period Reminder',
      'Your next period is predicted to start soon. Prepare accordingly!',
      platformChannelSpecifics,
      payload: 'period_reminder',
    );

    // Store the notification if _databaseService and _userProvider are not null
    if (_databaseService != null && _userProvider != null) {
      int? userId = _userProvider.user?.id;
      if (userId != null) {
        await _databaseService.insertNotification({
          'title': 'Period Reminder',
          'body': 'Your next period is predicted to start soon. Prepare accordingly!',
          'is_read': 0,
          'user_id': userId,
        });
      }
    }
  }

Future<void> scheduleDailyLoggingReminder() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'daily_log_channel',
    'Daily Logging',
    channelDescription: 'Remind you to log your daily symptoms and mood',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  await _flutterLocalNotificationsPlugin.zonedSchedule(
    1,
    'Daily Logging',
    'Don\'t forget to log your symptoms and mood today!',
    tz.TZDateTime.now(tz.local).add(const Duration(days: 1)),
    platformChannelSpecifics,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
    androidScheduleMode: AndroidScheduleMode.exact,  // Add this line
  );

    // Store the notification if _databaseService and _userProvider are not null
    if (_databaseService != null && _userProvider != null) {
      int? userId = _userProvider.user?.id;
      if (userId != null) {
        await _databaseService.insertNotification({
          'title': 'Daily Logging',
          'body': 'Don\'t forget to log your symptoms and mood today!',
          'is_read': 0,
          'user_id': userId,
        });
      }
    }
  }

Future<void> scheduleTemperatureReminder() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'temperature_channel',
    'Temperature Tracking',
    channelDescription: 'Remind you to track your temperature',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  // Schedule for 7 AM every day, assuming basal temperature is taken in the morning
  await _flutterLocalNotificationsPlugin.zonedSchedule(
    2,
    'Temperature Reminder',
    'Time to log your basal body temperature!',
    tz.TZDateTime(tz.local, DateTime.now().year, DateTime.now().month, DateTime.now().day, 7, 0),
    platformChannelSpecifics,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
    androidScheduleMode: AndroidScheduleMode.exact,  // Add this line
  );

    // Store the notification if _databaseService and _userProvider are not null
    if (_databaseService != null && _userProvider != null) {
      int? userId = _userProvider.user?.id;
      if (userId != null) {
        await _databaseService.insertNotification({
          'title': 'Temperature Reminder',
          'body': 'Time to log your basal body temperature!',
          'is_read': 0,
          'user_id': userId,
        });
      }
    }
  }

  Future<void> insertNotification(Map<String, dynamic> notificationData) async {
    if (_databaseService != null && _userProvider != null) {
      int? userId = _userProvider.user?.id;
      if (userId != null) {
        notificationData['user_id'] = userId;
        await _databaseService.insertNotification(notificationData);
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(int userId) async {
    if (_databaseService != null) {
      return await _databaseService.fetchNotifications(userId);
    }
    return []; // Return an empty list if _databaseService is null
  }

  Future<void> deleteNotification(int notificationId) async {
    if (_databaseService != null) {
      await _databaseService.deleteNotification(notificationId);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    if (_databaseService != null) {
      await _databaseService.markNotificationAsRead(notificationId);
    }
  }
}