import 'package:flutter/material.dart';

import '../data/mood_record_store.dart';
import '../domain/mood_record.dart';
import '../l10n/app_strings.dart';
import '../notifications/reminder_service.dart';
import '../settings/settings_controller.dart';
import '../widgets/level_selector.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen(
      {required this.store,
      required this.initialDate,
      required this.settings,
      required this.reminders,
      required this.onSaved,
      super.key});
  final MoodRecordStore store;
  final DateTime initialDate;
  final SettingsController settings;
  final ReminderService reminders;
  final VoidCallback onSaved;
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  static const centerPage = 10000;
  late final PageController _pages;
  late final DateTime _centerDate;
  var _page = centerPage;
  @override
  void initState() {
    super.initState();
    _centerDate = MoodRecord.dateOnly(widget.initialDate);
    _pages = PageController(initialPage: centerPage);
  }

  DateTime _dateFor(int page) =>
      _centerDate.add(Duration(days: page - centerPage));
  int get _lastPage =>
      centerPage +
      MoodRecord.dateOnly(DateTime.now()).difference(_centerDate).inDays;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
              Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.12),
              Theme.of(context).colorScheme.surface,
              Theme.of(context)
                  .colorScheme
                  .tertiaryContainer
                  .withValues(alpha: 0.10),
            ])))),
        Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(children: [
                IconButton(
                    onPressed: () => _pages.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut),
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                    child: Text(
                        AppStrings(widget.settings.value.language)
                            .recordFor(_dateFor(_page)),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall)),
                IconButton(
                    onPressed: _page >= _lastPage
                        ? null
                        : () => _pages.nextPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut),
                    icon: const Icon(Icons.chevron_right)),
              ])),
          Expanded(
              child: PageView.builder(
                  controller: _pages,
                  itemCount: _lastPage + 1,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, page) => _RecordDayForm(
                      key: ValueKey(MoodRecord.dateKey(_dateFor(page))),
                      date: _dateFor(page),
                      store: widget.store,
                      settings: widget.settings,
                      reminders: widget.reminders,
                      onSaved: widget.onSaved))),
        ]),
      ]);
}

class _RecordDayForm extends StatefulWidget {
  const _RecordDayForm(
      {required this.date,
      required this.store,
      required this.settings,
      required this.reminders,
      required this.onSaved,
      super.key});
  final DateTime date;
  final MoodRecordStore store;
  final SettingsController settings;
  final ReminderService reminders;
  final VoidCallback onSaved;
  @override
  State<_RecordDayForm> createState() => _RecordDayFormState();
}

class _RecordDayFormState extends State<_RecordDayForm> {
  final _memo = TextEditingController();
  int _mania = 0, _depression = 0;
  double _sleep = 7;
  bool _medication = false, _loading = true, _saving = false, _existing = false;
  static final _sleepOptions = [for (var i = 0; i <= 48; i++) i / 2];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final record = await widget.store.findByDate(widget.date);
    if (!mounted) return;
    setState(() {
      _existing = record != null;
      _mania = record?.maniaLevel ?? 0;
      _depression = record?.depressionLevel ?? 0;
      _sleep = record?.sleepHours ?? widget.settings.value.averageSleepHours;
      _medication = record?.tookMedication ?? false;
      _memo.text = record?.memo ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.store.save(MoodRecord(
        date: widget.date,
        maniaLevel: _mania,
        depressionLevel: _depression,
        sleepHours: _sleep,
        tookMedication: _medication,
        memo: _memo.text));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _existing = true;
    });
    await widget.reminders.update(widget.settings.value);
    widget.onSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings(widget.settings.value.language)
              .t('記録を保存しました', 'Record saved'))));
    }
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(widget.settings.value.language);
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(children: [
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              children: [
            Text(_existing
                ? s.t('保存済み・内容を編集できます', 'Saved · You can edit this record')
                : s.t('まだ記録されていません', 'Not recorded yet')),
            const SizedBox(height: 20),
            LevelSelector(
                label: s.t('躁の強さ', 'Mania intensity'),
                value: _mania,
                highColor: Colors.red,
                onChanged: (v) => setState(() => _mania = v)),
            const SizedBox(height: 20),
            LevelSelector(
                label: s.t('鬱の強さ', 'Depression intensity'),
                value: _depression,
                highColor: Colors.blue,
                onChanged: (v) => setState(() => _depression = v)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Text(s.t('睡眠時間', 'Sleep'),
                      style: Theme.of(context).textTheme.titleMedium)),
              DropdownButton<double>(
                  value: _sleep,
                  items: _sleepOptions
                      .map((h) => DropdownMenuItem(
                          value: h,
                          child: Text(
                              '${h.toStringAsFixed(h % 1 == 0 ? 0 : 1)} ${s.t('時間', 'hours')}')))
                      .toList(),
                  onChanged: (v) => setState(() => _sleep = v!)),
            ]),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('服薬', 'Medication')),
                subtitle: Text(_medication
                    ? s.t('飲んだ', 'Taken')
                    : s.t('飲んでいない', 'Not taken')),
                value: _medication,
                onChanged: (v) => setState(() => _medication = v)),
            TextField(
                controller: _memo,
                minLines: 2,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                    labelText: s.t('メモ（任意）', 'Memo (optional)'),
                    hintText:
                        s.t('気になることがあれば', 'Anything you want to remember'))),
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(_existing
                      ? s.t('記録を更新する', 'Update record')
                      : s.t('記録する', 'Save record'))))),
    ]);
  }
}
