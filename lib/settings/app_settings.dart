enum AppLanguage { japanese, english }

class AppSettings {
  const AppSettings({
    this.averageSleepHours = 7,
    this.language = AppLanguage.japanese,
    this.notificationsEnabled = false,
    this.notificationHour = 21,
    this.notificationMinute = 0,
  });

  final double averageSleepHours;
  final AppLanguage language;
  final bool notificationsEnabled;
  final int notificationHour;
  final int notificationMinute;

  AppSettings copyWith({
    double? averageSleepHours,
    AppLanguage? language,
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
  }) =>
      AppSettings(
        averageSleepHours: averageSleepHours ?? this.averageSleepHours,
        language: language ?? this.language,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        notificationHour: notificationHour ?? this.notificationHour,
        notificationMinute: notificationMinute ?? this.notificationMinute,
      );
}
