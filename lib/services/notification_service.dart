import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_10y.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'daily_vocab_reminder';
  static const _channelName = 'Daily Vocab Reminder';
  static const _notifId = 1;
  static const _keyEnabled = 'notif_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    if (value) {
      await requestPermission();
      await scheduleDailyReminder();
    } else {
      await cancel();
    }
  }

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    await _createChannel();

    // only schedule if the user has opted in
    if (await isEnabled()) {
      await scheduleDailyReminder();
    }
  }

  static Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily reminder to check the word of the day',
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  static Future<void> scheduleDailyReminder() async {
    await _plugin.cancel(_notifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8, // 8:00 AM
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notifId,
      'co:fe — word of the day',
      'your daily word is waiting ☕',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          icon: '@mipmap/ic_launcher',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    await _plugin.cancel(_notifId);
  }

  // For debug: show an immediate test notification
  static Future<void> showTestNotification() async {
    await _plugin.show(
      99,
      'co:fe — test notification',
      'notifications are working ✅',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> setTimeZone(String timeZoneName) async {
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // fall back to UTC if unknown zone
    }
  }
}

// Helper widget to request notification permission on first launch
class NotificationPermissionRequester extends StatefulWidget {
  final Widget child;
  const NotificationPermissionRequester({super.key, required this.child});

  @override
  State<NotificationPermissionRequester> createState() =>
      _NotificationPermissionRequesterState();
}

class _NotificationPermissionRequesterState
    extends State<NotificationPermissionRequester> {
  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    await NotificationService.requestPermission();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
