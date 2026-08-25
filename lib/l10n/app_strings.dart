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
  String recordFor(DateTime date) =>
      t('${date.month}/${date.day}の記録', 'Record for ${date.month}/${date.day}');
}
