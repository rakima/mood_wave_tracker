import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'settings_controller.dart';

class SettingsStore implements SettingsPersistence {
  SettingsStore(this._preferences);
  final SharedPreferencesAsync _preferences;

  static const _sleepKey = 'average_sleep_hours';
  static const _languageKey = 'language';
  static const _notificationsKey = 'notifications_enabled';
  static const _notificationHourKey = 'notification_hour';
  static const _notificationMinuteKey = 'notification_minute';
  static const _themeKey = 'theme_mode';

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
        themeMode: await _loadTheme(),
      );

  Future<AppThemeMode> _loadTheme() async {
    final stored = await _preferences.getString(_themeKey) ?? 'system';
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => AppThemeMode.system,
    );
  }

  @override
  Future<void> save(AppSettings value) async {
    await Future.wait([
      _preferences.setDouble(_sleepKey, value.averageSleepHours),
      _preferences.setString(_languageKey, value.language.name),
      _preferences.setBool(_notificationsKey, value.notificationsEnabled),
      _preferences.setInt(_notificationHourKey, value.notificationHour),
      _preferences.setInt(_notificationMinuteKey, value.notificationMinute),
      _preferences.setString(_themeKey, value.themeMode.name),
    ]);
  }
}
