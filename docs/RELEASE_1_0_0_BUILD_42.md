# MailPilot 1.0.0（42）：邮件检索卡片与返回位置

## 原因与变化

| 问题 | 原实现 | 本轮修复 |
|---|---|---|
| 邮件详情返回后跳到底部 | 详情页面替换并销毁 `Assistant`；返回重新建立滚动控制器，初次布局又触发跟随 | 详情覆盖父页面，保留滚动控制器、输入、卡片分页和思考区状态；系统返回与工具栏返回使用相同状态 |
| 从“选择邮件”返回也丢失位置 | 切换邮件分区同样销毁对话，只临时缓存了输入文字 | 会话在分区下方保留，账号和会话切换才重建；移除原输入缓存及恢复接口 |
| 结果一多就撑长对话 | `resultCards` 中所有邮件直接逐条加入对话列表，每封显示完整摘要 | 单张圆角卡片显示真实数量，默认两封预览，展开后每页五封；保留打开邮件和逐封选择操作 |
| 正在阅读却被迟到更新拉走 | 滚动回调可能在页面已被覆盖后继续执行 | 暂停流式跟随与当前滚动活动，废弃旧布局回调；返回本身不恢复跟随，点击向下箭头或主动发送后才恢复 |
| 多层页面同时响应返回 | 编辑器的 `PopScope` 即使被引用等页面遮住仍会处理返回 | 仅最上层编辑器响应自己的返回操作，保留未保存修改与发送确认保护 |

展开、收起、翻页、选择和打开检索邮件均优先保留用户阅读位置。卡片没有内部嵌套滚动区，分页只影响展示；不会额外搜索、修改检索条件或默认选中邮件。新会话、账号或请求的卡片状态彼此独立，结果减少时校正页码。

这次采用通用页面生命周期和展示组件修复，没有按问题文字、邮件主题、厂商或内容增加特例。没有修改 Agent、邮件传输、网页读取、数据库结构和缓存规则。清理原先逐条平铺结果与只保护引用页的页面替换分支，Room 仍为 v9。

## 验证

- Flutter 全套 405 项通过，其中新增 15 项回归；静态分析无问题。
- 覆盖 320／360／412 dp、1.0／1.6／2.0 字体，包含深浅色主题；30 封结果折叠后只构建两封，展开为五封，操作区不横向溢出。
- 覆盖打开邮件后的系统返回、输入保留、卡片翻页与选择保留、阅读详情期间继续生成、显式回到最新消息、结果缩减、会话隔离、隐藏编辑器返回保护。
- 现有引用返回、聊天滚动和流式显示回归通过。
- Android Lint 0 错误、20 条提示：16 条依赖版本建议、1 条目标系统版本建议和 3 条 KTX 建议。本轮比构建 41 多检出 7 条 AndroidX 版本建议，应用依赖版本未改动，见 [Lint 汇总](test-evidence/build42/lint-summary.json)、[提示明细](test-evidence/build42/lint-issues.json)及[运行日志](test-evidence/build42/lint.log)。原生代码没有变更，本轮没有重复原生单元测试或真实模型测试。

记录：[首轮 14 项回归](test-evidence/build42/results-tests.log)、[包含全部 15 项新增回归的最终 Flutter 测试](test-evidence/build42/flutter-tests.log)、[静态分析](test-evidence/build42/analyze.log)、[代码变更范围](test-evidence/build42/code-review.json)。

## API36 与交付

复用 `MailPilot_API36` 的现有系统镜像，界面测试通过 `scripts/Test-Profile.ps1` 在 `app.mailpilot.validation` 运行。使用合成邮件和模拟检索结果验证本轮界面变化，不调用模型、真实搜索或 SMTP，不将 UI 测试当作厂商性能测速。

设备回归通过：深浅主题下折叠／展开、第二页邮件详情返回，以及进入邮件分区后返回，均保留同一滚动控制器、偏移和卡片页码；四张截图已人工查看。系统返回测试调用 Flutter 的返回事件，与页面处理系统返回使用同一入口，未模拟特定手机厂商的手势动画。

首轮设备测试在 `ensureVisible` 后没有等待布局帧就点击，点击坐标落到视口外，未触发翻页。增加布局等待后通过，保留[首轮记录](test-evidence/build42/api36-ui-initial.log)和[最终设备回归](test-evidence/build42/api36-ui-tests.log)。Debug 日志中的启动跳帧不作为发布版性能结论。

截图：[浅色折叠](screenshots/build42/mail-results-collapsed-light.png)、[浅色展开](screenshots/build42/mail-results-expanded-light.png)、[深色折叠](screenshots/build42/mail-results-collapsed-dark.png)、[深色展开](screenshots/build42/mail-results-expanded-dark.png)。

日常包没有安装、卸载或清数据操作，仍保留构建 41。前后私有备份比较：17 张表、全部已备份配置及偏好文件哈希一致，SQLite 完整性通过，见[数据校验](test-evidence/build42/data-preserved.json)。

发布版本仍为 1.0.0，内部构建递增至 42；设置页继续不显示构建号。沿用原发布签名，以构建 41 的发布 APK 校验证书兼容性；日常包为调试签名，本轮不以卸载或清数据来安装发布包。

APK 实际包名 `app.mailpilot`、版本 `1.0.0`、构建 `42`，发布证书与构建 41 一致；见 [APK 和签名校验](test-evidence/build42/apk-verification.json)。交付包含 APK、源码、Windows 脚本、本报告、截图、测试证据和 SHA-256。

已结束本轮启动的无界面模拟器会话，保留 AVD、系统镜像与日常数据。使用 Flutter 自带 `clean` 清理 Flutter 构建目录；额外 Android Gradle／Kotlin 缓存保留且不进入源码包。私有数据备份、签名材料和临时文件均排除在交付包之外。
