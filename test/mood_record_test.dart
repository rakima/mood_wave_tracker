import 'package:flutter_test/flutter_test.dart';
import 'package:mood_wave_tracker/domain/chart_point.dart';
import 'package:mood_wave_tracker/domain/mood_record.dart';

MoodRecord record({int mania = 0, int depression = 0, double sleep = 7}) =>
    MoodRecord(
      date: DateTime(2026, 8, 24),
      maniaLevel: mania,
      depressionLevel: depression,
      sleepHours: sleep,
      tookMedication: true,
    );

void main() {
  group('MoodRecord validation', () {
    test('躁は0と5を許可する', () {
      expect(record(mania: 0).maniaLevel, 0);
      expect(record(mania: 5).maniaLevel, 5);
    });

    test('躁の範囲外を拒否する', () {
      expect(() => record(mania: -1), throwsArgumentError);
      expect(() => record(mania: 6), throwsArgumentError);
    });

    test('鬱は0と5を許可する', () {
      expect(record(depression: 0).depressionLevel, 0);
      expect(record(depression: 5).depressionLevel, 5);
    });

    test('鬱の範囲外を拒否する', () {
      expect(() => record(depression: -1), throwsArgumentError);
      expect(() => record(depression: 6), throwsArgumentError);
    });

    test('睡眠は0〜24時間のみ許可する', () {
      expect(record(sleep: 0).sleepHours, 0);
      expect(record(sleep: 24).sleepHours, 24);
      expect(() => record(sleep: -0.5), throwsArgumentError);
      expect(() => record(sleep: 24.5), throwsArgumentError);
      expect(() => record(sleep: double.nan), throwsArgumentError);
    });
  });

  test('グラフ変換は躁を正、鬱を負の独立値にする', () {
    final point = toChartPoint(record(mania: 4, depression: 3));
    expect(point.maniaValue, 4);
    expect(point.depressionValue, -3);
    expect(point.maniaValue, isNot(1));
  });

  test('グラフ変換は躁と鬱の0をそれぞれ保持する', () {
    final maniaZero = toChartPoint(record(mania: 0, depression: 3));
    final depressionZero = toChartPoint(record(mania: 4, depression: 0));

    expect(maniaZero.maniaValue, 0);
    expect(maniaZero.depressionValue, -3);
    expect(depressionZero.maniaValue, 4);
    expect(depressionZero.depressionValue, 0);
  });
}
