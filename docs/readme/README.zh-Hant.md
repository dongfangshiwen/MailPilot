<p align="center"><img src="../../docs/assets/mailpilot-banner.svg" alt="MailPilot" width="100%" /></p>

<h1 align="center">MailPilot</h1>
<p align="center">把 AI 對話、郵件閱讀與回覆，放在同一個 Android 應用裡。</p>
<p align="center"><a href="https://github.com/dongfangshiwen/MailPilot/releases/latest">下載 1.0.0</a> · <a href="#quick-start">快速上手</a> · <a href="#build">部署與編譯</a></p>

[简体中文](../../README.md) · **繁體中文** · [English](../../docs/readme/README.en.md) · [日本語](../../docs/readme/README.ja.md) · [한국어](../../docs/readme/README.ko.md) · [Español](../../docs/readme/README.es.md) · [Français](../../docs/readme/README.fr.md) · [Deutsch](../../docs/readme/README.de.md)

> **Android 8.0+ · Flutter + Kotlin · 8 種介面語言**<br>
> 配置你自己的模型即可開始聊天，郵箱按需新增。應用直接連線所配置的服務，無需部署 MailPilot 後端。每封郵件都在你確認後才傳送。

## 可以用它做什麼

| 功能 | 使用體驗 |
| --- | --- |
| **AI 對話** | 流式 Markdown 回答、可摺疊思考與處理過程；支援模型切換、停止和重試。 |
| **郵件助手** | 連線 IMAP / SMTP 郵箱，檢索和閱讀郵件，將選中的正文與附件交給模型分析。 |
| **圖文與附件** | 支援圖片、PDF、Office 和文字；同一會話內複用已完成的圖片分析，也可主動重新核對。 |
| **聯網與來源** | 配置搜尋服務後檢索公開資料；按需讀取資料中的網頁連結，回答可透過來源編號核對。 |
| **起草與傳送** | 將回答寫成郵件，編輯收件人、正文和附件；核對確認卡片後再傳送。 |
| **會話管理** | 搜尋對話、按日期分組、置頂、重新命名與側欄內多選；長曆史整理保留原始記錄。 |
| **日常偏好** | 八種語言、深淺主題、語音輸入和可選後臺同步，支援一天一次。 |

## 介面一覽

<p align="center">
  <img src="../../docs/screenshots/build43/language-zh-settings.png" width="30%" alt="简体中文" />
  <img src="../../docs/screenshots/build43/language-en-settings.png" width="30%" alt="English" />
  <img src="../../docs/screenshots/build43/language-de-settings.png" width="30%" alt="Deutsch — dark theme" />
</p>

簡體中文、英語與德語深色設定頁。截圖使用示例配置，不包含真實郵箱憑據。

<a id="quick-start"></a>
## 快速上手

1. **安裝應用**：從上方 Release 下載 APK。升級已有安裝時使用相同簽名的安裝包，保留應用資料。
2. **新增模型**：設定 → 模型與服務 → 新增模型，填寫服務商、HTTPS Base URL、模型名和 API Key。可配置 DeepSeek、火山方舟、百鍊等服務或相容介面，能力以實際型號為準。
3. **開始對話**：返回首頁輸入問題；透過加號新增圖片或檔案。普通 AI 聊天不要求繫結郵箱。
4. **連線郵箱（可選）**：設定 → 郵箱賬戶 → 新增郵箱。支援 QQ、163、阿里郵箱及自定義 IMAP / SMTP；先在郵箱服務商處開啟相關服務，按指引使用授權碼或客戶端密碼。
5. **閱讀與回覆**：設定 → 我的郵件，同步後閱讀；對話加號 → 選擇郵件，可檢查附件範圍，再提問或要求起草。傳送前核對收件人、正文與附件並確認。
6. **按需開啟功能**：設定 → 搜尋與語音配置服務；設定 → 偏好設定調整語言、主題和後臺同步。首次預設簡體中文；修改介面語言不會自動翻譯郵件或模型回答。

### 試著這樣提問

- “總結所選郵件，列出交期、金額和待確認的問題。”
- “對比這幾張圖片中的規格差異，並標出來源。”
- “根據以上結論，起草一封英文回覆，先讓我確認。”

### 附件支援

| 型別 | 處理方式 |
| --- | --- |
| JPG / PNG / WebP | 交給已配置的視覺模型分析 |
| PDF | 按選定頁渲染為圖片，預設前 10 頁 |
| DOCX / XLSX / PPTX | 本地提取文字、表格及嵌入圖片 |
| TXT | 本地讀取；舊 DOC / XLS / PPT 請先轉換格式 |

