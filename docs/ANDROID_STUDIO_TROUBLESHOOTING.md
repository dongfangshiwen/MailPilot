# Android Studio 模拟器黑屏排查

## 2026-09-08 排查记录

设备为现有 `MailPilot_API36`（API 36 / x86_64），应用为 1.8.0（10）。黑屏期间应用进程在线，Dart 入口为 `package:mailpilot/main.dart`，未暂停；Flutter 的首帧生成、首帧栅格化和组件树就绪状态均为 true。ADB 截屏也为黑屏，因此并非仅 Android Studio 嵌入显示面板的问题。应用日志未发现致命异常。

单独重启应用无效，临时关闭 Impeller 也无效。保留原 APK 和全部应用数据，冷启动模拟器并显式配置 SwiftShader 后，首页、设置页及返回首页均正常。问题定位在模拟器图形/恢复状态；现有证据不能进一步断言一定由某个显卡驱动或单一快照文件损坏引起。

原 AVD 配置为 `hw.gpu.enabled=no`、`hw.gpu.mode=auto` 并启用 Quick Boot；实际运行时生成的硬件配置已回退至 SwiftShader。修复将设置明确为以下值，并避免继续恢复旧运行状态：

```ini
hw.gpu.enabled=yes
hw.gpu.mode=swiftshader
fastboot.forceColdBoot=yes
fastboot.forceFastBoot=no
```

`hw.gpu.enabled=yes` 表示启用模拟图形设备，配合 `swiftshader` 仍为软件渲染，不代表强制使用宿主机独立显卡。

本机文件为 `D:\projects\MailPilot\.tools\avd36\config.ini`，修改前备份为 `.tools/avd36-config-before-black-screen-fix.ini`。本次未重装 APK、未清除应用数据、未修改 Flutter 渲染配置，应用 UID 和安装时间保持不变。

## 下次遇到时

1. 在 Android Studio 的 Device Manager 停止该模拟器，打开设备右侧 **⋮ → Cold Boot Now**（部分版本显示 Cold Boot）。它重新启动系统，不清除已安装应用和应用数据。
2. 如果仍然黑屏，停止模拟器，进入该设备 **Edit → Additional Settings / Emulated Performance → Graphics**，选择 **Software**，保存后冷启动。菜单位置可能随 Android Studio 版本变化。固定冷启动通常比 Quick Boot 慢，但不会反复恢复旧状态。
3. 确认系统桌面正常后再启动 MailPilot。开发调试时打开项目根目录，选 Flutter 的 `main.dart` 运行配置；`main_preview.dart` 是样例预览入口。
4. 若系统桌面正常而只有 MailPilot 仍黑屏，在 Logcat 选择 `app.mailpilot` 检查 `AndroidRuntime`、`flutter`、`FlutterJNI`，保留日志后定位。不要反复卸载或清数据。

**Wipe Data 会删除模拟器里的账号配置、聊天及其他应用数据，不作为此类黑屏的首选操作。**

Android 官方建议在自动/硬件图形模式不兼容时使用软件渲染，支持 `swiftshader` 模式，参见 [图形加速配置](https://developer.android.com/studio/run/emulator-acceleration) 和 [模拟器故障排查](https://developer.android.com/studio/run/emulator-troubleshooting)。
