# MailPilot 1.0.0（38）：动态网页读取与引用选区

## 修复结果与实际边界

公司介绍链接已能读取动态正文，引用详情的选中文字与代码块也已恢复清晰高亮。用户提供的发票链接目前可以打开并读取“下载到手机、打印二维码”等页面入口，但该页的可见文字不包含发票明细。本版将它标为 `limited_content`，保留实际片段并说明图片／文件未读；**不能把本轮结果称为已经读取发票明细**。明细仍需在浏览器查看，或将下载文件添加为资料。

设置页继续显示 **1.0.0** 和发送确认提示，不显示构建号。内部构建号 38，Room 保持 v9。

## 根因与优化前后

| 项目 | 优化前 | 优化后 |
|---|---|---|
| 文档请求 | 简单请求头在该发票站点返回 406 | 使用标识 MailPilot 的浏览器兼容文档请求头；仍返回拒绝状态的请求不自动绕过或重复提交 |
| 动态页面 | 只解析初始 HTML，脚本外壳无正文 | 仅成功 HTML 且静态正文不足时，进入一次有时限的 WebView 渲染 |
| 页面数据 | 仅 GET 会拦住普通 AJAX POST 数据加载 | 支持同站点、限体积的 JSON／URL 编码数据请求，fetch 和 XHR 共用原生校验 |
| 渲染入口 | 开发验证曾把初始入口误拦，Chrome 错误页被当作文字 | 只接管一次初始文档请求，主框架加载错误明确失败；实际网站测试断言正文内容 |
| 短页面 | 文字不足时一直等待，再统一提示需要 JavaScript | DOM 就绪、文字稳定且网络空闲后返回可见片段；不冒充完整正文、不作为完整网页缓存 |
| 重试 | 旧失败回执可能一直复用 | 按读取策略版本及运行尝试复用失败；同次尝试不重复，新尝试可补读，成功正文保留 |
| 引用选区 | 代码文字的实色背景覆盖 Flutter 选区 | 删除字形背景，保留代码块容器；统一主题选区颜色 |
| 邮件引用 | 缩进被解析为 Markdown 代码，长链接横向溢出 | 邮件原文使用可选择、可换行的纯文本；其他格式化来源保留 Markdown |

没有按发票网站、公司名或截图中的词语写专用解析分支。生产代码不含本次站点地址；站点仅作为显式设备测试输入。

## 架构与代码审查

- `PublicWebReader` 负责文档、字符编码识别、公网地址校验及重定向；`AndroidWebRenderer` 负责短生命周期 DOM；`WebRenderTransport` 负责页面资源和数据传输。复用原来的 `WebReadWorkflow`、来源编号、统一预算及会话缓存，没有新增模型规划请求。
- 文档请求仍限制为 HTTP／HTTPS、公网实际 DNS IP、80／443 端口、最多三次重定向、HTTPS 不降级、解压后 2 MiB、单页整体 30 秒。渲染最多 18 秒，每页最多 48 次资源连接、累计解压后 12 MiB，单个资源仍不超过 2 MiB。
- WebView 的直接联网关闭；资源必须经过独立无账号凭据的客户端。只允许同源资源和原始文档明确列出的第三方脚本地址；子资源重定向不能扩大来源范围。
- Android 的请求拦截不提供 POST 正文。兼容层将同源 AJAX 的正文封装在本地拦截请求中，原生校验后提交；封装头不发给服务器。仅 JSON 和 URL 编码正文，最多 64 KiB；不同正文有不同缓存键。它用于页面脚本自动加载数据，不是点击按钮或填写表单的自动化功能。
- 没有原生 JavaScript 桥、文件／内容协议访问、文件上传、自动点击、表单提交、摄像头／麦克风／定位授权、登录 Cookie 或模型／邮箱凭据转发。CSP 放在原生响应头，阻止 frame、worker、表单及额外连接来源；渲染结束销毁 WebView 并清理网页临时存储。
- 网页脚本不可信。兼容层不等于任意网站都能访问：验证码、登录、文件下载、跨站数据 API 及纯图像内容仍有明确边界。少量可见文字只作为片段，不能证明对应图片或文件已读。
- 清除临时正文诊断、入口试验分支与重复读取路径；检查缓存命中时保留完整正文文件引用，取消后保留已成功页面，引用页返回沿用现有位置恢复。
- 不改变工具权限、草稿版本检查或发送确认，不执行 SMTP。

