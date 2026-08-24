import '../domain/mood_record.dart';

abstract interface class MoodRecordStore {
  Future<MoodRecord?> findByDate(DateTime date);
  Future<List<MoodRecord>> findAll();
  Future<List<MoodRecord>> findBetween(DateTime from, DateTime to);
  Future<void> save(MoodRecord record);
  Future<void> close();
}
