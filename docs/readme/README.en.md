<p align="center"><img src="../../docs/assets/mailpilot-banner.svg" alt="MailPilot" width="100%" /></p>

<h1 align="center">MailPilot</h1>
<p align="center">AI conversations, email reading and replies — together on Android.</p>
<p align="center"><a href="https://github.com/dongfangshiwen/MailPilot/releases/latest">Download 1.0.0</a> · <a href="#quick-start">Quick start</a> · <a href="#build">Deploy & build</a></p>

[简体中文](../../README.md) · [繁體中文](../../docs/readme/README.zh-Hant.md) · **English** · [日本語](../../docs/readme/README.ja.md) · [한국어](../../docs/readme/README.ko.md) · [Español](../../docs/readme/README.es.md) · [Français](../../docs/readme/README.fr.md) · [Deutsch](../../docs/readme/README.de.md)

> **Android 8.0+ · Flutter + Kotlin · 8 interface languages**<br>
> Bring your own model to start chatting; connect an email account when you need it. MailPilot connects directly to your configured services, with no MailPilot server to deploy. Emails are sent only after your confirmation.

## What you can do

| Feature | How it helps |
| --- | --- |
| **AI conversations** | Stream Markdown answers, expand reasoning and activity, switch models, stop or retry. |
| **Email assistance** | Connect IMAP / SMTP accounts, search and read messages, and analyze selected email content and attachments. |
| **Images & documents** | Work with images, PDF, Office and text files. Reuse completed image analysis within a conversation or request a fresh check. |
| **Search & sources** | Use a configured search service for public information; read referenced web links on demand and inspect citations. |
| **Draft & send** | Turn an answer into an email, edit recipients and attachments, and review the confirmation card before sending. |
| **Conversation library** | Search, group by date, pin, rename and select multiple conversations in the sidebar. Long-history summaries retain original records. |
| **Personal preferences** | Eight languages, light and dark themes, voice input and optional background sync, including once a day. |

## A look inside

<p align="center">
  <img src="../../docs/screenshots/build43/language-zh-settings.png" width="30%" alt="简体中文" />
  <img src="../../docs/screenshots/build43/language-en-settings.png" width="30%" alt="English" />
  <img src="../../docs/screenshots/build43/language-de-settings.png" width="30%" alt="Deutsch — dark theme" />
</p>

Settings in Simplified Chinese, English and German dark mode. Screenshots use sample configuration, not real email credentials.

<a id="quick-start"></a>
## Quick start

1. **Install**: download the APK from Releases above. Use a package with the same signature to update an existing installation and retain its data.
2. **Add a model**: Settings → Models & services → Add model. Enter the provider, HTTPS Base URL, model ID and API key. DeepSeek, Volcengine Ark, Alibaba Cloud Model Studio and compatible endpoints are configurable; features depend on the chosen model.
3. **Start a conversation**: ask a question on the home screen, or use the plus button to add images and files. AI chat does not require an email account.
4. **Connect email (optional)**: Settings → Email accounts → Add email account. Choose QQ, 163, Alibaba Mail or custom IMAP / SMTP. Enable those services with your provider and use the required authorization code or app password.
5. **Read and reply**: open My emails in Settings and sync. In chat, use Plus → Select emails, review attachment selection, then ask for analysis or a draft. Verify recipients, body and attachments before confirming a send.
6. **Customize**: configure Search & voice in Settings, then choose language, appearance and background sync under Preferences. The default is Simplified Chinese. Interface language does not automatically translate emails or model answers.

### Try asking

- “Summarize the selected emails and list delivery dates, prices and open questions.”
- “Compare the specifications in these images and cite your sources.”
- “Draft an English reply from these conclusions and let me review it first.”

### Supported attachments

| Type | Processing |
| --- | --- |
| JPG / PNG / WebP | Analyzed by your configured vision model |
| PDF | Selected pages rendered as images; first 10 pages by default |
| DOCX / XLSX / PPTX | Text, tables and embedded images extracted locally |
| TXT | Read locally; convert legacy DOC / XLS / PPT first |

