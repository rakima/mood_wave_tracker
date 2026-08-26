import '../settings/app_settings.dart';

class AppStrings {
  const AppStrings(this.language);
  final AppLanguage language;
  bool get isJapanese => language == AppLanguage.japanese;
  String t(String ja, String en) => isJapanese ? ja : en;

  String get record => t('記録', 'Record');
  String get chart => t('グラフ', 'Chart');
  String get history => t('履歴', 'History');
  String get settings => t('設定', 'Settings');
  String recordFor(DateTime date) {
    const japaneseWeekdays = ['月', '火', '水', '木', '金', '土', '日'];
    const englishWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = isJapanese
        ? japaneseWeekdays[date.weekday - 1]
        : englishWeekdays[date.weekday - 1];
    return t(
      '${date.month}/${date.day}($weekday)の記録',
      'Record for ${date.month}/${date.day} ($weekday)',
    );
  }
}
