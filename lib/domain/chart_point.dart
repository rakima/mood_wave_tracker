import 'mood_record.dart';

class MoodChartPoint {
  const MoodChartPoint({
    required this.date,
    required this.maniaValue,
    required this.depressionValue,
  });

  final DateTime date;
  final int maniaValue;
  final int depressionValue;
}

MoodChartPoint toChartPoint(MoodRecord record) => MoodChartPoint(
      date: record.date,
      maniaValue: record.maniaLevel,
      depressionValue: -record.depressionLevel,
    );
