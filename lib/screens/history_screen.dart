import 'package:flutter/material.dart';

import '../data/mood_record_store.dart';
import '../domain/mood_record.dart';
import '../l10n/app_strings.dart';
import '../settings/app_settings.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen(
      {required this.store,
      required this.language,
      required this.onEdit,
      super.key});

  final MoodRecordStore store;
  final AppLanguage language;
  final ValueChanged<DateTime> onEdit;

  String _sleep(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(language);
    return FutureBuilder<List<MoodRecord>>(
      future: store.findAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!;
        return CustomScrollView(
          slivers: [
            SliverAppBar.large(title: Text(strings.history)),
            if (records.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child: Text(strings.t('記録はまだありません', 'No records yet'))),
              )
            else
              SliverList.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      minVerticalPadding: 14,
                      title: Text(
                          MoodRecord.dateKey(record.date).replaceAll('-', '/')),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  strings.t(
                                      '躁${record.maniaLevel}　鬱${record.depressionLevel}　睡眠時間${_sleep(record.sleepHours)}時間　服薬 ${record.tookMedication ? '〇' : '×'}',
                                      'Mania ${record.maniaLevel}  Depression ${record.depressionLevel}  Sleep ${_sleep(record.sleepHours)}h  Med ${record.tookMedication ? '○' : '×'}'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (record.memo.isNotEmpty)
                                Text(record.memo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ]),
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
}