Per turn: up to 10 attachments, 50 MB total and 20 visual items; up to 20 MB per attachment. Encoded requests also obey the app’s 32 MiB limit and provider limits. Adjust the selection or explicitly choose batch processing when a limit is reached.

<a id="build"></a>
## Deploy & build

MailPilot runs on Android. It needs no Docker deployment, database server or separate API backend. Enter email and model credentials in the installed app’s Settings, not in source code. Web is a sample UI preview only.

### Build environment

| Component | Validated version |
| --- | --- |
| Flutter / Dart | 3.47.2 / 3.13.2 |
| JDK | 17–25 |
| Android SDK / Build Tools | 36 / 36.0.0 |
| NDK / CMake | 28.2.13676358 / 3.22.1 |
| Gradle / AGP | 9.3.1 / 9.1.0 |

Install Flutter and Android Studio, put Flutter on PATH, and install the Android components listed below through SDK Manager. Replace the JDK path with your local installation. The initial dependency download requires internet access.

```powershell
git clone https://github.com/dongfangshiwen/MailPilot.git
cd MailPilot
flutter doctor

$env:MAILPILOT_JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
.\scripts\Build.ps1 -Mode Debug
.\scripts\Build.ps1 -Mode Release
.\scripts\Package-Delivery.ps1
```

Debug uses the isolated package `app.mailpilot.validation`; Release uses `app.mailpilot`. Scripts generate local SDK configuration. Your first release build creates `.signing/`; keep it for future updates. A newly generated key cannot update an installation signed with the official release key.

### Output files · artifacts/

| File | Purpose |
| --- | --- |
| `MailPilot-1.0.0-flutter-release.apk` | Android installer |
| `MailPilot-1.0.0-flutter-source.zip` | Source, scripts, documentation and screenshots |
| `MailPilot-1.0.0-flutter-delivery.zip` | Complete APK and source bundle |
| `*.sha256` | SHA-256 checksum for the corresponding file |

### Tests

```powershell
.\scripts\Build.ps1 -Mode Test
adb devices
.\scripts\Test-Profile.ps1 -Device emulator-5554 -Mode Debug -Target integration_test/language43_test.dart
```

Replace the device ID with one shown by `adb devices`. The UI test script uses an isolated package and keeps it installed. Do not run `flutter drive` directly against your daily app package.

The language update passed 489 Flutter tests, 3 native language tests and isolated API36 validation. Lint reports no errors and 13 advisories. The 72 layout cases cover eight languages, three widths and text scaling. See the linked test report for scope and results.

### Browser preview

```powershell
flutter run -d chrome -t lib/main_preview.dart
```

The preview uses sample emails and simulated replies without connecting to real email or model services. It is not a supported web email client.

## Project layout

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

Flutter renders the interface and calls Kotlin services through platform channels. Android handles the Agent, email, attachments, Room storage and DataStore preferences. Edit resources in `lib/l10n/`, then run `flutter gen-l10n`.

## Data & sending

- Email authorization codes and API keys are encrypted with Android Keystore; conversations, attachments and caches reside in app-private storage.
- Selected content is sent to your configured model when you ask a question. Search and cloud voice features contact their configured services and may incur provider charges.
- Web reading is read-only. Login pages, CAPTCHAs and some dynamic sites may not yield readable content; not every link can be extracted.
- Sending email always requires user confirmation. Background sync is off by default and does not automatically analyze or send email.
- Uninstalling deletes local data. Source and delivery archives exclude signing keys, user configuration and databases. Developers should back up `.signing/` separately.

## Learn more

- [Email setup guide](../../docs/MAIL_SETUP.md)
- [Eight languages and test report](../../docs/LOCALIZATION_1_0_0_BUILD_43.md)
- [Release history](../../docs/CHANGELOG.md)
- [Third-party components](../../docs/THIRD_PARTY.md)

The README is available in eight languages. Detailed technical records are currently mainly in Simplified Chinese.
