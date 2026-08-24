import 'package:flutter_test/flutter_test.dart';
import 'package:mood_wave_tracker/data/mood_record_repository.dart';
import 'package:mood_wave_tracker/domain/mood_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late MoodRecordRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    final database =
        await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await MoodRecordRepository.createSchema(database);
    repository = MoodRecordRepository(database: database);
  });

  tearDown(() => repository.close());

  MoodRecord makeRecord(
          {int mania = 2, int depression = 1, String memo = ''}) =>
      MoodRecord(
        date: DateTime(2026, 8, 24, 18),
        maniaLevel: mania,
        depressionLevel: depression,
        sleepHours: 7.5,
        tookMedication: true,
        memo: memo,
      );

  test('MoodRecordを保存して読み出せる', () async {
    await repository.save(makeRecord(memo: '穏やか'));
    final saved = await repository.findByDate(DateTime(2026, 8, 24));
    expect(saved, isNotNull);
    expect(saved!.memo, '穏やか');
    expect(saved.sleepHours, 7.5);
    expect(saved.tookMedication, isTrue);
  });

  test('同日の保存は追加せず既存レコードを更新する', () async {
    await repository.save(makeRecord(mania: 1));
    await repository.save(makeRecord(mania: 5));
    final all = await repository.findAll();
    expect(all, hasLength(1));
    expect(all.single.maniaLevel, 5);
  });

  test('躁と鬱が同時に0より大きくても独立して保存する', () async {
    await repository.save(makeRecord(mania: 4, depression: 3));
    final saved = await repository.findByDate(DateTime(2026, 8, 24));
    expect(saved!.maniaLevel, 4);
    expect(saved.depressionLevel, 3);
  });
}
