import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/mood_record_store.dart';
import '../domain/mood_record.dart';
import '../settings/app_settings.dart';

tz.Location resolveTimezoneLocation(String identifier) {
  final normalized = identifier.trim();
  if (normalized == 'GMT' || normalized == 'UTC' || normalized == 'Etc/UTC') {
    return tz.UTC;
  }
  try {
    return tz.getLocation(normalized);
  } on Object {
    return tz.UTC;
  }
}

class ReminderService {
  ReminderService(this._store);
  final MoodRecordStore _store;
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _settingsChannel = MethodChannel('mood_wave_tracker/settings');

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(resolveTimezoneLocation(zone.identifier));
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

  Future<bool> areNotificationsEnabled() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ??
      false;

  Future<void> openNotificationSettings() =>
      _settingsChannel.invokeMethod<void>('openNotificationSettings');

  Future<void> update(AppSettings settings) async {
    await _plugin.cancelAll();
    if (!settings.notificationsEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final japanese = settings.language == AppLanguage.japanese;
    final end = now.add(const Duration(days: 364));
    final recordedDates = (await _store.findBetween(now, end))
        .map((record) => MoodRecord.dateKey(record.date))
        .toSet();
    final schedules = <Future<void>>[];
    for (var offset = 0; offset < 365; offset++) {
      final day = now.add(Duration(days: offset));
      final target = tz.TZDateTime(tz.local, day.year, day.month, day.day,
          settings.notificationHour, settings.notificationMinute);
      if (!target.isAfter(now) ||
          recordedDates.contains(MoodRecord.dateKey(day))) {
        continue;
      }
      schedules.add(_plugin.zonedSchedule(
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
      ));
    }
    await Future.wait(schedules);
  }
}
