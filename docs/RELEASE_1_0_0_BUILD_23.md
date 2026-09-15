# MailPilot 1.0.0（23）

继续按用户要求作为 **1.0.0** 稳定测试版发布，内部构建号由 22 增至 23；验收前不升至 1.0.1。包名 `app.mailpilot`、原发布签名、Room v8 及已有存储结构保持不变。

## 聊天直达最新消息

- 查看较早聊天、距离底部超过 180 dp 时，在输入框上方右侧显示小型向下箭头；点击直达最新消息，接近底部时自动隐藏。
- 中性边框与浅阴影，圆形外观 32 dp，图标 21 dp，实际点击区域 48 dp；适配浅色、深色和大字体，提供“回到最新消息”无障碍名称。
- 按钮悬浮于消息区，不占用输入框或消息布局。保留已有输入和键盘状态，不主动聚焦输入框。
- 翻看旧消息时，普通流式回答不会强行把阅读位置拉到底部。点击按钮后恢复现有的底部跟随行为。
- 长距离直接定位，短距离使用轻微滚动动画；系统要求减少动画时直接定位。处理懒加载长短消息造成的列表高度修正，避免停在最后一条之前。
- 空会话、短对话及浏览其他历史分支时不显示按钮；切换会话会撤销待执行的旧跳转。只改变视图位置，不发送问题、请求模型或改变资料选择。

新增独立 `ChatScrollViewport` 组件，沿用原来的聊天列表控制器。滚动时仅刷新按钮可见性，原有新消息、草稿卡片和会话恢复逻辑保留。构建 22 的模型上下文与邮箱配置优化继续有效，见 [上一版说明](RELEASE_1_0_0_BUILD_22.md)。

## 验证

| 检查 | 结果 |
|---|---|
| Flutter analyze | 无问题 |
| Flutter 测试 | 246 项通过，其中新增滚动交互测试 9 项 |
| Android JVM | 146 项通过、2 项真实 IMAP 测试跳过、0 失败 |
| Android Lint | 0 错误，17 条既有警告 |
| API 36 长会话流程 | 1 项功能流程通过（不把框架 tearDownAll 计入），覆盖深浅色、跳转及实际键盘展开 |
| 发布签名 / 16 KB 对齐 | 通过，与旧版证书一致 |
| 1.0.0（22）→（23）覆盖安装 | 通过，UID、首次安装时间及旧测试模型配置保留 |

新增界面测试覆盖 320／360／412 dp、浅色普通字体和深色 2.0 字体、80 条不同高度消息、流式增量、键盘展开、输入保留、切换会话与短会话。实际设备流程使用 API 36 和本地虚构长会话；相关截图标明样例模式，不是用户邮件或真实模型回答。

覆盖升级先安装既有正式（22），确认之前保存的虚构配置 `upgrade22-fixture`，再通过 `adb install -r` 安装正式（23）。两版间没有卸载或清除数据；冷启动后配置仍在。随后才运行独立的 Flutter 集成测试入口。本轮未改原生业务逻辑，执行原生 JVM 与 Lint，未重复构建 22 的全套原生设备迁移流程。

本轮没有真实邮箱、云端模型或 SMTP 请求。保留现有工具链，Kotlin 插件未来迁移提示仍存在，不影响此次构建。

测试记录：`test-evidence/build23-*`；界面截图：`screenshots/build23/`。

截图复核后补充“软键盘确实展开”的断言。首个补充测试因系统输入法尚未回报窗口尺寸就检查而失败，之后改为有限等待 Android 的键盘尺寸通知并重新通过；保留失败日志，没有移除断言。截图通过 Flutter 渲染层采集，因此键盘图片本身未进入截图，但输入框的上移及非零键盘尺寸已验证。

截图：[浅色箭头](screenshots/build23/scroll-history-light.png)、[深色箭头](screenshots/build23/scroll-history-dark.png)、[直达最新](screenshots/build23/scroll-latest-light.png)、[键盘展开后的布局](screenshots/build23/scroll-with-keyboard.png)、[正式 APK 覆盖升级](screenshots/build23/release-upgrade.png)。

## 交付与缓存

- APK：`artifacts/MailPilot-1.0.0-flutter-release.apk`
- 源码：`artifacts/MailPilot-1.0.0-flutter-source.zip`
- 完整包：`artifacts/MailPilot-1.0.0-flutter-delivery.zip`
- 每个文件均附 SHA-256；源码含 Windows 构建与打包脚本、测试、中文说明及截图，不含私钥、本机配置和编译缓存。

APK SHA-256：`9632f112757b684fd6e0d381497fb6b35fb39ea2ef255af2ee94c8c2aca127ec`

签名证书 SHA-256：`0be84c66d74a7a2f8ccd8a39ee792f0c3b22fd942600307164f38ff93b3f2f17`

验证后通过 Android 官方 `avdmanager` 删除复用的临时设备 `MailPilot_Build22_Test36`；通过 `flutter clean` 清除 `build`、`.dart_tool` 和生成的插件索引。磁盘可用空间约增加 **9.15 GiB**（9.82 GB，系统并行写入可能使该值略有变化）。保留日常设备 `MailPilot_API36`、现有 API 36 系统镜像、源码、签名材料、发布文件及旧 APK 升级基线。下次构建会重新生成项目缓存。

遗留目录 `.tools/avd170-test36` 约 3.80 GiB：自动审批拒绝递归删除，只返回 `blocked by policy`，未提供进一步原因，因此仍保留，没有改用其他方法绕过。约 17 MB 的 Gradle 项目元数据也保留。清理记录见 `test-evidence/build23-cleanup.json`。
