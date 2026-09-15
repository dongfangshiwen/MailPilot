param([ValidateSet('Debug','Release','Test','Verify')][string]$Mode='Debug',[switch]$DeviceTests,[string]$Device='',[int]$ExpectedApi=0)
$ErrorActionPreference='Stop'
if($Mode -in @('Release','Verify') -and $env:ORG_GRADLE_PROJECT_mailpilotTestApplicationId) { throw '发布构建禁止使用测试包名；请先退出隔离测试环境。' }
$projectRoot=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$appVersion=[regex]::Match((Get-Content pubspec.yaml -Raw),'(?m)^version:\s*([^+\s]+)').Groups[1].Value
if(!$appVersion) { throw 'pubspec.yaml 缺少版本号' }
$jdkCandidates=@($env:MAILPILOT_JAVA_HOME,$env:JAVA_HOME,'D:\Android\Android Studio\jbr','C:\Program Files\Android\Android Studio\jbr')
$chosenJdk=$null
foreach($candidate in $jdkCandidates) {
    if($candidate -and (Test-Path -LiteralPath (Join-Path $candidate 'bin\java.exe'))) {
        $versionText=(& (Join-Path $candidate 'bin\java.exe') -version 2>&1 | Out-String)
        if($versionText -match 'version "(\d+)' -and [int]$Matches[1] -ge 17 -and [int]$Matches[1] -le 25) { $chosenJdk=$candidate; break }
    }
}
if(!$chosenJdk) { throw '需要 JDK 17–25，请设置 MAILPILOT_JAVA_HOME。' }
$env:JAVA_HOME=$chosenJdk
$flutterCommand=(Get-Command flutter -ErrorAction Stop).Source
$flutterSdk=Split-Path -Parent (Split-Path -Parent $flutterCommand)
$sdk=@($env:ANDROID_HOME,$env:ANDROID_SDK_ROOT,(Join-Path $env:LOCALAPPDATA 'Android\Sdk')) | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'platform-tools')) } | Select-Object -First 1
if(!$sdk) { throw '未找到 Android SDK，请设置 ANDROID_HOME。' }
if($DeviceTests) {
    if(!$Device) { throw '请用 -Device 指定测试设备' }
    $deviceApi=(& (Join-Path $sdk 'platform-tools\adb.exe') -s $Device shell getprop ro.build.version.sdk | Out-String).Trim()
    if($LASTEXITCODE -ne 0 -or !$deviceApi) { throw '测试设备未就绪' }
    Write-Output "Testing device $Device / API $deviceApi"
    if($ExpectedApi -gt 0 -and $deviceApi -ne [string]$ExpectedApi) { throw "设备系统版本不匹配：期望 API $ExpectedApi，实际 $deviceApi" }
}
$env:ANDROID_HOME=$sdk
function Escape-Property([string]$value) { $value.Replace('\','\\').Replace(':','\:') }
function Normalize-LocalProperties {
    # Flutter rewrites Windows drive colons without Java-properties escaping.
    $lines=Get-Content -LiteralPath android/local.properties
    $lines | ForEach-Object { $_ -replace '^(\w[\w.]*=[A-Za-z]):','$1\:' } | Set-Content -LiteralPath android/local.properties -Encoding ascii
}
Set-Content -LiteralPath android/local.properties -Value @('sdk.dir='+(Escape-Property $sdk),'flutter.sdk='+(Escape-Property $flutterSdk)) -Encoding ascii
$proxyArgs=@()
$proxy=Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
if($proxy.ProxyEnable -eq 1 -and $proxy.ProxyServer -match '^([a-zA-Z0-9.-]+):(\d+)$') {
    $hostValue=$Matches[1]; $portValue=$Matches[2]
    $proxyArgs=@("-Dhttps.proxyHost=$hostValue","-Dhttps.proxyPort=$portValue","-Dhttp.proxyHost=$hostValue","-Dhttp.proxyPort=$portValue")
    $env:JAVA_OPTS=($proxyArgs -join ' ')
    $env:GRADLE_OPTS=($proxyArgs -join ' ')
}
& $flutterCommand pub get
if($LASTEXITCODE -ne 0) { throw 'Flutter dependencies failed' }
if($Mode -in @('Release','Verify')) { & (Join-Path $PSScriptRoot 'Initialize-Signing.ps1') }
if($Mode -in @('Test','Verify')) {
    & $flutterCommand analyze
    if($LASTEXITCODE -ne 0) { throw 'Dart analysis failed' }
    & $flutterCommand test
    if($LASTEXITCODE -ne 0) { throw 'Flutter tests failed' }
    Normalize-LocalProperties
    Push-Location android
    try { & .\gradlew.bat :app:testDebugUnitTest --console=plain @proxyArgs; if($LASTEXITCODE -ne 0) { throw 'Android tests failed' } } finally { Pop-Location }
    # Flutter's Gradle compilation can rewrite local.properties again. Normalize
    # after compilation so a clean build passes the same Lint checks as a warm one.
    Normalize-LocalProperties
    Push-Location android
    try { & .\gradlew.bat :app:lintDebug --console=plain @proxyArgs; if($LASTEXITCODE -ne 0) { throw 'Android Lint failed' } } finally { Pop-Location }
}
if($DeviceTests) {
    if(!$Device) { throw '请使用 -Device 指定 adb 设备，例如 emulator-5558。设备测试逐台运行。' }
    foreach($entry in @('app_test','ui101_test','ui102_test','ui103_test','reading21_test','context22_test','scroll23_test','history25_test')) {
        & (Join-Path $PSScriptRoot 'Test-Profile.ps1') -Device $Device -Mode Debug -Target ("integration_test/"+$entry+".dart")
    }
    # Restore the normal entrypoint in the isolated test package only.
    & $flutterCommand build apk --debug --target=lib/main.dart --android-project-arg 'mailpilotTestApplicationId=app.mailpilot.validation'
    if($LASTEXITCODE -ne 0) { throw 'Native test target build failed' }
    $testManifest=(& (Join-Path $sdk 'build-tools/36.0.0/aapt.exe') dump badging build/app/outputs/flutter-apk/app-debug.apk | Out-String)
    if($LASTEXITCODE -ne 0 -or $testManifest -notmatch "package: name='app.mailpilot.validation'") { throw '拒绝安装非隔离测试包' }
    & (Join-Path $sdk 'platform-tools\adb.exe') -s $Device install -r build/app/outputs/flutter-apk/app-debug.apk
    if($LASTEXITCODE -ne 0) { throw 'Native test target installation failed' }
    & (Join-Path $sdk 'platform-tools\adb.exe') -s $Device shell am force-stop app.mailpilot.validation
    & (Join-Path $sdk 'platform-tools\adb.exe') -s $Device shell pm revoke app.mailpilot.validation android.permission.RECORD_AUDIO
    $previousSerial=$env:ANDROID_SERIAL
    $env:ANDROID_SERIAL=$Device
    Push-Location android
    try { & .\gradlew.bat :app:connectedDebugAndroidTest '-PmailpilotTestApplicationId=app.mailpilot.validation' --console=plain @proxyArgs; if($LASTEXITCODE -ne 0) { throw 'Android platform device tests failed' } } finally { Pop-Location; $env:ANDROID_SERIAL=$previousSerial }
}
if($Mode -in @('Debug','Verify')) { & $flutterCommand build apk --debug --target=lib/main.dart --android-project-arg 'mailpilotTestApplicationId=app.mailpilot.validation'; if($LASTEXITCODE -ne 0) { throw 'Debug build failed' } }
if($Mode -in @('Release','Verify')) { & $flutterCommand build apk --release --target=lib/main.dart; if($LASTEXITCODE -ne 0) { throw 'Release build failed' } }
New-Item -ItemType Directory -Path artifacts -Force | Out-Null
$variants=switch($Mode) { 'Debug' { 'debug' }; 'Release' { 'release' }; 'Verify' { 'debug'; 'release' } }
foreach($variant in $variants) {
    $apk=Join-Path $projectRoot "build\app\outputs\flutter-apk\app-$variant.apk"
    if(Test-Path -LiteralPath $apk) {
        $destination=Join-Path $projectRoot "artifacts\MailPilot-$appVersion-flutter-$variant.apk"
        Copy-Item -LiteralPath $apk -Destination $destination -Force
        $hash=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
        Set-Content -LiteralPath ($destination+'.sha256') -Value ($hash+'  '+(Split-Path -Leaf $destination)) -Encoding ascii
        Write-Output "APK: $destination"
    }
}
