import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/mood_record_store.dart';
import '../settings/app_settings.dart';

class ReminderService {
  ReminderService(this._store);
  final MoodRecordStore _store;
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<bool> requestPermission() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission() ??
      false;

  Future<void> update(AppSettings settings) async {
    await _plugin.cancelAll();
    if (!settings.notificationsEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final japanese = settings.language == AppLanguage.japanese;
    for (var offset = 0; offset < 30; offset++) {
      final day = now.add(Duration(days: offset));
      final target = tz.TZDateTime(tz.local, day.year, day.month, day.day,
          settings.notificationHour, settings.notificationMinute);
      if (!target.isAfter(now) || await _store.findByDate(day) != null) {
        continue;
      }
      await _plugin.zonedSchedule(
        id: target.year * 10000 + target.month * 100 + target.day,
        title: japanese ? '今日の記録' : "Today's record",
        body: japanese
            ? '今日の状態を記録しませんか？'
            : 'Would you like to record how you feel today?',
        scheduledDate: target,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_record_reminder',
            'Daily record reminder',
            channelDescription:
                'Reminds you only when today has not been recorded',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
