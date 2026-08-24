import 'package:flutter/material.dart';

import '../data/mood_record_store.dart';
import '../domain/mood_record.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.store, required this.onEdit, super.key});

  final MoodRecordStore store;
  final ValueChanged<DateTime> onEdit;

  String _sleep(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<MoodRecord>>(
        future: store.findAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          return CustomScrollView(
            slivers: [
              const SliverAppBar.large(title: Text('履歴')),
              if (records.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('記録はまだありません')),
                )
              else
                SliverList.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        minVerticalPadding: 14,
                        title: Text(MoodRecord.dateKey(record.date)
                            .replaceAll('-', '/')),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                              '躁 ${record.maniaLevel}　鬱 ${record.depressionLevel}　'
                              '睡眠 ${_sleep(record.sleepHours)}時間\n'
                              '服薬 ${record.tookMedication ? '飲んだ' : '飲んでいない'}'),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onEdit(record.date),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      );
}
