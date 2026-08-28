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

  Future<void> _showPrivacyPolicy(AppStrings s) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.t('プライバシーポリシー', 'Privacy policy')),
          content: SingleChildScrollView(
            child: SelectableText(s.t(
              'Mood Waveは、入力した躁・鬱の強さ、睡眠時間、服薬状況、メモを端末内のSQLiteに保存します。設定内容は端末内のアプリ設定に保存します。\n\n'
              '本アプリは、開発者のサーバーへの送信、広告、アクセス解析、クラッシュ収集を行いません。Androidのバックアップ設定が有効な場合、記録と設定はAndroid Auto Backupにより暗号化され、Googleアカウントのバックアップ領域へ保存されることがあります。バックアップと復元はAndroid OSが管理します。\n\n'
              '通知を有効にした場合、未記録時のリマインダーを端末内で予約します。通知以外の機密性の高いAndroid権限は使用しません。\n\n'
              '本アプリは日々の状態を記録・可視化するためのツールです。医療機器ではなく、いかなる疾患の診断、治療、治癒、予防も行いません。医療上の助言、診断、治療については医療専門家へ相談してください。',
              'Mood Wave stores the mania and depression intensity, sleep duration, medication status, and notes you enter in SQLite on your device. App preferences are stored locally on your device.\n\n'
              'The app does not send data to a developer server and contains no advertising, analytics, or crash-reporting service. If Android backup is enabled, records and settings may be encrypted and stored in your Google Account backup by Android Auto Backup. Backup and restoration are managed by Android OS.\n\n'
              'If reminders are enabled, the app schedules unrecorded-day reminders locally. It does not use sensitive Android permissions other than notifications.\n\n'
              'This app is a tool for recording and visualizing daily conditions. It is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Consult a healthcare professional for medical advice, diagnosis, or treatment.',
            )),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.t('閉じる', 'Close')),
            ),
          ],
        ),
      );

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
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(s.t('プライバシーポリシー', 'Privacy policy')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrivacyPolicy(s),
            ),
          ])),
    ]);
  }
}
