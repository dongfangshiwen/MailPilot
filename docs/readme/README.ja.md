<p align="center"><img src="../../docs/assets/mailpilot-banner.svg" alt="MailPilot" width="100%" /></p>

<h1 align="center">MailPilot</h1>
<p align="center">AI との対話、メールの閲覧と返信を、ひとつの Android アプリで。</p>
<p align="center"><a href="https://github.com/dongfangshiwen/MailPilot/releases/latest">1.0.0 をダウンロード</a> · <a href="#quick-start">使い始める</a> · <a href="#build">導入とビルド</a></p>

[简体中文](../../README.md) · [繁體中文](../../docs/readme/README.zh-Hant.md) · [English](../../docs/readme/README.en.md) · **日本語** · [한국어](../../docs/readme/README.ko.md) · [Español](../../docs/readme/README.es.md) · [Français](../../docs/readme/README.fr.md) · [Deutsch](../../docs/readme/README.de.md)

> **Android 8.0+ · Flutter + Kotlin · 8 言語に対応**<br>
> ご自身のモデルを設定すれば対話を開始できます。メールアカウントの追加は任意です。設定したサービスへ直接接続するため、MailPilot 用サーバーは不要です。メールは確認後にのみ送信されます。

## 主な機能

| 機能 | できること |
| --- | --- |
| **AI 対話** | Markdown のストリーミング表示、折りたたみ可能な思考・処理表示、モデル切り替え、停止と再試行。 |
| **メール支援** | IMAP / SMTP 接続、メールの検索と閲覧、選択した本文・添付ファイルの分析。 |
| **画像と文書** | 画像、PDF、Office、テキストに対応。同じ会話内では完了した画像分析を再利用し、必要に応じて再確認。 |
| **検索と出典** | 設定した検索サービスで公開情報を検索し、資料中のリンクを必要に応じて読み取り、出典を確認。 |
| **下書きと送信** | 回答からメールを作成し、宛先や添付を編集。確認カードを確認してから送信。 |
| **会話管理** | 会話検索、日付別表示、固定、名前変更、サイドバー内の複数選択。要約後も元の履歴を保持。 |
| **各種設定** | 8 言語、ライト・ダークテーマ、音声入力、1 日ごとを含む任意のバックグラウンド同期。 |

## 画面紹介

<p align="center">
  <img src="../../docs/screenshots/build43/language-zh-settings.png" width="30%" alt="简体中文" />
  <img src="../../docs/screenshots/build43/language-en-settings.png" width="30%" alt="English" />
  <img src="../../docs/screenshots/build43/language-de-settings.png" width="30%" alt="Deutsch — dark theme" />
</p>

簡体字中国語、英語、ドイツ語のダークテーマ設定画面。実際のメール認証情報ではなくサンプル設定を使用しています。

<a id="quick-start"></a>
## 使い始める

1. **インストール**：上の Releases から APK を取得します。既存アプリの更新には同じ署名のパッケージを使用し、データを保持してください。
2. **モデルを追加**：設定 → モデルとサービス → モデルを追加。プロバイダー、HTTPS Base URL、モデル名、API キーを入力します。DeepSeek、火山方舟、Alibaba Cloud Model Studio などに対応し、利用可能な機能はモデルに依存します。
3. **対話を開始**：ホームで質問するか、＋から画像・ファイルを追加します。AI 対話にメール登録は不要です。
4. **メール接続（任意）**：設定のメールアカウントから追加します。QQ、163、Alibaba Mail、カスタム IMAP / SMTP を選べます。提供元でサービスを有効にし、認証コードやアプリパスワードを設定してください。
5. **閲覧と返信**：設定からメールを開いて同期します。対話の＋からメールを選び、添付範囲を確認して分析や下書きを依頼します。宛先・本文・添付を確認してから送信します。
6. **環境設定**：検索・音声サービス、言語、テーマ、同期を設定できます。初期言語は簡体字中国語です。表示言語を変えてもメールやモデルの回答は自動翻訳されません。

### 質問の例

- 「選択したメールを要約し、納期、金額、確認事項をまとめて。」
- 「画像の仕様の違いを比較し、出典を示して。」
- 「この結論から英語の返信を下書きし、先に確認させて。」

### 添付ファイル

| 形式 | 処理 |
| --- | --- |
| JPG / PNG / WebP | 設定した視覚モデルで分析 |
| PDF | 選択ページを画像化。初期設定は最初の 10 ページ |
| DOCX / XLSX / PPTX | 文字・表・埋め込み画像を端末で抽出 |
| TXT | 端末で読み取り。旧 DOC / XLS / PPT は事前変換が必要 |

