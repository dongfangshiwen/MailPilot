<p align="center"><img src="docs/assets/mailpilot-banner.svg" alt="MailPilot" width="100%" /></p>

<h1 align="center">MailPilot</h1>
<p align="center">把 AI 对话、邮件阅读与回复，放在同一个 Android 应用里。</p>
<p align="center"><a href="https://github.com/dongfangshiwen/MailPilot/releases/latest">下载 1.0.0</a> · <a href="#quick-start">快速上手</a> · <a href="#build">部署与编译</a></p>

**简体中文** · [繁體中文](docs/readme/README.zh-Hant.md) · [English](docs/readme/README.en.md) · [日本語](docs/readme/README.ja.md) · [한국어](docs/readme/README.ko.md) · [Español](docs/readme/README.es.md) · [Français](docs/readme/README.fr.md) · [Deutsch](docs/readme/README.de.md)

> **Android 8.0+ · Flutter + Kotlin · 8 种界面语言**<br>
> 配置你自己的模型即可开始聊天，邮箱按需添加。应用直接连接所配置的服务，无需部署 MailPilot 后端。每封邮件都在你确认后才发送。

## 可以用它做什么

| 功能 | 使用体验 |
| --- | --- |
| **AI 对话** | 流式 Markdown 回答、可折叠思考与处理过程；支持模型切换、停止和重试。 |
| **邮件助手** | 连接 IMAP / SMTP 邮箱，检索和阅读邮件，将选中的正文与附件交给模型分析。 |
| **图文与附件** | 支持图片、PDF、Office 和文本；同一会话内复用已完成的图片分析，也可主动重新核对。 |
| **联网与来源** | 配置搜索服务后检索公开资料；按需读取资料中的网页链接，回答可通过来源编号核对。 |
| **起草与发送** | 将回答写成邮件，编辑收件人、正文和附件；核对确认卡片后再发送。 |
| **会话管理** | 搜索对话、按日期分组、置顶、重命名与侧栏内多选；长历史整理保留原始记录。 |
| **日常偏好** | 八种语言、深浅主题、语音输入和可选后台同步，支持一天一次。 |

## 界面一览

<p align="center">
  <img src="docs/screenshots/build43/language-zh-settings.png" width="30%" alt="简体中文" />
  <img src="docs/screenshots/build43/language-en-settings.png" width="30%" alt="English" />
  <img src="docs/screenshots/build43/language-de-settings.png" width="30%" alt="Deutsch — dark theme" />
</p>

简体中文、英语与德语深色设置页。截图使用示例配置，不包含真实邮箱凭据。

<a id="quick-start"></a>
## 快速上手

1. **安装应用**：从上方 Release 下载 APK。升级已有安装时使用相同签名的安装包，保留应用数据。
2. **添加模型**：设置 → 模型与服务 → 添加模型，填写服务商、HTTPS Base URL、模型名和 API Key。可配置 DeepSeek、火山方舟、百炼等服务或兼容接口，能力以实际型号为准。
3. **开始对话**：返回首页输入问题；通过加号添加图片或文件。普通 AI 聊天不要求绑定邮箱。
4. **连接邮箱（可选）**：设置 → 邮箱账户 → 添加邮箱。支持 QQ、163、阿里邮箱及自定义 IMAP / SMTP；先在邮箱服务商处开启相关服务，按指引使用授权码或客户端密码。
5. **阅读与回复**：设置 → 我的邮件，同步后阅读；对话加号 → 选择邮件，可检查附件范围，再提问或要求起草。发送前核对收件人、正文与附件并确认。
6. **按需开启功能**：设置 → 搜索与语音配置服务；设置 → 偏好设置调整语言、主题和后台同步。首次默认简体中文；修改界面语言不会自动翻译邮件或模型回答。

### 试着这样提问

- “总结所选邮件，列出交期、金额和待确认的问题。”
- “对比这几张图片中的规格差异，并标出来源。”
- “根据以上结论，起草一封英文回复，先让我确认。”

### 附件支持

| 类型 | 处理方式 |
| --- | --- |
| JPG / PNG / WebP | 交给已配置的视觉模型分析 |
| PDF | 按选定页渲染为图片，默认前 10 页 |
| DOCX / XLSX / PPTX | 本地提取文字、表格及嵌入图片 |
| TXT | 本地读取；旧 DOC / XLS / PPT 请先转换格式 |

