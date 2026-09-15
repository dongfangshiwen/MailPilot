param([string]$Device='emulator-5554',[ValidateSet('Profile','Debug')][string]$Mode='Profile',[string]$Target='integration_test/agent33_test.dart')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
$previousScreens=$env:MAILPILOT_SCREENSHOT_DIR
if($Target -notmatch '^integration_test/[a-zA-Z0-9_]+\.dart$') { throw '测试入口必须位于 integration_test' }
$variant=$Mode.ToLowerInvariant()
$modeFlag='--'+$variant
$apk="build/app/outputs/flutter-apk/app-$variant.apk"
try {
    # Never let Flutter's test cleanup uninstall the daily MailPilot package.
    $buildNumber=[regex]::Match((Get-Content pubspec.yaml -Raw),'(?m)^version:\s*[^+]+\+(\d+)').Groups[1].Value
    if(!$buildNumber) { throw 'Missing build number' }
    $env:MAILPILOT_SCREENSHOT_DIR=Join-Path $root ('docs/screenshots/build'+$buildNumber)
    & flutter build apk $modeFlag --target-platform android-x64 ('--target='+$Target) --android-project-arg 'mailpilotTestApplicationId=app.mailpilot.validation'
    if($LASTEXITCODE -ne 0) { throw '隔离测试构建失败' }
    $sdk=if($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android/Sdk' }
    $manifest=(& (Join-Path $sdk 'build-tools/36.0.0/aapt.exe') dump badging $apk | Out-String)
    if($LASTEXITCODE -ne 0 -or $manifest -notmatch "package: name='app.mailpilot.validation'") { throw '拒绝安装：测试 APK 不是隔离包名。' }
    & flutter drive $modeFlag --keep-app-running ('--use-application-binary='+$apk) --driver=test_driver/integration_test.dart ('--target='+$Target) -d $Device
    if($LASTEXITCODE -ne 0) { throw '隔离界面测试失败' }
} finally {
    $env:MAILPILOT_SCREENSHOT_DIR=$previousScreens
}
