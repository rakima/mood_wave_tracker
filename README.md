# mood-wave-tracker

毎日の躁・鬱の強さをそれぞれ独立して記録し、0を中心とした時系列の波として確認する Android 向け Flutter アプリです。医学的な診断や状態判定は行いません。

Android上のアプリ表示名は「Mood Wave」です。

## 主な機能

- 曜日付きの日付を左右にスワイプして、躁・鬱（各0〜5）、睡眠（0〜24時間、0.5時間刻み）、服薬、任意メモを記録
- 日付を一意キーとして、同日の再保存時は既存記録を更新
- 躁を `+1〜+5`、鬱を `-1〜-5` の独立した系列として表示（初期表示30日）
- グラフを7日／30日／90日から選択し、点のタップで日別詳細を表示
- 日付降順の履歴と、履歴からの編集
- システム設定に連動するライト／ダークテーマ
- 平均睡眠時間、日本語／英語、未記録時の通知時刻を設定
- テーマを端末設定／ライト／ダークから選択
- SQLiteとアプリ設定をAndroid Auto Backup／端末間転送の対象として保持

## 技術構成

- Flutter / Material 3
- SQLite (`sqflite`)：1日1レコードという制約を主キーと DB 制約で堅牢に表現でき、Android で実績があり、データ移行も明示的に管理しやすいため採用
- `path`：SQLite のデータベースパスをプラットフォーム非依存に組み立てるため使用
- `CustomPainter`：一般的な気分チャートの単一スコアへ寄せず、躁と鬱の独立した ± 系列、強調した0線、上下対称の背景を正確に描画するため採用。チャートライブラリ依存は追加していません
- `sqflite_common_ffi`（開発時のみ）：SQLite リポジトリの単体テストに使用
- `shared_preferences`：平均睡眠時間、言語、通知設定のような小さな端末設定を保存
- `flutter_local_notifications`：未記録日の端末内リマインダーを予約
- `timezone` / `flutter_timezone`：指定した通知時刻を端末のローカルタイムで扱うため使用
- `flutter_launcher_icons`（開発時のみ）：`image/icon.png` からAndroid用アイコンを生成
- Android Auto Backup：SQLite（補助ファイルを含む）とアプリ設定を、Android 11以前／12以降それぞれのバックアップルールで明示的に対象化

データモデルは UI から分離し、`MoodRecordStore` を境界としているため、画面を DB 実装の詳細に依存させていません。値の範囲は Dart モデルと SQLite の `CHECK` 制約の二重で検証します。

## 起動方法

Flutter SDK と Android SDK を用意し、Android 端末またはエミュレーターを接続して実行します。

```sh
flutter pub get
flutter run
```

テストと静的解析、APK ビルドは次のコマンドで確認できます。

```sh
flutter analyze
flutter test
flutter build apk --debug
```

## Google Play公開

Androidの正式Application IDは`com.rakima.moodwavetracker`、端末上の表示名は「Mood Wave」です。releaseビルドは専用のアップロード鍵が設定されている場合だけ生成でき、debug鍵は使用しません。

- [Google Playリリース手順](docs/play-store-release.md)
- [Data safety調査](docs/play-store-data-safety.md)
- [プライバシーポリシー原稿](docs/privacy-policy.md)

公開前には、プライバシーポリシー原稿を公開URLへ掲載し、Play ConsoleのData safetyおよびHealth apps declarationを完了してください。

## MVP の範囲

アカウント、アプリ独自のクラウド同期、診断・医療アドバイス、エクスポート、詳細統計、ウェアラブル連携は含みません。Android Auto Backupは端末のバックアップ設定が有効な場合にOSが実行し、アプリ自身が外部APIへ送信する機能ではありません。通知は端末内で今後365日分を予約し、記録保存または設定変更時に未記録日のみ再構成します。

`flutter_timezone` は現行最新版でも将来のKotlin Gradle Plugin互換性警告が出るため、依存更新時に追従します。
