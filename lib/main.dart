import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/mood_record_repository.dart';
import 'notifications/reminder_service.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final recordStore = MoodRecordRepository();
  final settingsStore = SettingsStore(SharedPreferencesAsync());
  final settings =
      SettingsController(settingsStore, await settingsStore.load());
  final reminders = ReminderService(recordStore);
  await reminders.initialize();
  await reminders.update(settings.value);
  runApp(MoodWaveApp(
    store: recordStore,
    settings: settings,
    reminders: reminders,
  ));
}
