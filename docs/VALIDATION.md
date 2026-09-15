> 本轮交付 **1.0.0（24）**。图片分析复用、会话侧栏、代码审查与验证见 [构建 24 说明](RELEASE_1_0_0_BUILD_24.md)。以下旧版本内容保留为历史记录。

> 当前交付 **1.0.2（19）**，版本栏间距调整验证见 [构建 19](RELEASE_1_0_2_BUILD19.md)。以下保留历史记录。

> 本轮重新交付 **1.0.2（18）**，版本左右切换与气泡操作验证见 [构建 18](RELEASE_1_0_2_BUILD18.md)。以下保留历史记录。

> 当前版本为 **1.0.0（30）**。本轮验证见 [构建 30 说明](RELEASE_1_0_0_BUILD_30.md) 及 `test-evidence/build30/validation.json`；下文旧数据保留为历史证据，不计入本轮测试。

> 当前版本为 **1.0.1（16）**。默认附件选择、处理预算、PDF 缩略图与覆盖升级的本轮验证见 [RELEASE_1_0_1.md](RELEASE_1_0_1.md) 和 `test-evidence/release101-*`。菜单返回键盘修复见 [1.0.0](RELEASE_1_0_0.md)，图片附件预览见 [1.8.4](RELEASE_1_8_4.md)，模型设置见 [1.8.3](RELEASE_1_8_3.md)，阿里 IMAP 真实验证见 [1.8.1](RELEASE_1_8_1.md)。下文旧版数据保留为历史证据，不计为本轮测试。

# MailPilot 1.2.0 Flutter 验证记录

本页保留 1.2.0 的历史验证。当前 1.6.0 的检查、实际 QQ 只读验证及设备记录见 [RELEASE_1_6.md](RELEASE_1_6.md)。1.3.0 的上下文机制见 [CONTEXT_MEMORY.md](CONTEXT_MEMORY.md)，邮箱选项布局修复见 [MAILBOX_LAYOUT.md](MAILBOX_LAYOUT.md)。

验证日期：2026-09-07。`lib/main.dart` 在 Android 使用真实服务，在浏览器／桌面进入标记清楚的预览。`lib/main_preview.dart` 只用于样例预览和自动化测试。

## 工程检查

- Flutter 3.47.2 / Dart 3.13.2，JDK 25，Gradle 9.3.1，AGP 9.1.0。
- Android compile / target 36，最低 API 26；NDK 28.2.13676358、CMake 3.22.1。
- `flutter analyze`：通过，无问题。
- Flutter Web 主入口 Release 编译通过，包含 WebAssembly dry run；未做浏览器实际连通验收。非 Android 入口选择由 Widget 测试验证。
- Flutter 测试：18 项通过。覆盖原有页面流程，以及预览无原生通道、MissingPlugin 中文提示、首次启动模型按钮、设置按钮与系统返回、部分回答实时显示与停止、Markdown 表格／代码／图片限制／来源链接、回答复制、服务商识别、思考配置保存及参数互斥。新增阿里企业／个人邮箱预设提交的 SSL 地址与端口、切换保留输入、编辑识别和窄屏大字体测试。
- Android JVM 测试：36 项通过。7 项资料范围 / 工具编排，3 项本地邮件服务集成，4 项 MIME / 编码，4 项原有模型协议，7 项 Office，6 项流式与异常，5 项思考参数及数据库升级。
- 延迟 SSE 测试确认在请求仍运行时已收到第一段中文；覆盖 reasoning_content、encrypted_content、空 choices 用量尾包、工具参数分片、取消、断流、长度限制、内容过滤、资源不足中断、非 SSE 响应不自动重试。
- 数据库 1 → 2 测试使用旧版 schema 建库并写入模型和草稿，再通过实际 Room 自动迁移读取；密钥密文、正文及草稿版本均保留，新增思考设置可保存。
- Android Lint：0 错误，17 条警告。警告为 target SDK 新版本建议、依赖新版本提示和 KTX 写法建议。未关闭 Lint 错误检查。

JVM 邮箱测试使用本机 GreenMail；模型协议测试使用 MockWebServer。它们验证代码行为，不代表真实 QQ / 163 / 阿里邮箱或云模型连通性。

