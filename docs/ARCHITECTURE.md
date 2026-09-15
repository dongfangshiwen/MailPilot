> 构建 32 更新：建议摘要目标与实际空间分开，工具结果优先整理；新增可选快速整理、按账号与会话隔离的分块摘要缓存和任务输出预算。恢复、缓存边界及验证见 [当前实现说明](RELEASE_1_0_0_BUILD_32.md)。下方保留已有设计及历史说明，以本轮说明为准。

> 当前交付 **1.0.0（30）**。通用动作架构、搜索恢复及验证见 [构建 30 说明](RELEASE_1_0_0_BUILD_30.md)。

# MailPilot 架构

MailPilot 是 Flutter Android 应用。业务逻辑均在 APK 内运行，向用户配置的邮箱、HTTPS 模型、独立搜索和可选云端语音服务发起网络请求。无自建后端、OCR、模型权重、Google Play 服务、统计 SDK 或广告 SDK。

## 数据流

1. Dart / Flutter 页面通过 `MailController` 调用 MethodChannel（mailpilot/actions）；Android MainActivity 分发到 MailCoordinator 与应用内服务。EventChannel（mailpilot/state）每 32 ms 最多发送一次状态变化；连续思考／正文只发送有序增量，后台编码，结构变化发送完整快照（会话列表独立分页，仅通知历史版本），公开状态不包含凭据或加密密文。启动时先探测 snapshot 再订阅；Web／桌面使用明确标记的预览。
2. 启动只读缓存，手动刷新或用户开启后台同步才拉取邮箱。Angus Mail 优先 SORT DATE，反转为日期降序，再分页；无 SORT 时核对 UID、优先搜索近期发送/接收日期，范围不足则逐步扩展。日期索引持久缓存，已读取正文复用，按日期和 UID 降序分页；文件夹发现独立执行并缓存。邮件、附件元数据写入 Room。
3. 用户勾选邮件时默认选择可分析附件，只改变选择；提问时下载所选资料，PDF 支持默认前 10 页或显式页码。
4. Office 在手机提取文本、表格和嵌入图片；PDF 由系统 `PdfRenderer` 渲染；图片处理方向和尺寸。
5. `LocalAgent` 向所选模型提交问题；普通聊天不依赖邮箱，只有选择邮件时才追加资料。`ConversationCompressor` 按预算复用或更新早期历史摘要，并保留近期完整对话。视觉主模型直接接收未缓存图片；文字主模型采用视觉助手。VisualEvidence 与 ProcessedMaterial 在当前账号和会话内持久复用，保留原问题、文件指纹、关联组和不确定性。
6. 模型默认 `stream: true`；SSE 增量更新 Flutter Markdown。`ReasoningTrace` 将可读思考与正文分开，工具后回传本轮完整协议消息；密文不进入显示状态。Room v9 保存可读思考、耗时、停止状态、草稿确认快照、文件夹和日期索引，通过自动迁移保留历史。取消和异常保留部分回答。CommonMark 在 AI 草稿进入编辑器／本地库前转换为纯文本；用户修改后预览与 SMTP 使用同一草稿版本，只有聊天卡片的确认按钮、紧接卡片的明确确认短句或保留的旧预览确认入口能调用发送服务。模型没有发送工具。

## 模块

| 模块 | 职责 |
| --- | --- |
| `data` | Room 实体和 DAO、DataStore 设置、Android Keystore 凭据加密 |
| `mail` | TLS 邮箱会话、MIME 解析、按 UID 同步、附件下载、发送状态和已发送副本 |
| `attachments` | ZIP/XML Office 读取、图片方向与缩放、PDF 页面渲染 |
| `ai` | HTTPS 兼容模型 API、SSE 解析、能力测试、资料范围和工具编排 |
| `ai/ConversationCompressor` | 滚动摘要、历史边界、分批整理、完整原文保留及失败保护 |
| `ai/ReasoningOptions` / `lib/model_options.dart` | 服务商思考模式、档位、预算参数与表单选项 |
| `lib/` | Dart / Flutter 对话、邮件、草稿、配置、附件预览和主题 |
| `android/.../platform/MailCoordinator` | Android 服务状态协调，无 Compose UI |
| `MainActivity` / `BridgeCodec` | Flutter 平台通道、状态编解码、SAF 文件选择与导出 |

## 搜索工作流

