import 'package:flutter/material.dart';

import 'data/mood_record_store.dart';
import 'screens/chart_screen.dart';
import 'screens/history_screen.dart';
import 'screens/record_screen.dart';

class MoodWaveApp extends StatelessWidget {
  const MoodWaveApp({required this.store, super.key});

  final MoodRecordStore store;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mood Wave Tracker',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: HomeShell(store: store),
      );

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
  const HomeShell({required this.store, super.key});

  final MoodRecordStore store;

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
    final screens = [
      RecordScreen(
        key: ValueKey('record-${_editingDate.toIso8601String()}-$_revision'),
        store: widget.store,
        date: _editingDate,
        onSaved: _saved,
      ),
      ChartScreen(
        key: ValueKey('chart-$_revision'),
        store: widget.store,
      ),
      HistoryScreen(
        key: ValueKey('history-$_revision'),
        store: widget.store,
        onEdit: _edit,
      ),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: screens)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() {
          _index = index;
          if (index == 0) _editingDate = DateTime.now();
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit_note), label: '記録'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'グラフ'),
          NavigationDestination(icon: Icon(Icons.history), label: '履歴'),
        ],
      ),
    );
  }
}
