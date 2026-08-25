import 'package:flutter_test/flutter_test.dart';
import 'package:mood_wave_tracker/notifications/reminder_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('GMTとUTCをUTCロケーションへ変換する', () {
    expect(resolveTimezoneLocation('GMT').name, 'Etc/UTC');
    expect(resolveTimezoneLocation('UTC').name, 'Etc/UTC');
  });

  test('有効な地域タイムゾーンを維持する', () {
    expect(resolveTimezoneLocation('Asia/Tokyo').name, 'Asia/Tokyo');
  });

  test('未知のタイムゾーンはUTCへフォールバックする', () {
    expect(resolveTimezoneLocation('Unknown/Timezone').name, 'Etc/UTC');
  });
}