1 回につき添付 10 個、合計 50 MB、視覚資料 20 件まで。添付 1 個は 20 MB までです。エンコード後のリクエストにはアプリの 32 MiB 上限と提供元の制限も適用されます。超過時は資料を調整するか分割処理を選択してください。

<a id="build"></a>
## 導入とビルド

Android 上で動作し、Docker、データベースサーバー、独自 API サーバーは不要です。認証情報はソースではなくアプリの設定に入力します。Web はサンプル UI プレビューのみです。

### ビルド環境

| 構成要素 | 検証したバージョン |
| --- | --- |
| Flutter / Dart | 3.47.2 / 3.13.2 |
| JDK | 17–25 |
| Android SDK / Build Tools | 36 / 36.0.0 |
| NDK / CMake | 28.2.13676358 / 3.22.1 |
| Gradle / AGP | 9.3.1 / 9.1.0 |

Flutter と Android Studio をインストールし、Flutter を PATH に追加してください。SDK Manager で下表の構成要素を導入し、JDK パスは実際の場所に変更します。初回の依存関係取得にはネット接続が必要です。

```powershell
git clone https://github.com/dongfangshiwen/MailPilot.git
cd MailPilot
flutter doctor

$env:MAILPILOT_JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
.\scripts\Build.ps1 -Mode Debug
.\scripts\Build.ps1 -Mode Release
.\scripts\Package-Delivery.ps1
```

Debug は隔離パッケージ `app.mailpilot.validation`、Release は `app.mailpilot` を使用します。スクリプトがローカル SDK 設定を生成します。初回 Release ビルドで作られる `.signing/` は更新用に保管してください。新規生成した鍵では公式署名版を上書き更新できません。

### 出力ファイル · artifacts/

| ファイル | 用途 |
| --- | --- |
| `MailPilot-1.0.0-flutter-release.apk` | Android インストーラー |
| `MailPilot-1.0.0-flutter-source.zip` | ソース、スクリプト、文書、スクリーンショット |
| `MailPilot-1.0.0-flutter-delivery.zip` | APK とソースの完全パッケージ |
| `*.sha256` | 各ファイルの SHA-256 チェックサム |

### テスト

```powershell
.\scripts\Build.ps1 -Mode Test
adb devices
.\scripts\Test-Profile.ps1 -Device emulator-5554 -Mode Debug -Target integration_test/language43_test.dart
```

端末 ID は `adb devices` の表示に合わせてください。UI テストは隔離パッケージを使い、終了後もアプリを保持します。日常利用のパッケージに直接 `flutter drive` を実行しないでください。

言語更新は Flutter 489 件、ネイティブ言語テスト 3 件、API36 の隔離検証を通過しました。Lint はエラー 0 件、注意事項 13 件です。72 パターンで 8 言語、3 画面幅、文字拡大を検証しました。詳細は下記レポートを参照してください。

### ブラウザープレビュー

```powershell
flutter run -d chrome -t lib/main_preview.dart
```

サンプルメールと模擬応答を使用し、実際のメール・モデルには接続しません。Web メールクライアントとしての提供ではありません。

## プロジェクト構成

```text
MailPilot/
├── lib/                    # Flutter UI
│   └── l10n/               # ARB resources & generated localizations
├── android/app/src/main/   # Android services & Agent
├── test/                   # Flutter tests
├── integration_test/       # Isolated UI tests
├── scripts/                # Windows build & packaging
└── docs/                   # Guides, reports & screenshots
```

Flutter が UI を担当し、プラットフォームチャネルで Kotlin を呼び出します。Android 側に Agent、メール、添付処理、Room、DataStore を配置しています。`lib/l10n/` の ARB 編集後は `flutter gen-l10n` を実行してください。

## データと送信

- 認証コードと API キーは Android Keystore で暗号化し、会話・添付・キャッシュはアプリ専用領域に保存します。
- 質問時に選択資料が設定したモデルへ送られます。検索・クラウド音声は対応サービスを利用し、提供元の料金が発生する場合があります。
- Web 読み取りは読み取り専用です。ログイン、CAPTCHA、一部の動的ページには対応できず、すべてのリンクの取得は保証しません。
- 送信には必ずユーザー確認が必要です。バックグラウンド同期は初期状態で無効で、自動分析や自動送信は行いません。
- アンインストールするとローカルデータが削除されます。配布物に署名鍵、利用者設定、データベースは含めません。開発者は `.signing/` を別途バックアップしてください。

## 詳しく知る

- [メール設定ガイド](../../docs/MAIL_SETUP.md)
- [8 言語とテストレポート](../../docs/LOCALIZATION_1_0_0_BUILD_43.md)
- [更新履歴](../../docs/CHANGELOG.md)
- [サードパーティーコンポーネント](../../docs/THIRD_PARTY.md)

README は 8 言語で提供しています。詳細な技術資料は主に簡体字中国語です。