构建 31 增加 `PreparedModelRequest` 与统一逻辑输入预算；`CompressionPacker` 根据完整整理请求动态装填，并用来源块／字符游标恢复。`EvidenceView` 将模型可见摘录与本轮本地全文分开，受限 `read_evidence` 只读取当前授权来源。文本适配器反馈可读内容，移除 JSON 多层包装。详见 [构建 31](RELEASE_1_0_0_BUILD_31.md)。

AgentActions 统一声明工具和参数约束。原生调用与文本 JSON 协议接入同一有界循环，由模型结合完整预算上下文解析任务，不再使用自然语言关键词路由或独立搜索规划器。显式写成邮件与重拟入口保留确定性工作流。SearchWorkflow 只执行已校验的公开查询；逐条查询和动作交换分别保存检查点，手动重试复用成功步骤。模型不拥有发送工具，确认发送由独立应用状态机控制。详见构建 30 说明。

此流程采用任务路由与分阶段校验，不赋予模型更多邮箱权限，不新增后台服务或无限自主循环。参考及取舍见本轮说明。

## 发送状态

Room 当前版本 9。8 → 9 增加会话活动／置顶时间及视觉证据、处理文件缓存；7 → 8 保存模型诊断与消息结果状态；6 → 7 增加手机文件等记录。本轮沿用 JSON 和 DataStore，不增加表。历史迁移：5 → 6 增加文件夹同步游标、正文状态和每轮资料快照。3 → 4 增加可读思考与草稿链接；4 → 5 增加日期索引、文件夹、正文错误和确认卡片快照。1 → 2 为模型增加思考设置四列；2 → 3 为会话增加摘要、最后已整理消息 ID 和已整理条数。自动迁移不清空用户表。摘要成功后通过带会话范围条件的 UPDATE 保存，不删除原文，也不会重建已经删除的会话。厂商参数见 [STREAMING.md](STREAMING.md)，压缩机制见 [CONTEXT_MEMORY.md](CONTEXT_MEMORY.md)。

`DRAFT → SENDING → SENT / FAILED / UNKNOWN`。发送记录以草稿 ID 和版本建立唯一索引。确认后原子写入记录和状态，然后连接 SMTP。未进入 SMTP 发送阶段的失败标记 FAILED；进入发送但未收到明确结果时标记 UNKNOWN，不自动重试。应用重启将遗留 SENDING 标记 UNKNOWN。用户核实后才能恢复草稿或标记发送成功。

SMTP 成功确认后先持久化 SENT，再尝试保存 IMAP 已发送副本；归档失败不改变已发送事实。远端副本使用 Message-ID 查重。SMTP 本身不支持严格 exactly-once，结果不确定时需要人工核实。

## 资料隔离

检索工具只向模型返回主题、发件人、时间和附件数量，正文预览保留在手机。选中后的正文与附件才可进入分析。账号和附件归属在应用内再次检查。分析已选资料时不提供检索工具，即使模型伪造检索调用，应用也会拒绝。若要再次检索，清空当前选择即可。工具没有发送、删除或任意文件读取能力。更改选择保留当前会话和已有分析，实际读取范围以每轮快照为准，来源按轮次区分。邮件聊天按账号隔离，未绑定邮箱的普通聊天独立保存。没有邮箱时不提供邮箱工具，也拒绝模型自行返回的工具调用。摘要请求不开放工具，结果仅作为历史参考，不提升权限。

## 范围与资源限制

- 首次每个文件夹最新 50 封、后续按 UID 增量同步；默认关闭后台同步，主动开启后仅同步，不调用模型。
- 单附件下载／分析 20 MB；单封发送附件总量 20 MB。服务商可能有更低限制。
- Office 解压读取总量 100 MB、10000 个 ZIP 条目、300000 个 XML 节点、80 张嵌入图片；拒绝外部关系和 DTD。
- Office 读取正文和表格等结构内容，不执行宏或公式；不提供完整 Office 排版、矢量图表与 SmartArt 渲染。
- PDF 默认选择前 10 页，单次最多 20 页；每轮最多 20 张视觉资料，按厂商限额与完整请求体预算规划；不再固定四张分批，超限需用户选择处理方式。图片最长边压缩到 1600 像素。
- 文字资料最多 24 万字符，长内容分组摘要，最多 24 组；超限时明确要求缩小范围。
- Agent 最多 8 轮工具调用，每轮最多 4 个工具。
- 已知官方型号自动匹配上下文，其余手动配置；统一预算按 95% 触发、60% 目标整理，保留最近两轮完整对话和原始记录，连接诊断可选。

## 本地安全与备份

