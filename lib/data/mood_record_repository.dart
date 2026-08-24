import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../domain/mood_record.dart';
import 'mood_record_store.dart';

class MoodRecordRepository implements MoodRecordStore {
  MoodRecordRepository({Database? database}) : _database = database;

  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;
    final databasePath = await getDatabasesPath();
    return _database = await openDatabase(
      path.join(databasePath, 'mood_wave_tracker.db'),
      version: 1,
      onCreate: (db, version) => createSchema(db),
    );
  }

  static Future<void> createSchema(DatabaseExecutor db) => db.execute('''
        CREATE TABLE mood_records (
          date TEXT PRIMARY KEY,
          mania_level INTEGER NOT NULL CHECK(mania_level BETWEEN 0 AND 5),
          depression_level INTEGER NOT NULL CHECK(depression_level BETWEEN 0 AND 5),
          sleep_hours REAL NOT NULL CHECK(sleep_hours BETWEEN 0 AND 24),
          took_medication INTEGER NOT NULL CHECK(took_medication IN (0, 1)),
          memo TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

  @override
  Future<MoodRecord?> findByDate(DateTime date) async {
    final rows = await (await _db).query(
      'mood_records',
      where: 'date = ?',
      whereArgs: [MoodRecord.dateKey(date)],
      limit: 1,
    );
    return rows.isEmpty ? null : MoodRecord.fromMap(rows.first);
  }

  @override
  Future<List<MoodRecord>> findAll() async {
    final rows = await (await _db).query('mood_records', orderBy: 'date DESC');
    return rows.map(MoodRecord.fromMap).toList();
  }

  @override
  Future<List<MoodRecord>> findBetween(DateTime from, DateTime to) async {
    final rows = await (await _db).query(
      'mood_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [MoodRecord.dateKey(from), MoodRecord.dateKey(to)],
      orderBy: 'date ASC',
    );
    return rows.map(MoodRecord.fromMap).toList();
  }

  @override
  Future<void> save(MoodRecord record) async {
    record.validate();
    final database = await _db;
    await database.transaction((transaction) async {
      final existing = await transaction.query(
        'mood_records',
        columns: ['created_at'],
        where: 'date = ?',
        whereArgs: [MoodRecord.dateKey(record.date)],
        limit: 1,
      );
      final values = record.toMap();
      if (existing.isNotEmpty) {
        values['created_at'] = existing.first['created_at'];
      }
      values['updated_at'] = DateTime.now().toIso8601String();
      await transaction.insert(
        'mood_records',
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
