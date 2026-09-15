> 当前交付 **1.0.0（32）**。摘要预算修复、快速整理与会话隔离、代码审查与验证见 [本轮说明](RELEASE_1_0_0_BUILD_32.md)。


# 交付内容

- `MailPilot-1.0.0-flutter-release.apk`：Android 8.0+ 正式签名通用安装包。
- `MailPilot-1.0.0-flutter-source.zip`：当前 Flutter / Android 服务源码、测试与 Windows 脚本。
- `MailPilot-1.0.0-flutter-delivery.zip`：安装包、源码包、各自 SHA-256、使用说明、设计规范、截图和测试证据的合集。

每个归档和 APK 都有同名 `.sha256` 校验文件。可在 PowerShell 执行 `Get-FileHash 文件路径 -Algorithm SHA256` 与其比较。

源码包不包含发布私钥。开发机 `.signing/` 需要由项目持有人单独安全备份，详情见 README。清理范围及被自动审批拦截的缓存目录操作见 CLEANUP.md。

再次构建后运行 `scripts/Package-Delivery.ps1` 可重建交付包。实际邮箱与模型连接需要用户自行配置，未使用样例测试结果替代真实连通性验收。




