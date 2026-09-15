# 邮箱配置与官方指引

核对日期：2026-09-09。设置 → 添加邮箱，选择服务商后点击“如何配置邮箱”。底部抽屉提供简要步骤、服务器及官方网页入口。关闭或返回保留已填写的账号与凭据；打开网页仅提交固定官方 URL，不附加表单内容，不自动同步邮件。

| 邮箱 | IMAP / SSL | SMTP / SSL | 配置要点与官方说明 |
|---|---|---|---|
| QQ | imap.qq.com:993 | smtp.qq.com:465 | 网页设置 → 账号与安全 → 安全设置，开启服务并生成授权码。[授权码帮助](https://help.mail.qq.com/detail/106/985) |
| 163 | imap.163.com:993 | smtp.163.com:465 | 开启 IMAP/SMTP 并取得客户端授权码。[网易官方帮助中心](https://help.mail.163.com/)；该链接为帮助首页，可搜索“授权码”或“IMAP” |
| 阿里企业 | imap.qiye.aliyun.com:993 | smtp.qiye.aliyun.com:465 | 管理员允许第三方客户端，启用安全密码后使用安全密码。[访问权限](https://help.aliyun.com/zh/document_detail/606337.html)、[三方客户端安全密码](https://help.aliyun.com/zh/document_detail/444269.html)、[服务器与地区差异](https://help.aliyun.com/zh/document_detail/36576.html) |
| 阿里个人 | imap.aliyun.com:993 | smtp.aliyun.com:465 | 适用于免费个人邮箱；企业域名账号选择企业预设。[官方服务器参数](https://help.aliyun.com/zh/document_detail/465307.html) |

企业域名本身不能确定服务商。自定义邮箱由管理员提供地址、端口、加密方式及凭据，不猜测官方链接。阿里香港地区或企业指定服务器可在高级设置调整。连接测试验证登录，不发送测试邮件；成功保存不代表服务商一定允许所有文件夹访问。

指引使用本地目录，不在进入页面时联网拉取；只有用户点击链接才打开浏览器。网页步骤可能随厂商调整，遇到差异以官方页面和管理员策略为准。UI 验证覆盖 320／360／412 dp、深浅色、1.0／1.6／2.0 字体；本轮未使用真实邮箱凭据重新验证登录。
