import 'package:flutter/material.dart';

import 'data/mood_record_store.dart';
import 'l10n/app_strings.dart';
import 'notifications/reminder_service.dart';
import 'screens/chart_screen.dart';
import 'screens/history_screen.dart';
import 'screens/record_screen.dart';
import 'screens/settings_screen.dart';
import 'settings/settings_controller.dart';
import 'settings/app_settings.dart';

class MoodWaveApp extends StatelessWidget {
  const MoodWaveApp(
      {required this.store,
      required this.settings,
      required this.reminders,
      super.key});

  final MoodRecordStore store;
  final SettingsController settings;
  final ReminderService reminders;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: settings,
      builder: (context, child) => MaterialApp(
            title: 'Mood Wave Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: switch (settings.value.themeMode) {
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
              AppThemeMode.system => ThemeMode.system,
            },
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            home: HomeShell(
                store: store, settings: settings, reminders: reminders),
          ));

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff526d82),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell(
      {required this.store,
      required this.settings,
      required this.reminders,
      super.key});

  final MoodRecordStore store;
  final SettingsController settings;
  final ReminderService reminders;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _revision = 0;
  final _recordKey = GlobalKey<RecordScreenState>();

  void _saved() => setState(() => _revision++);

  void _edit(DateTime date) {
    _recordKey.currentState?.showDate(date);
    setState(() => _index = 0);
  }

  Future<void> _selectDestination(int index) async {
    if (index == _index) return;
    if (_index == 0 &&
        !(await (_recordKey.currentState?.confirmDiscard() ??
            Future.value(true)))) {
      return;
    }
    if (!mounted) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.settings.value.language);
    final screens = [
      RecordScreen(
        key: _recordKey,
        store: widget.store,
        initialDate: DateTime.now(),
        settings: widget.settings,
        reminders: widget.reminders,
        onSaved: _saved,
      ),
      ChartScreen(
        key: ValueKey('chart-$_revision'),
        store: widget.store,
        language: widget.settings.value.language,
      ),
      HistoryScreen(
        key: ValueKey('history-$_revision'),
        store: widget.store,
        language: widget.settings.value.language,
        onEdit: _edit,
      ),
      SettingsScreen(controller: widget.settings, reminders: widget.reminders),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: screens)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectDestination,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.edit_note), label: strings.record),
          NavigationDestination(
              icon: const Icon(Icons.show_chart), label: strings.chart),
          NavigationDestination(
              icon: const Icon(Icons.history), label: strings.history),
          NavigationDestination(
              icon: const Icon(Icons.settings), label: strings.settings),
        ],
      ),
    );
  }
}
