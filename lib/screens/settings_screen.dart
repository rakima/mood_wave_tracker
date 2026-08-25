import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../notifications/reminder_service.dart';
import '../settings/app_settings.dart';
import '../settings/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen(
      {required this.controller, required this.reminders, super.key});
  final SettingsController controller;
  final ReminderService reminders;

  Future<void> _update(AppSettings next) async {
    await controller.update(next);
    await reminders.update(next);
  }

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final strings = AppStrings(value.language);
    final sleepOptions = [for (var i = 0; i <= 48; i++) i / 2];
    return CustomScrollView(slivers: [
      SliverAppBar.large(title: Text(strings.settings)),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList.list(children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.t('平均睡眠時間', 'Average sleep time')),
            subtitle: Text(strings.t(
                '新しい記録の初期値に使います', 'Used as the default for new records')),
            trailing: DropdownButton<double>(
              value: value.averageSleepHours,
              items: sleepOptions
                  .map((hours) => DropdownMenuItem(
                        value: hours,
                        child: Text(
                            '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}h'),
                      ))
                  .toList(),
              onChanged: (hours) =>
                  _update(value.copyWith(averageSleepHours: hours)),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.t('言語', 'Language')),
            trailing: DropdownButton<AppLanguage>(
              value: value.language,
              items: const [
                DropdownMenuItem(
                    value: AppLanguage.japanese, child: Text('日本語')),
                DropdownMenuItem(
                    value: AppLanguage.english, child: Text('English')),
              ],
              onChanged: (language) =>
                  _update(value.copyWith(language: language)),
            ),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.t('記録リマインダー', 'Record reminder')),
            subtitle: Text(strings.t('指定時刻に未記録の場合のみ通知します',
                'Notifies only if today is not recorded')),
            value: value.notificationsEnabled,
            onChanged: (enabled) async {
              if (enabled && !await reminders.requestPermission()) return;
              await _update(value.copyWith(notificationsEnabled: enabled));
            },
          ),
          if (value.notificationsEnabled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.t('通知時間', 'Notification time')),
              trailing: TextButton(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                        hour: value.notificationHour,
                        minute: value.notificationMinute),
                  );
                  if (time != null) {
                    await _update(value.copyWith(
                        notificationHour: time.hour,
                        notificationMinute: time.minute));
                  }
                },
                child: Text(
                    '${value.notificationHour.toString().padLeft(2, '0')}:${value.notificationMinute.toString().padLeft(2, '0')}'),
              ),
            ),
        ]),
      ),
    ]);
  }
}
