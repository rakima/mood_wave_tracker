import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_wave_tracker/data/mood_record_store.dart';
import 'package:mood_wave_tracker/domain/mood_record.dart';
import 'package:mood_wave_tracker/notifications/reminder_service.dart';
import 'package:mood_wave_tracker/screens/record_screen.dart';
import 'package:mood_wave_tracker/settings/app_settings.dart';
import 'package:mood_wave_tracker/settings/settings_controller.dart';
import 'package:mood_wave_tracker/widgets/level_selector.dart';

class _MemorySettings implements SettingsPersistence {
  @override
  Future<void> save(AppSettings value) async {}
}

class _MemoryRecordStore implements MoodRecordStore {
  @override
  Future<void> close() async {}
  @override
  Future<List<MoodRecord>> findAll() async => [];
  @override
  Future<List<MoodRecord>> findBetween(DateTime from, DateTime to) async => [];
  @override
  Future<MoodRecord?> findByDate(DateTime date) async => null;
  @override
  Future<void> save(MoodRecord record) async {}
}

void main() {
  testWidgets('強度をタップすると選択値が変わる', (tester) async {
    var selected = 0;
    await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
            builder: (context, setState) => LevelSelector(
                  label: '躁の強さ',
                  value: selected,
                  highColor: Colors.red,
                  onChanged: (value) => setState(() => selected = value),
                ))));
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(selected, 4);
  });

  testWidgets('当日は翌日ボタンを無効にする', (tester) async {
    final store = _MemoryRecordStore();
    final settings = SettingsController(_MemorySettings(), const AppSettings());
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RecordScreen(
      store: store,
      initialDate: DateTime.now(),
      settings: settings,
      reminders: ReminderService(store),
      onSaved: () {},
    ))));
    await tester.pump();
    final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right));
    expect(button.onPressed, isNull);
  });

  test('テーマ設定をcopyWithで保持・変更できる', () {
    const settings = AppSettings();
    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.copyWith(themeMode: AppThemeMode.dark).themeMode,
        AppThemeMode.dark);
  });
}