## Android 设备测试

测试设备均为 Windows 上的 Android 模拟器，没有连接实体手机。

| 系统 | Flutter 集成测试 | Android 平台测试 | Google Play 服务 |
| --- | --- | --- | --- |
| Android 8.0 / API 26 | 2 项功能测试通过 | 4 项通过 | 系统镜像不含 GMS |
| Android 16 / API 36 | 2 项功能测试通过 | 4 项通过 | 不作为无 GMS 验收依据 |
| Android 17 / API 37 | 2 项功能测试通过 | 4 项通过 | 测试前禁用 GMS |

Flutter 集成测试验证真实 MethodChannel / EventChannel、思考模式和档位保存、空 Key 编辑保留凭据、状态不泄露密钥、设置按钮和系统返回。样例流程覆盖选信 → PDF 页码 → 草稿 → 发送前核对、增量 Markdown、思考参数表单与深色模式。测试不发送真实邮件，不调用云端模型。额外 `tearDownAll` 为框架收尾，不计入功能测试数。

最终 API 26 回归还覆盖阿里企业预设。首次运行的流式截图断言因固定 400 ms 等待早于异步画面更新而失败；已改为等待第一段文字渲染与键盘收起，随后仍断言回答未结束，再进行截图。失败日志保留为 `streaming-alibaba-first-attempt.log`，调整后的设备测试通过，最终截图日志为 `streaming-ui26-final.log`。

API 26 使用 `emulator-5562` 并以 `-ExpectedApi 26` 校验设备实际系统；API 36 来自 Android Studio 同时运行的模拟器，日志按实际系统单独记录，不混作 API 26 结果。

平台测试验证：系统 PdfRenderer 渲染普通和模拟扫描 PDF、空 / 超限页码拒绝、Keystore 每次产生不同密文且能解密、通道省略凭据、列表只传正文预览而详情才传完整正文、Android 邮件 provider 和中文 MIME 可用。

截图 `screenshots/flutter/` 来自 API 37 的样例测试，`screenshots/android26/` 来自 API 26。可打开 [界面预览](preview.html)。

## Release 与升级

正式 APK 包名 `app.mailpilot`，版本 `1.2.0`（versionCode 3），包含 arm64-v8a / armeabi-v7a / x86_64。

APK 已使用原发布密钥签名，签名验证及 16 KB 原生库页对齐检查通过。证书 SHA-256：

`0be84c66d74a7a2f8ccd8a39ee792f0c3b22fd942600307164f38ff93b3f2f17`

API 26 已完成 1.1.0 → 1.2.0 Release 覆盖安装与冷启动，无平台通道报错；版本、启动记录和截图以 `streaming-api26-` 开头保存。最终 SHA-256 见交付校验文件。旧版迁移的历史证据保留在原子目录中，不计入本版测试数量。

## 尚未验证

- 真实邮箱授权码及真实模型 API Key 未提供，因此真实服务端的登录、收发、限流和视觉识别质量尚未验证。
- 未在实体手机执行“电脑关闭后”的网络全流程、厂商省电策略、不同硬件图像处理及实际长时间后台同步验证。
- Office / 图像测试覆盖构造样例，不能保证所有供应商生成文件或复杂排版均兼容。

安装后请先在应用内执行邮箱和模型的连接 / 能力测试。应用按手机独立运行设计，测试模拟服务不属于 APK 运行依赖。

## 证据

本版证据采用 `test-evidence/streaming-*` 前缀；`streaming-jvm/` 为 36 项 JUnit XML，API 26 / 36 / 37 分别保存平台测试记录。`streaming-final-build.log` 含分析、单元测试、API 36 设备测试和签名构建；API 26 使用 `streaming-android26.log`，API 37 使用 `streaming-android37.log` 和 `streaming-ui37-final.log`。加入阿里邮箱预设后的最终检查和 API 26 页面回归记录在 `streaming-alibaba-final-build.log`；新版配置截图见 `screenshots/android26/flutter-alibaba-fixture.png`。目录中其他文件是此前版本记录。






