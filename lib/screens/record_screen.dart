import 'package:flutter/material.dart';

import '../data/mood_record_store.dart';
import '../domain/mood_record.dart';
import '../widgets/level_selector.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    required this.store,
    required this.date,
    required this.onSaved,
    super.key,
  });

  final MoodRecordStore store;
  final DateTime date;
  final VoidCallback onSaved;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _memoController = TextEditingController();
  int _mania = 0;
  int _depression = 0;
  double _sleep = 7;
  bool _medication = false;
  bool _loading = true;
  bool _saving = false;
  bool _existing = false;

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
      _sleep = record?.sleepHours ?? 7;
      _medication = record?.tookMedication ?? false;
      _memoController.text = record?.memo ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.store.save(MoodRecord(
        date: widget.date,
        maniaLevel: _mania,
        depressionLevel: _depression,
        sleepHours: _sleep,
        tookMedication: _medication,
        memo: _memoController.text,
      ));
      if (!mounted) return;
      setState(() => _existing = true);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('記録を保存しました')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final day = MoodRecord.dateKey(widget.date).replaceAll('-', '/');
    final isToday =
        MoodRecord.dateKey(widget.date) == MoodRecord.dateKey(DateTime.now());
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: [
              Text(isToday ? '今日の記録' : '$day の記録',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(_existing ? '保存済み・内容を編集できます' : 'まだ記録されていません'),
              const SizedBox(height: 24),
              LevelSelector(
                  label: '躁の強さ',
                  value: _mania,
                  onChanged: (value) => setState(() => _mania = value)),
              const SizedBox(height: 20),
              LevelSelector(
                  label: '鬱の強さ',
                  value: _depression,
                  onChanged: (value) => setState(() => _depression = value)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: Text('睡眠時間',
                          style: Theme.of(context).textTheme.titleMedium)),
                  DropdownButton<double>(
                    value: _sleep,
                    items: _sleepOptions
                        .map((hours) => DropdownMenuItem(
                              value: hours,
                              child: Text(
                                  '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)} 時間'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _sleep = value!),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('服薬'),
                subtitle: Text(_medication ? '飲んだ' : '飲んでいない'),
                value: _medication,
                onChanged: (value) => setState(() => _medication = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'メモ（任意）',
                  hintText: '気になることがあれば',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_existing ? '記録を更新する' : '記録する'),
            ),
          ),
        ),
      ],
    );
  }
}
