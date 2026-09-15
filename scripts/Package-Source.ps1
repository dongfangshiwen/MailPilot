$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
. (Join-Path $PSScriptRoot 'Zip-Helpers.ps1')
$appVersion=[regex]::Match((Get-Content pubspec.yaml -Raw),'(?m)^version:\s*([^+\s]+)').Groups[1].Value
if(!$appVersion) { throw 'pubspec.yaml 缺少版本号' }
$output=Join-Path $projectRoot "artifacts\MailPilot-$appVersion-flutter-source.zip"
New-Item -ItemType Directory -Path (Split-Path -Parent $output) -Force | Out-Null
$allowedFiles=@('README.md','AGENTS.md','.gitignore','.gitattributes','.metadata','pubspec.yaml','pubspec.lock','l10n.yaml','analysis_options.yaml','android/settings.gradle.kts','android/build.gradle.kts','android/gradle.properties','android/gradlew','android/gradlew.bat','android/app/build.gradle.kts','android/app/proguard-rules.pro')
$allowedFolders=@('lib','test','integration_test','test_driver','web','android/app/src','android/app/schemas','android/gradle/wrapper','scripts','docs','design-system')
$files=@($allowedFiles | ForEach-Object { Get-Item -LiteralPath (Join-Path $projectRoot $_) })
foreach($folder in $allowedFolders) { $files+=@(Get-ChildItem -LiteralPath (Join-Path $projectRoot $folder) -File -Recurse) }
# An allowlist deliberately excludes local configuration, credentials, signing material and caches.
$stream=[IO.File]::Open($output,[IO.FileMode]::Create)
try {
    $zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach($file in ($files | Where-Object { $_.Name -ne 'GeneratedPluginRegistrant.java' } | Sort-Object FullName -Unique)) {
            $relative=$file.FullName.Substring($projectRoot.Length+1).Replace('\','/')
            Add-ZipFile -Archive $zip -Source $file.FullName -EntryName $relative
        }
    } finally { $zip.Dispose() }
} finally { $stream.Dispose() }
$hash=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath ($output+'.sha256') -Value ($hash+'  '+(Split-Path -Leaf $output)) -Encoding ascii
Write-Output "Source archive: $output"
