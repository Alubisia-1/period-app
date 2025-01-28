import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/database_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final DatabaseService _databaseService;

  NotificationService(this._flutterLocalNotificationsPlugin, this._databaseService);

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

    // Store the notification
    await _databaseService.insertNotification({
      'title': 'Period Reminder',
      'body': 'Your next period is predicted to start soon. Prepare accordingly!',
      'is_read': 0,
      'user_id': 1, // Assuming user ID 1, replace with dynamic user ID
    });
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
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Store the notification
    await _databaseService.insertNotification({
      'title': 'Daily Logging',
      'body': 'Don\'t forget to log your symptoms and mood today!',
      'is_read': 0,
      'user_id': 1, // Assuming user ID 1, replace with dynamic user ID
    });
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
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Store the notification
    await _databaseService.insertNotification({
      'title': 'Temperature Reminder',
      'body': 'Time to log your basal body temperature!',
      'is_read': 0,
      'user_id': 1, // Assuming user ID 1, replace with dynamic user ID
    });
  }

  // Made public by removing the underscore
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      3,
      'Test Notification',
      'This is a test notification to check if notifications are working.',
      platformChannelSpecifics,
      payload: 'test_notification',
    );

    // Store the notification
    await _databaseService.insertNotification({
      'title': 'Test Notification',
      'body': 'This is a test notification to check if notifications are working.',
      'is_read': 0,
      'user_id': 1, // Assuming user ID 1, replace with dynamic user ID
    });
  }

  // Made public by removing the underscore
  Future<void> scheduleTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'scheduled_test_channel',
      'Scheduled Test Channel',
      channelDescription: 'Channel for scheduled test notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      4,
      'Scheduled Test',
      'This is a scheduled test notification.',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Store the notification
    await _databaseService.insertNotification({
      'title': 'Scheduled Test',
      'body': 'This is a scheduled test notification.',
      'is_read': 0,
      'user_id': 1, // Assuming user ID 1, replace with dynamic user ID
    });
  }

  Future<void> insertNotification(Map<String, dynamic> notificationData) async {
    await _databaseService.insertNotification(notificationData);
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(int userId) async {
    return await _databaseService.fetchNotifications(userId);
  }

  Future<void> deleteNotification(int notificationId) async {
    await _databaseService.deleteNotification(notificationId);
  }

  Future<void> markAsRead(int notificationId) async {
    await _databaseService.markNotificationAsRead(notificationId);
  }
}