import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../notifications/reminder_service.dart';
import '../settings/app_settings.dart';
import '../settings/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(
      {required this.controller, required this.reminders, super.key});
  final SettingsController controller;
  final ReminderService reminders;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool? _permissionGranted;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final enabled = await widget.reminders.areNotificationsEnabled();
    if (mounted) setState(() => _permissionGranted = enabled);
  }

  Future<void> _update(AppSettings next) async {
    await widget.controller.update(next);
    await widget.reminders.update(next);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final s = AppStrings(value.language);
    final sleepOptions = [for (var i = 0; i <= 48; i++) i / 2];
    return CustomScrollView(slivers: [
      SliverAppBar.large(title: Text(s.settings)),
      SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(children: [
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('平均睡眠時間', 'Average sleep time')),
                subtitle: Text(s.t(
                    '新しい記録の初期値に使います', 'Used as the default for new records')),
                trailing: DropdownButton<double>(
                    value: value.averageSleepHours,
                    items: sleepOptions
                        .map((h) => DropdownMenuItem(
                            value: h,
                            child: Text(
                                '${h.toStringAsFixed(h % 1 == 0 ? 0 : 1)}h')))
                        .toList(),
                    onChanged: (h) =>
                        _update(value.copyWith(averageSleepHours: h)))),
            const Divider(),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('言語', 'Language')),
                trailing: DropdownButton<AppLanguage>(
                    value: value.language,
                    items: const [
                      DropdownMenuItem(
                          value: AppLanguage.japanese, child: Text('日本語')),
                      DropdownMenuItem(
                          value: AppLanguage.english, child: Text('English')),
                    ],
                    onChanged: (language) =>
                        _update(value.copyWith(language: language)))),
            const Divider(),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('テーマ', 'Theme')),
                trailing: DropdownButton<AppThemeMode>(
                    value: value.themeMode,
                    items: [
                      DropdownMenuItem(
                          value: AppThemeMode.system,
                          child: Text(s.t('端末設定', 'System'))),
                      DropdownMenuItem(
                          value: AppThemeMode.light,
                          child: Text(s.t('ライト', 'Light'))),
                      DropdownMenuItem(
                          value: AppThemeMode.dark,
                          child: Text(s.t('ダーク', 'Dark'))),
                    ],
                    onChanged: (mode) =>
                        _update(value.copyWith(themeMode: mode)))),
            const Divider(),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('記録リマインダー', 'Record reminder')),
                subtitle: Text(s.t('指定時刻に未記録の場合のみ通知します',
                    'Notifies only if today is not recorded')),
                value: value.notificationsEnabled,
                onChanged: (enabled) async {
                  if (enabled && !await widget.reminders.requestPermission()) {
                    await _refreshPermission();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(s.t('通知権限が許可されていません',
                              'Notification permission is not granted'))));
                    }
                    return;
                  }
                  await _refreshPermission();
                  await _update(value.copyWith(notificationsEnabled: enabled));
                }),
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('通知権限', 'Notification permission')),
                subtitle: Text(_permissionGranted == true
                    ? s.t('許可済み', 'Granted')
                    : s.t('未許可', 'Not granted')),
                trailing: _permissionGranted == true
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : TextButton(
                        onPressed: widget.reminders.openNotificationSettings,
                        child: Text(s.t('端末設定を開く', 'Open settings')))),
            if (value.notificationsEnabled)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.t('通知時間', 'Notification time')),
                  trailing: TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                                hour: value.notificationHour,
                                minute: value.notificationMinute));
                        if (time != null) {
                          await _update(value.copyWith(
                              notificationHour: time.hour,
                              notificationMinute: time.minute));
                        }
                      },
                      child: Text(
                          '${value.notificationHour.toString().padLeft(2, '0')}:${value.notificationMinute.toString().padLeft(2, '0')}'))),
          ])),
    ]);
  }
}
