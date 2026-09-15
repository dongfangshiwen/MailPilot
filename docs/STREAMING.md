> 本轮交付 **1.0.0（21）**。摘要入口、引述排版与本轮验证见 [1.0.0（21）说明](RELEASE_1_0_0_BUILD_21.md)。上一构建的 Agent 工作流与代码清理见 [构建 20](RELEASE_1_0_0_BUILD_20.md)。以下旧版本内容保留为历史记录。

# 流式回答、Markdown 与思考配置（1.2.0）

以下协议与修复继续用于 1.4.0；普通聊天和上下文整理见 [CONTEXT_MEMORY.md](CONTEXT_MEMORY.md)，实时思考、自动折叠及草稿转换见 [RELEASE_1_4.md](RELEASE_1_4.md)。流式回答不要求先绑定邮箱。

## 本次修正

`MissingPluginException … snapshot … mailpilot/actions` 表示当前 Flutter 引擎没有注册 Android 邮件服务。旧入口无条件创建 AndroidBackend，浏览器和 Widget Preview 也会调用该通道。Flutter 官方说明 [Widget Preview 基于 Web，不能访问原生平台 API](https://docs.flutter.dev/tools/widget-previewer)。

现在 `lib/main.dart` 在 Android 使用真实服务；在浏览器或桌面明确进入“界面预览”，不连接邮箱和模型。`lib/main_preview.dart` 仍可单独启动预览。Android 中通道缺失会显示中文处理提示，不会自动切换为假数据。修改原生服务后需要重新构建 APK，单纯 Hot Reload 不能加载原生修改。

设置页左上角“返回主页”回到助手，系统返回也可用。邮箱、模型编辑页先返回设置。所有主页面最大宽度 800；手机保持全宽，输入框随键盘避让，较矮窗口减少输入框最大行数。

## 厂商协议依据

本版使用 HTTPS Chat Completions 的 OpenAI 兼容协议，不使用各厂商的 Responses API 或 DashScope 原生协议。

| 服务 | 官方依据 | 实现 |
| --- | --- | --- |
| 火山引擎方舟 | [官方流式示例](https://github.com/volcengine/volcengine-python-sdk/blob/master/volcenginesdkexamples/volcenginesdkarkruntime/completions.py)、[官方增量响应类型](https://github.com/volcengine/volcengine-python-sdk/blob/master/volcenginesdkarkruntime/types/chat/chat_completion_chunk.py) | `stream: true`；追加 `delta.content`；跳过空 choices；保留 reasoning_content 和 encrypted_content 用于本次工具继续调用 |
| DeepSeek | [思考模式与流式、工具调用](https://api-docs.deepseek.com/zh-cn/guides/thinking_mode/) | 区分回答和思考增量；工具后回传完整的 assistant 协议消息，包含 reasoning_content；此前保存的对话作为参考文本，避免伪造缺失的协议字段 |
| 阿里云百炼 | [流式输出](https://help.aliyun.com/zh/model-studio/stream)、[Chat Completions 参数](https://help.aliyun.com/zh/model-studio/qwen-api-via-openai-chat-completions) | 处理 SSE、空 delta、空 choices 的用量尾包和 `[DONE]`；extra_body 所指的参数直接放在 HTTP JSON 根级 |

查阅日期：2026-09-07。云端模型及参数会更新，以对应模型控制台和官方文档为准。

## 实时输出和中断

- 对话默认请求流式，不依赖曾经通过能力测试。流式能力记录仅表示上一次测试结果。
- OkHttp 逐事件读取 SSE，支持注释、CRLF、多行 data 和跨数据包的工具参数。有界通道反压保证增量不会因界面忙而被丢弃。
- 原生状态每 32 ms 最多处理一次；首次和结构变化发送完整快照，后续发送有序的思考／正文增量，后台线程编码。Flutter 保留未变化的历史 Markdown，实际收到的突发片段最多在 80 ms 内展开；结束、取消或减少动画设置立即展示已收到全文。逐帧滚动跟随不会重启长动画，手动上翻暂停跟随。模型思考时显示“正在思考”，正文到达后显示回答。
- `[DONE]` 或明确 finish_reason 表明传输结束；达到长度限制、内容过滤、SSE error、无正文及突然断流均有提示。只有用量的尾包不会生成空消息。
- “停止回答”取消 HTTP 请求；取消和错误均保留已经收到的部分回答并标记未完成。服务未返回 SSE 时明确报错，不自动追加普通请求或重复请求。
- 工具最多 8 轮。每一轮回答重新开始显示；工具产生的草稿仍必须由用户审核后发送。

## 思考模式与档位

入口：设置 → 添加模型／模型设置 → 高级参数。选择服务商、思考模式及档位；代理地址可手动指定实际服务商。默认为自动识别服务商、跟随服务商思考设置，不给旧配置强行增加参数。

| 适配 | 思考控制 | 档位 / 预算 |
| --- | --- | --- |
| DeepSeek Chat Completions | `thinking.type` 开启／关闭 | 当前官方档位 low、high、max；默认不传档位 |
| 火山引擎方舟 | `thinking.type` 开启／关闭／模型自动判断 | minimal、low、medium、high；是否支持取决于具体模型或接入点，需测试 |
| 阿里云百炼 | `enable_thinking` | Qwen3.8 提供 low、medium、xhigh；其他 Qwen 系列提供 thinking_budget。其他已支持档位的模型提供 low、high、max，具体以模型版本为准 |
| 通用兼容服务 | `reasoning_effort` | 提供常见档位；开启且未选档位时 high，关闭时 none；模型必须支持该参数 |

阿里云档位和预算二选一，预算需小于最大输出长度。高档位通常增加等待时间与 Token 用量；部分模型不允许关闭思考。1.8 将内置能力与连接诊断分开；修改名称、思考参数保留能力，修改地址、型号或密钥只使旧连接诊断过期。“连接诊断（可选）”使用当前配置发起请求，保存和实际读图不以诊断通过为前置条件。没有服务商密钥时不会声称这些参数已真实连通。

## Markdown

使用锁定版本 `flutter_markdown_plus 1.0.12`，支持标题、加粗、列表、引用、表格、行内代码和代码块。表格与长代码可横向滚动；支持长按选择、复制 Markdown 原文、浅色和深色主题。

回答完成后，已知 `[S编号]` 可点击打开对应来源；未知编号和流式期间尚未建立来源映射的编号显示为普通文字。远程图片、模型给出的本地路径不会自动加载；网页链接点击后展示目标地址，由用户选择打开或复制。HTML 与脚本不会执行。

## 数据兼容

Room 数据库版本 1 → 2 自动迁移，只为模型增加 provider、thinkingMode、reasoningEffort、thinkingBudget 四列及默认值。保留模型密钥、邮箱、邮件、会话、草稿和发送记录。签名与包名沿用旧版，安装时选择覆盖升级。

本地 MockWebServer 测试覆盖延迟分片、思考字段、工具分片、用量尾包、断流、取消、JSON 非流式响应等；样例预览单独模拟逐段输出，用于界面测试，不代表任何真实模型连通性验证。