每轮最多 10 个附件、合计 50 MB、20 张视觉资料；单附件最多 20 MB。最终编码请求体另受应用 32 MiB 及厂商限制约束。超限时调整资料或选择分批处理。

<a id="build"></a>
## 部署与编译

这是在手机上运行的 Android 应用，不需要 Docker、数据库服务器或独立 API 后端。邮箱与模型凭据在安装后的设置页填写，不写进源码。Web 仅提供示例界面预览。

### 构建环境

| 组件 | 本次验证版本 |
| --- | --- |
| Flutter / Dart | 3.47.2 / 3.13.2 |
| JDK | 17–25 |
| Android SDK / Build Tools | 36 / 36.0.0 |
| NDK / CMake | 28.2.13676358 / 3.22.1 |
| Gradle / AGP | 9.3.1 / 9.1.0 |

先安装 Flutter 与 Android Studio，把 Flutter 加入 PATH，并通过 SDK Manager 安装表中的 Android 组件。下面的 JDK 路径请改成你电脑上的实际路径。首次下载依赖需要网络。

```powershell
git clone https://github.com/dongfangshiwen/MailPilot.git
cd MailPilot
flutter doctor

$env:MAILPILOT_JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
.\scripts\Build.ps1 -Mode Debug
.\scripts\Build.ps1 -Mode Release
.\scripts\Package-Delivery.ps1
```

Debug 使用隔离包名 `app.mailpilot.validation`；Release 使用 `app.mailpilot`。脚本会生成本机 SDK 配置。首次自行构建 Release 会创建 `.signing/`；以后务必保留原签名。自行生成的新签名不能覆盖官方签名安装。

### 输出文件 · artifacts/

| 文件 | 用途 |
| --- | --- |
| `MailPilot-1.0.0-flutter-release.apk` | Android 安装包 |
| `MailPilot-1.0.0-flutter-source.zip` | 源码、脚本、文档及截图 |
| `MailPilot-1.0.0-flutter-delivery.zip` | 安装包与源码完整交付包 |
| `*.sha256` | 对应文件的 SHA-256 校验值 |

### 测试

```powershell
.\scripts\Build.ps1 -Mode Test
adb devices
.\scripts\Test-Profile.ps1 -Device emulator-5554 -Mode Debug -Target integration_test/language43_test.dart
```

把示例设备编号替换为 `adb devices` 显示的编号。UI 测试脚本使用隔离包名并保留测试应用；不要对日常包直接运行 `flutter drive`。

本轮语言更新通过 489 项 Flutter 测试、3 项原生语言测试及 API36 隔离验证；Lint 无错误，保留 13 个提示。72 组布局检查覆盖 8 种语言、三种宽度和字体缩放。详细结果见下方测试说明。

### 浏览器预览

```powershell
flutter run -d chrome -t lib/main_preview.dart
```

预览使用示例邮件和模拟回复，不连接真实邮箱或模型。浏览器预览不代表已支持 Web 邮箱客户端。

## 项目结构

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

Flutter 负责界面，通过平台通道调用 Kotlin 服务；Android 侧负责 Agent、邮箱、附件、Room 数据库与 DataStore 设置。语言资源位于 `lib/l10n/`，修改 ARB 后运行 `flutter gen-l10n`。

## 数据与发送边界

- 邮箱授权码与 API Key 使用 Android Keystore 加密；会话、附件和缓存保存在应用私有目录。
- 提问时会将所选资料发送给配置的模型；启用搜索或云端语音时会调用对应服务，并可能产生厂商费用。
- 网页读取以只读访问为目标；登录、验证码和部分动态站点可能无法提取，不保证所有链接都可读取。
- 邮件发送始终需要用户确认。后台同步默认关闭，也不会自动分析或发送邮件。
- 卸载会删除本地数据。源码与交付包排除签名材料、用户配置和数据库；开发者应单独备份 `.signing/`。

## 进一步了解

- [邮箱配置指南](docs/MAIL_SETUP.md)
- [八种语言与测试报告](docs/LOCALIZATION_1_0_0_BUILD_43.md)
- [版本更新与历史记录](docs/CHANGELOG.md)
- [第三方组件](docs/THIRD_PARTY.md)

README 提供八种语言版本；详细技术记录目前以简体中文为主。