参考：[Android WebSettings](https://developer.android.com/reference/android/webkit/WebSettings)、[WebView 文件访问风险](https://developer.android.com/privacy-and-security/risks/webview-unsafe-file-inclusion)、[原生桥风险](https://developer.android.com/privacy-and-security/risks/insecure-webview-native-bridges)、[W3C CSP](https://www.w3.org/TR/CSP/)、[Flutter 选区样式](https://api.flutter.dev/flutter/widgets/DefaultSelectionStyle-class.html)、[OWASP 请求目标校验](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)。

## 验证结果

- Flutter：**390 项通过**；静态分析无问题。
- 原生：**284 项，282 通过、2 项真实 IMAP 条件测试跳过，0 失败**。
- Android Lint：**0 错误、13 项已有提示**。
- API36 原生网页测试：2 项通过。其中合成响应验证 GET、fetch POST、XHR POST、中文正文、无凭据转发、受限提交和短页面；真实网页测试记录正文校验及读取边界。
- API36 完整 Agent：2 项通过，包含 DSML 回归和使用现有 **doubao-seed-evolving**、合成邮件中公司介绍链接的真实请求。**12.552 秒、2 次模型请求、1 次网页读取、0 次搜索、完整回答、0 草稿、无协议泄漏**。邮件链接读取不需要额外搜索请求。
- API36 UI：通过实际点击 `[T5:S2]` 进入引用详情，再长按选中；验证浅深主题、邮件原文与代码块，返回原对话。选区端点有断言，4 张截图已人工核看。Flutter 补充 320／360／412 dp 的浅深主题回归。
- 新增回归覆盖字符编码、401／403／406／429 不渲染或自动重试、子资源来源及重定向、POST 体积／类型／缓存、旧失败策略、新尝试补读、页面片段不作为完整缓存、缓存文件引用保留和取消恢复。

### 真实网页与固定响应分开记录

| 真实对象 | 最终状态 | 可见文字 | 耗时 | 验证范围 |
|---|---|---:|---:|---|
| 诺诺公司介绍公开页 | complete | 966 字符 | 3.020 秒 | 真实动态正文包含站点名称，长度断言通过 |
| 用户提供的发票链接 | limited_content | 44 字符 | 3.365 秒 | 真实发票下载／打印入口已取得；发票明细未读取 |

耗时是这台 API36 在本次网络条件下的单次结果，不保证每次相同。旧请求头的 406 通过同链接 HTTP 探测确认；旧版缺少 JS 渲染通过代码及页面外壳确认。本次没有做旧 APK 与新 APK、相同模型输入的重复测速，不将这些结果冒充严格性能对照，也不等同于 DeepSeek APK 的实现或速度。

过程中发现并修复了初始入口误拦、短页面误报动态失败，以及一条旧加载文案断言。新 POST 单元测试起初缺少 Android JSON 测试环境，补齐 Robolectric 配置后重新执行全套通过；不将这些未通过的中间运行计入最终验收。

证据：[原生汇总](test-evidence/build38/native-summary.json)、[网页测试](test-evidence/build38/api36-web-tests.log)、[真实网页](test-evidence/build38/live-web.json)、[Agent 测试](test-evidence/build38/api36-agent-tests.log)、[真实模型](test-evidence/build38/live-agent.json)、[UI 测试](test-evidence/build38/api36-ui-tests.log)。

截图：[浅色引用选区](screenshots/build38/citation-selection-light.png)、[深色引用选区](screenshots/build38/citation-selection-dark.png)、[浅色邮件原文](screenshots/build38/mail-selection-light.png)、[深色邮件原文](screenshots/build38/mail-selection-dark.png)。

## 数据、升级与交付

API36 日常包从 37 到 38 只用相同调试证书的 `adb install -r` 覆盖安装。备份后逐表核对，**17 张表数据完全相同，既有设置文件未改变**，SQLite 完整性通过。首次使用 WebView 新增两份系统偏好元数据，已在[数据校验](test-evidence/build38/data-preserved.json)中单列，没有把全目录差异隐藏为“完全相同”。

真实模型测试用临时 Room 数据库及合成邮件；没有读取或改写日常邮箱内容。UI 自动化使用 `app.mailpilot.validation` 和 `--keep-app-running`，未对日常包运行 flutter drive，未卸载日常应用。

发布包沿用原发布证书，调试设备沿用原调试证书，两者分别校验。交付包含 APK、源码、Windows 构建脚本、本文与测试证据、截图、SHA-256；签名材料、私有链接、网页正文诊断和数据备份均不进入源码及交付包。仅清理本轮构建缓存和临时测试输入／输出，保留已有模拟器、系统镜像、用户资料和有效分析缓存。
