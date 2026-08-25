import 'package:flutter/material.dart';

import 'data/mood_record_store.dart';
import 'l10n/app_strings.dart';
import 'notifications/reminder_service.dart';
import 'screens/chart_screen.dart';
import 'screens/history_screen.dart';
import 'screens/record_screen.dart';
import 'screens/settings_screen.dart';
import 'settings/settings_controller.dart';

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
            themeMode: ThemeMode.system,
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
  DateTime _editingDate = DateTime.now();

  void _saved() => setState(() => _revision++);

  void _edit(DateTime date) => setState(() {
        _editingDate = date;
        _index = 0;
      });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.settings.value.language);
    final screens = [
      RecordScreen(
        key: ValueKey('record-${_editingDate.toIso8601String()}'),
        store: widget.store,
        initialDate: _editingDate,
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
        onDestinationSelected: (index) => setState(() {
          _index = index;
          if (index == 0) _editingDate = DateTime.now();
        }),
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
