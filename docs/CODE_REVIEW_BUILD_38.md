# MailPilot 1.0.0（38）代码复查

审查日期：2026-09-12。范围为本轮动态网页读取、页面资源传输、正文缓存和失败重试，以及引用详情的选区改动。

发现 **4 项可复现问题**，其中两项 P1、两项 P2。本次是审查及本地复现，生产代码和已交付 APK 未修改；这些问题尚未修复。之前的全套测试通过，不能替代这四项缺失的边界覆盖。

后续处理：上述为构建 38 的历史复现结果；修复与回归结果见 [构建 39](RELEASE_1_0_0_BUILD_39.md)。

## 1. P1：同源 POST 缺少操作授权边界

位置：`android/app/src/main/java/app/mailpilot/services/WebRenderTransport.kt:31–41`，以及 `AndroidWebRenderer.kt` 中的 `PAGE_DATA_COMPAT`。

兼容层把页面发起的任意同源 JSON／URL 编码 POST 转成原生 POST，只检查来源、类型和体积。相同来源、没有 Cookie，并不代表请求只读取数据。页面可从其 URL 或脚本中获得访问令牌，再调用取消、确认或发送等接口；这些请求不经过 Agent 的操作授权检查。CSP 的 `form-action 'none'` 也没有约束这条 AJAX 兼容路径。

本地复现向合成地址 `/record/cancel` 提供合成令牌及 `action=cancel`，MockWebServer 收到了 POST。没有访问真实网站或执行真实取消操作。这证明请求会发出；具体远端是否改变状态取决于目标接口的权限规则。

建议把页面数据加载与可能写入的请求分开授权，不能仅以 JSON、表单编码或同源推断只读。未经可信能力声明或明确授权的写请求应返回受限状态；相关判断应在原生传输层落实，不能仅依赖页面脚本包装或提示词。

## 2. P1：用字符数判断正文完整，会缓存加载占位内容

位置：`android/app/src/main/java/app/mailpilot/services/PublicWebReader.kt:44`；动态分支另见 `AndroidWebRenderer.kt:39–43`。

静态解析只要得到至少 40 个字符，就返回 `complete`，后续不会执行动态渲染。带有 `aria-busy=true`、约 100 字加载提示和正文脚本的页面，在真实正文尚未产生时便会被接受。`WebReadWorkflow` 随后将其存成 `webpage`，同会话复用时跳过再次读取。

本地复现中，合成加载外壳返回 `complete`，渲染器调用次数为 0。动态分支也只要求文字稳定且至少 80 个字符；资源失败或加载占位仍有机会被当成完整正文。

建议将“取得可见文字”和“正文加载完成”分开表示；结合页面就绪、忙碌标记和必要资源加载结果判定，无法确认时保留片段而不写入完整缓存。补充失败资源、长占位文字以及旧误判缓存的恢复覆盖。

## 3. P2：12 MiB 累计上限没有限制实际下载

位置：`android/app/src/main/java/app/mailpilot/services/WebRenderTransport.kt:58–61`。

代码先完整读取一个资源，再累加字节数；累计超限后只丢弃该响应，下一次调用仍继续发请求和下载。单资源超过 2 MiB 时还会在累计前退出，使这部分实际读取量没有计入总量。

本地连续请求 8 个各 2 MiB 的合成资源：第 7、8 个结果被丢弃，但 8 次网络请求全部发生，累计读取了 16 MiB。当前 48 次请求上限仍提供次数边界，但它不能替代所宣称的 12 MiB 流量上限。

建议在读取流时逐块扣减共享预算，并在建立新连接前检查剩余额度。额度耗尽时取消活动连接、拒绝后续请求，返回明确的资源预算状态；失败或超大的响应所消耗的字节也应计算。

## 4. P2：Content-Type 解析异常越过错误处理

位置：`android/app/src/main/java/app/mailpilot/services/WebRenderTransport.kt:41`。

`decodePost` 对类型只校验 MIME 前缀、长度及换行符，例如 `application/json; broken` 能通过该层。随后 `toMediaType()` 抛出 `IllegalArgumentException`，但执行位置在 `try` 块之前，所以没有转成受限或失败结果，而是直接向 WebView 拦截回调抛出。

本地复现确认异常向调用方传播，且没有发出网络请求。本次未在 API36 验证该异常是否导致进程退出，因此不把“应用必然崩溃”作为结论。

建议在参数验证阶段安全解析为 `MediaType` 并复用解析结果，把请求构建纳入统一错误边界；添加异常 MIME 参数的回归。

## 复现与审查边界

使用 Robolectric、OkHttp 和 MockWebServer 运行 4 项专门的审查探针。**4 项复现断言通过表示当前缺陷已被复现，不表示缺陷已修复。**

证据：[JUnit 结果](test-evidence/build38-review/probes.xml)、[运行日志](test-evidence/build38-review/probes.log)、[探针源码](test-evidence/build38-review/Review38AuditProbeTest.kt.txt)。探针通过临时测试文件运行，结束后移出正式测试源码目录，避免把验证当前缺陷的断言当成长期正确行为测试。

本次未新增真实厂商请求、未安装或卸载应用、未改动日常模拟器数据。生产文件和发布 APK 与审查前保持一致；本轮生成的构建缓存已清理。

引用选区改动、主题颜色和邮件原文换行的相关实现未发现新的高置信度问题；本次没有重新执行 UI 设备验收，也不把本轮审查称为整个仓库的完整安全审计。
