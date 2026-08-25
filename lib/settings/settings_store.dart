import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsStore {
  SettingsStore(this._preferences);
  final SharedPreferencesAsync _preferences;

  static const _sleepKey = 'average_sleep_hours';
  static const _languageKey = 'language';
  static const _notificationsKey = 'notifications_enabled';
  static const _notificationHourKey = 'notification_hour';
  static const _notificationMinuteKey = 'notification_minute';

  Future<AppSettings> load() async => AppSettings(
        averageSleepHours: await _preferences.getDouble(_sleepKey) ?? 7,
        language: (await _preferences.getString(_languageKey)) == 'english'
            ? AppLanguage.english
            : AppLanguage.japanese,
        notificationsEnabled:
            await _preferences.getBool(_notificationsKey) ?? false,
        notificationHour: await _preferences.getInt(_notificationHourKey) ?? 21,
        notificationMinute:
            await _preferences.getInt(_notificationMinuteKey) ?? 0,
      );

  Future<void> save(AppSettings value) async {
    await Future.wait([
      _preferences.setDouble(_sleepKey, value.averageSleepHours),
      _preferences.setString(_languageKey, value.language.name),
      _preferences.setBool(_notificationsKey, value.notificationsEnabled),
      _preferences.setInt(_notificationHourKey, value.notificationHour),
      _preferences.setInt(_notificationMinuteKey, value.notificationMinute),
    ]);
  }
}
