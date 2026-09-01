import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'preferences_service.dart';

abstract class ReminderScheduler {
  Future<bool> schedule(
      {required String key,
      required String title,
      required String body,
      required DateTime at});
  Future<void> cancel(String key);
}

class NotificationService implements ReminderScheduler {
  NotificationService._();
  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  int notificationId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  Future<bool> _permission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    if (await android.areNotificationsEnabled() ?? false) return true;
    if (await PreferencesService.notificationPermissionAsked()) return false;
    await PreferencesService.markNotificationPermissionAsked();
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> schedule(
      {required String key,
      required String title,
      required String body,
      required DateTime at}) async {
    if (at.isBefore(DateTime.now()) || !await _permission()) return false;
    const details = NotificationDetails(
        android: AndroidNotificationDetails(
            'studymate_reminders', 'StudyMate reminders',
            channelDescription: 'Task, exam and academic reminders',
            importance: Importance.high,
            priority: Priority.high));
    await _plugin.zonedSchedule(notificationId(key), title, body,
        tz.TZDateTime.from(at.toUtc(), tz.UTC), details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: key);
    return true;
  }

  @override
  Future<void> cancel(String key) => _plugin.cancel(notificationId(key));
  Future<void> cancelAll() => _plugin.cancelAll();
}
