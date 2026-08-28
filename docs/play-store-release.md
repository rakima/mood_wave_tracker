# Google Play リリース手順

## 固定設定

- Application ID / namespace: `com.rakima.moodwavetracker`
- Android表示名: `Mood Wave`
- 初回バージョン: `1.0.0+1`
- minSdk: 24
- targetSdk / compileSdk: 36
- 提出形式: Android App Bundle (`.aab`)
- Play Storeアイコン: `image/play-store-icon.png`（512×512、32-bit PNG）

Application IDはPlay Consoleでアプリを作成した後に変更できません。登録前に最終確認してください。

開発版の旧Application ID `com.example.mood_wave_tracker` とはAndroid上で別アプリとして扱われます。旧開発版のSQLiteやAuto Backupは新Application IDへ自動移行されません。Google Play初回登録前の変更としては問題ありませんが、既存の動作確認データが必要なら旧アプリを削除する前に内容を確認してください。

## 1. バージョン更新

`pubspec.yaml`の`version`は`versionName+versionCode`です。

```yaml
version: 1.0.0+1
```

次回以降は例として`1.0.1+2`、`1.1.0+3`のように更新します。`+`以降のversionCodeは、Google Playへ提出するたびに必ず過去より大きくしてください。

## 2. アップロード鍵を作成

この操作は初回のみ、人間が安全なローカル環境で行います。リポジトリの`android`ディレクトリで次を実行します。

```sh
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`upload-keystore.jks`を安全な場所へバックアップしてください。鍵やパスワードをGit、Issue、チャット、CIログへ掲載しないでください。

## 3. 署名設定

`android/key.properties.example`を`android/key.properties`へコピーし、実際の値を設定します。

```properties
storePassword=実際のパスワード
keyPassword=実際のパスワード
keyAlias=upload
storeFile=../upload-keystore.jks
```

`key.properties`、`*.jks`、`*.keystore`はGit管理対象外です。releaseビルドはこの設定がない場合に停止し、debug鍵へフォールバックしません。

## 4. 品質確認と成果物生成

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

生成場所:

- release APK: `build/app/outputs/flutter-apk/app-release.apk`
- Play提出用AAB: `build/app/outputs/bundle/release/app-release.aab`

新規アプリはPlay App Signingを利用し、ローカルのアップロード鍵で署名したAABをPlay Consoleへ提出します。Google Playが配布用のアプリ署名鍵を管理します。

## 5. Play Console側の作業

- [ ] `com.rakima.moodwavetracker`でアプリを作成
- [ ] Play App Signingを有効化
- [ ] ストア掲載情報、スクリーンショット、アイコン、フィーチャーグラフィックを登録
- [ ] 公開プライバシーポリシーURL `https://rakima.github.io/mood_wave_tracker/` をPlay Consoleへ登録
- [ ] PR #7のマージ後、GitHub Pagesの配信元を`main /docs`へ変更
- [ ] Data safetyフォームを提出
- [ ] Health apps declarationを提出
- [ ] コンテンツレーティング、対象年齢、広告の有無を回答
- [ ] 内部テストへAABを登録して実機検証
- [ ] クローズドテスト要件を確認・実施
- [ ] pre-launch reportとポリシー警告を確認
- [ ] 製品版リリース前にversionCodeが未使用か確認
