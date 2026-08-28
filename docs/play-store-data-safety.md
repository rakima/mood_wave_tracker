# Google Play Data safety 調査

調査日: 2026-08-28

対象: `com.rakima.moodwavetracker` / version 1.0.0 (1)

この文書は現在のコード、直接・推移依存パッケージ、Android Manifest、バックアップルールを調査した結果です。Play Consoleの質問文やポリシーは変更される可能性があるため、提出時に最新内容と再照合してください。

## アプリが扱うデータ

| データ | 内容 | 保存場所 | 用途 |
| --- | --- | --- | --- |
| 健康情報 | 躁・鬱の強さ、睡眠時間、服薬状況 | 端末内SQLite | 日々の記録、履歴、グラフ |
| ユーザー生成コンテンツ | 任意メモ | 端末内SQLite | 記録の補足 |
| アプリ設定 | 平均睡眠時間、言語、テーマ、通知ON/OFF・時刻 | SharedPreferences | UIとリマインダー設定 |
| 日時情報 | 記録日、作成・更新日時 | 端末内SQLite | 1日1件の管理と時系列表示 |

氏名、メールアドレス、アカウント識別子、位置情報、連絡先、写真、音声、決済情報、広告IDは取得しません。

## 外部送信・SDK調査

- アプリ独自サーバー、外部API、Firebaseを使用していません。
- Analytics、Crashlytics、広告、課金SDKを使用していません。
- 本番Manifestには`INTERNET`権限がありません。debug/profile ManifestだけがFlutter開発接続用に`INTERNET`を追加します。
- `timezone`の推移依存に`http`がありますが、本アプリは`timezone/data/latest.dart`の同梱データを読み込むだけで、HTTPクライアントを呼び出しません。
- `sqflite`と`shared_preferences`は端末内保存に使用します。
- `flutter_local_notifications`は端末内通知の予約に使用します。
- `flutter_timezone`は端末のタイムゾーン識別子の取得に使用します。

## Android Auto Backup

`AndroidManifest.xml`でAuto Backupを有効化し、Android 11以前の`backup_rules.xml`とAndroid 12以降の`data_extraction_rules.xml`で次を対象にしています。

- SQLite database domain全体（DB本体、journal/WAL等の補助ファイル）
- SharedPreferences全体
- Googleアカウントへのクラウドバックアップ
- 対応端末間のDevice-to-Device Transfer

Android標準バックアップは転送中・保存時に暗号化されます。実行時期、保存先、復元可否はユーザーのAndroidバックアップ設定、Googleアカウント、端末メーカーに依存します。アプリ開発者はバックアップ内容へアクセスしません。

健康情報を含むため、公開判断として「Auto Backupを維持する」「クライアント側暗号化を必須化する」「健康記録をクラウドバックアップから除外する」のいずれかを、プライバシーポリシーと利用者期待を踏まえて最終確認してください。現状は利便性を優先して標準Auto Backupを維持しています。

## Android権限

release用統合Manifestで確認した権限は次のとおりです。

| 権限 | 用途 |
| --- | --- |
| `POST_NOTIFICATIONS` | Android 13以降で、利用者がONにした未記録リマインダーを表示 |
| `VIBRATE` | 通知プラグインが通知時の端末標準振動に使用 |
| `RECEIVE_BOOT_COMPLETED` | 再起動・アプリ更新後に予約通知を復元 |

AndroidXが、同一署名アプリ内の動的receiver保護用にApplication ID固有のsignature権限を自動追加します。これは利用者へ要求されるruntime権限ではなく、外部データへのアクセスにも使いません。

release Manifestには`INTERNET`、位置情報、カメラ、マイク、連絡先、電話、身体センサー、Health Connect、ストレージ全体へのアクセス権限はありません。

## Data safety回答の判断材料

現在の実装では、開発者または第三者SDKがユーザーデータを受領・利用せず、アプリ外への独自送信もありません。Android OSがユーザーのバックアップ設定に基づいてGoogleアカウントへ保存する標準Auto Backupについては、アプリ開発者はデータへアクセスしません。

Google Playの現行説明では、ユーザー自身の外部ストレージへ直接アップロードされ、アプリ側がアクセスしないデータは「収集」として申告不要となる場合があります。この前提では、Data safetyの「収集」「共有」はともに「なし」が候補です。ただし健康情報とOS管理の自動バックアップを含むため、Play Console提出時の最新設問・ヘルプに照らして最終回答してください。

Data safetyフォーム自体の提出と公開プライバシーポリシーURLは、データ収集がない場合でも必要です。

## Health apps申告

- 本アプリはメンタルヘルス・睡眠・服薬状況の自己記録と可視化を提供するため、Play ConsoleのHealth apps declarationが必要です。
- 医療機器ではなく、診断、治療、治癒、予防を行いません。
- 設定画面のプライバシーポリシー本文に免責と、医療上の判断は医療専門家へ相談する旨を表示します。
- ストア説明にも同等の免責を明記する必要があります。

## 提出前の再確認

- [ ] Play ConsoleのData safetyフォームを最新設問に従って完了
- [ ] Health apps declarationで実際の記録機能を正確に申告
- [ ] 公開プライバシーポリシーの内容とアプリ内表示を一致させる
- [ ] Auto Backup方針を最終決定
- [ ] 新しいSDK追加時はデータ収集・共有・権限を再監査