API Key 和邮箱授权码由 Android Keystore AES-GCM 加密。邮箱数据库和文件属于应用私有目录，禁止云备份和设备迁移。邮件使用安全文本呈现，不执行 HTML 脚本或加载远程跟踪图片。应用不输出密钥或邮件正文到日志。

APK 发布签名保存在开发机 `.signing/`，与用户手机上的凭据无关。该目录必须单独安全备份，不能提交版本库。

## 迁移与预览隔离

1.1.0 保留包名 app.mailpilot、原发布签名、Room schema 1 和 Keystore alias，支持覆盖升级。可见页面全部由 Flutter 构建，Kotlin 仅实现 Android 平台服务。lib/main_preview.dart 的样例后端只在显式预览与 UI 测试时使用，不被正式 main.dart 导入。项目不宣称 iOS 或 Web 邮箱功能支持。



## 1.6 同步与草稿写入

SyncScheduler 通过账号唯一 WorkManager 任务异步同步全部文件夹；MailCoordinator 只观察状态和 Room 缓存，不占用全局 busy。首次每文件夹最新 50 封，头部及附件元数据先落库，正文随后按小批补齐。SyncCursor 在元数据提交后推进 UID；待补正文独立保留状态，取消或进程恢复后可继续补齐。稳定 UIDVALIDITY 下只拉新 UID，核对已缓存 UID 的 FLAGS 与删除状态。加载更多和服务器搜索独立于缓存筛选。

Agent 对草稿修改先在本轮内暂存，模型完整返回才保存。重拟采用结构化正文输出并保留地址与附件；显式指定的新地址经当前用户输入核对。saveDraft 检查旧版本和状态，拒绝覆盖过期版本、已删除草稿及发送中记录。保存后生成新的不可变确认卡片，SMTP 发送仍只由用户触发。

## 1.7 扩展

- `ChatRequestOptions` 与 `TurnSnapshot.optionsJson/localJson` 保存每轮思考、搜索和手机资料快照；`ChatEntry.action/targetAnswerId` 分离显示消息与按回答 ID 起草的动作。
- `local_materials` 通过会话外键级联删除；文件保存在私有 materials 目录。统一 `SourceChunk.kind/url` 区分 mail/local/web/answer，旧来源 JSON 默认 mail。
- `DirectWebSearchClient` 适配火山 Filter/ContentFormats 和博查 query/summary。每个 web_search 动作最多两条查询，每条返回五条、去重最多八条来源；AgentActions 选择动作，SearchWorkflow 校验关键词并处理缓存与恢复。错误不伪装为已联网回答。
- `DraftReviewState` 向 Flutter 返回可发送状态、阻止原因和操作，`ChatSendGate` 与 SMTP 校验复用正文/地址条件；仍进行版本 CAS 和发送结果不确定保护。
- `AndroidSpeechInput` 使用 Android SpeechRecognizer 或 AudioRecord + QwenAsrClient；独立 `mailpilot/speech` 事件通道只返回语音状态和文本，不接入 Agent 或发送接口。录音在主线程控制，PCM 文件写入与 HTTP 请求在后台执行，取消终止请求并回收临时文件。
- 搜索和语音独立配置保存在 DataStore，密钥加密后写入，状态桥仅返回 hasSecret。无新增 SDK 依赖。


## 1.8 能力、视觉协作与恢复

`ModelCapabilityResolver` 提供带官方来源与日期的离线目录、连接身份和三态视觉声明。`VisionRouter` 决定当前型号、固定助手、同接口视觉配置及官方同厂商默认助手；默认路由仅复制相同接口和密钥，拒绝未知代理及非标准套餐地址的自动搭配。`VisionReader` 最多四图一批，缺失或重复编号只逐图补读一次，来源由客户端绑定。主模型只收到已选图像的观察文字；辅助请求不继承主模型思考参数。

`FailureInfo` 将服务错误归类为权限、配置、图片不支持、思考参数、网络、限流、结果格式等，UI 根据恢复动作显示入口。只有明确图片不支持才尝试下一条视觉路由。错误在原回答中显示。重试读取原 `TurnSnapshot` 的资料、页码、问题和起草动作，同时使用当前配置；复用回答 ID 和轮次来源，不新增问题气泡。发送授权机制不变。

Room 7→8 自动迁移添加连接诊断、凭据版本、结果状态、失败详情、实际视觉型号和轮次请求元数据。旧 false 标记解析为未知而非禁用。诊断与公开平台状态均不输出密钥。