每輪最多 10 個附件、合計 50 MB、20 張視覺資料；單附件最多 20 MB。最終編碼請求體另受應用 32 MiB 及廠商限制約束。超限時調整資料或選擇分批處理。

<a id="build"></a>
## 部署與編譯

這是在手機上執行的 Android 應用，不需要 Docker、資料庫伺服器或獨立 API 後端。郵箱與模型憑據在安裝後的設定頁填寫，不寫進原始碼。Web 僅提供示例介面預覽。

### 構建環境

| 元件 | 本次驗證版本 |
| --- | --- |
| Flutter / Dart | 3.47.2 / 3.13.2 |
| JDK | 17–25 |
| Android SDK / Build Tools | 36 / 36.0.0 |
| NDK / CMake | 28.2.13676358 / 3.22.1 |
| Gradle / AGP | 9.3.1 / 9.1.0 |

先安裝 Flutter 與 Android Studio，把 Flutter 加入 PATH，並透過 SDK Manager 安裝表中的 Android 元件。下面的 JDK 路徑請改成你電腦上的實際路徑。首次下載依賴需要網路。

```powershell
git clone https://github.com/dongfangshiwen/MailPilot.git
cd MailPilot
flutter doctor

$env:MAILPILOT_JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
.\scripts\Build.ps1 -Mode Debug
.\scripts\Build.ps1 -Mode Release
.\scripts\Package-Delivery.ps1
```

Debug 使用隔離包名 `app.mailpilot.validation`；Release 使用 `app.mailpilot`。指令碼會生成本機 SDK 配置。首次自行構建 Release 會建立 `.signing/`；以後務必保留原簽名。自行生成的新簽名不能覆蓋官方簽名安裝。

### 輸出檔案 · artifacts/

| 檔案 | 用途 |
| --- | --- |
| `MailPilot-1.0.0-flutter-release.apk` | Android 安裝包 |
| `MailPilot-1.0.0-flutter-source.zip` | 原始碼、指令碼、文件及截圖 |
| `MailPilot-1.0.0-flutter-delivery.zip` | 安裝包與原始碼完整交付包 |
| `*.sha256` | 對應檔案的 SHA-256 校驗值 |

### 測試

```powershell
.\scripts\Build.ps1 -Mode Test
adb devices
.\scripts\Test-Profile.ps1 -Device emulator-5554 -Mode Debug -Target integration_test/language43_test.dart
```

把示例裝置編號替換為 `adb devices` 顯示的編號。UI 測試指令碼使用隔離包名並保留測試應用；不要對日常包直接執行 `flutter drive`。

本輪語言更新透過 489 項 Flutter 測試、3 項原生語言測試及 API36 隔離驗證；Lint 無錯誤，保留 13 個提示。72 組佈局檢查覆蓋 8 種語言、三種寬度和字型縮放。詳細結果見下方測試說明。

### 瀏覽器預覽

```powershell
flutter run -d chrome -t lib/main_preview.dart
```

預覽使用示例郵件和模擬回覆，不連線真實郵箱或模型。瀏覽器預覽不代表已支援 Web 郵箱客戶端。

## 專案結構

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

Flutter 負責介面，透過平臺通道呼叫 Kotlin 服務；Android 側負責 Agent、郵箱、附件、Room 資料庫與 DataStore 設定。語言資源位於 `lib/l10n/`，修改 ARB 後執行 `flutter gen-l10n`。

## 資料與傳送邊界

- 郵箱授權碼與 API Key 使用 Android Keystore 加密；會話、附件和快取儲存在應用私有目錄。
- 提問時會將所選資料傳送給配置的模型；啟用搜尋或雲端語音時會呼叫對應服務，並可能產生廠商費用。
- 網頁讀取以只讀訪問為目標；登入、驗證碼和部分動態站點可能無法提取，不保證所有連結都可讀取。
- 郵件傳送始終需要使用者確認。後臺同步預設關閉，也不會自動分析或傳送郵件。
- 解除安裝會刪除本地資料。原始碼與交付包排除簽名材料、使用者配置和資料庫；開發者應單獨備份 `.signing/`。

## 進一步瞭解

- [郵箱配置指南](../../docs/MAIL_SETUP.md)
- [八種語言與測試報告](../../docs/LOCALIZATION_1_0_0_BUILD_43.md)
- [版本更新與歷史記錄](../../docs/CHANGELOG.md)
- [第三方元件](../../docs/THIRD_PARTY.md)

README 提供八種語言版本；詳細技術記錄目前以簡體中文為主。
