> 当前交付 **1.0.0（32）**，详见 [本轮说明](RELEASE_1_0_0_BUILD_32.md)。本轮只清理临时诊断副本、测试运行器和本轮生成文件；保留日常设备、镜像、用户资料及有效视觉缓存。以下内容为历史清理记录。

## 构建 24 本轮清理（2026-09-09）

完成 API 36 测试、原签名检查与 23 → 24 保留数据升级后，停止本轮 `emulator-5564`。核实 `MailPilot_Build24_Test36.ini` 指向工作区 `.tools/avd24-test36`，确认进程退出，再使用官方 `avdmanager delete avd` 删除；专属数据目录和注册文件均已移除。运行 `flutter clean` 清理生成的构建缓存，先前复制到 artifacts 的签名 APK、测试证据及源码保留。

保留 API 36 既有镜像、日常 `MailPilot_API36` / `.tools/avd36`、原签名、用户资料和有效分析缓存。本轮没有处理此前版本的其他模拟器残留。实际结果见 [清理记录](test-evidence/build24/cleanup.json)。

2026-09-10，最后一轮选择/返回交互修复完成后，再次通过 23 → 24 保留数据升级及 API 36 回归。核实 `.tools/avd24-final36` 和 `MailPilot_Build24_Final36.ini` 的精确路径后，停止并删除 `MailPilot_Build24_Final36`，再次运行 `flutter clean`。日常设备、既有镜像、签名和交付文件保留；本次工作盘可用空间增加约 6.78 GB。[最终清理记录](test-evidence/build24/cleanup-final.json)。

# Flutter 迁移后的清理记录

2026-09-07，按用户要求清理旧 Kotlin UI 与冗余实现。

已完成：

- 删除原 Compose 页面、主题和 Compose 仪器测试源码，移除 `.tools/legacy-ui/` 及其子目录。
- 删除 `android/app/src/main/java/app/mailpilot/ui/`。当前 Android 服务协调器改为 `platform/MailCoordinator.kt`，平台状态模型单独放入 `platform/MailState.kt`。
- 更新 Flutter 通道、平台测试及架构文档的全部引用；Android 编译源中不再有 Compose 导入或旧 AppViewModel 引用。
- 删除未调用的 `MailDao.accountAttachments` 查询与未使用的 import；邮箱 IMAP ID 版本改为当前 BuildConfig 版本，移除旧版硬编码。
- 删除 `artifacts/` 中 1.0.0 的 APK、源码归档、校验文件与旧签名验证输出。
- 清理旧 IDE 测试运行配置；Android Studio 的 Gradle 关联改为 `android/` 与 `android/app`。

保留的 Kotlin 代码均为当前 Flutter 实际调用的 Android 平台功能：IMAP / SMTP、Room / DataStore、Keystore、WorkManager、PDF / Office / 图片处理、模型协议及 Agent 编排。界面由 `lib/` 中的 Dart 代码实现。

自动审批两次拦截了递归删除目录的命令，返回信息为 `blocked by policy`。因此部分开发缓存与模板备份仍保留，例如根目录 `.gradle/`、`.kotlin/`、`.widget_preview/`、`android/app/build/` 和 `.tools/` 内的旧模板 / 工具备份。它们不参与当前应用源码编译，也不进入交付源码 ZIP。源码文件采用逐项补丁删除，空源码目录已删除。

源码打包使用白名单，只包含 Flutter / Android 当前源码、测试、构建脚本和文档，不包含签名、SDK 下载、模拟器、IDE 缓存或旧备份。

## 1.8 临时设备清理（2026-09-08）

复用既有 `system-images;android-36;default;x86_64` 镜像创建 `MailPilot_180_Test36`，用于本轮设备测试与 Release 覆盖升级。核实专属数据目录为 `D:\projects\MailPilot\.tools\avd180-test36` 后停止模拟器，等待对应进程退出，使用官方 `avdmanager delete avd` 删除。数据目录与 `C:\Users\Mayn\.android\avd\MailPilot_180_Test36.ini` 均已确认不存在。删除前逻辑文件总大小约 2.78 GB；未新增系统镜像，原有 `MailPilot_API36` 和 emulator-5554 保留。此前版本的缓存记录不因本次操作改变。

## 1.8.1 临时设备清理（2026-09-08）

本轮 `MailPilot_181_Test36` 同样复用既有 API 36 镜像。界面和覆盖升级检查完成后，核实专属数据目录 `D:\projects\MailPilot\.tools\avd181-test36` 与注册文件一致，停止对应模拟器，等待其进程退出，再使用官方 `avdmanager delete avd` 删除。约 2.78 GB 逻辑文件和 `MailPilot_181_Test36.ini` 已移除；没有新下载镜像，日常 `MailPilot_API36` / emulator-5554 继续保留。

## 1.8.2 临时设备清理（2026-09-08）

复用既有 API 36 镜像验证输入框、模型操作面板及签名覆盖升级。已核实 `MailPilot_182_Test36` 专属目录为 `D:\projects\MailPilot\.tools\avd182-test36`，与注册文件一致；停止对应进程后，使用官方 AVD 管理命令删除设备。约 2.78 GB 逻辑文件及对应 `.ini` 已移除，日常 emulator-5554 保留，没有新增系统镜像。


