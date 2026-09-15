[CmdletBinding()]
param([switch]$WebServer, [switch]$Machine)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterCommand = Get-Command flutter -ErrorAction Stop
$previewRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('MailPilot-WidgetPreview-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $previewRoot | Out-Null
foreach ($name in @('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'lib', 'web')) {
    $sourcePath = Join-Path $projectRoot $name
    if (Test-Path -LiteralPath $sourcePath) {
        Copy-Item -LiteralPath $sourcePath -Destination $previewRoot -Recurse
    }
}
Write-Host "Widget Preview workspace: $previewRoot"

Push-Location -LiteralPath $previewRoot
try {
    # Keep Flutter's recursive watcher away from the running AVDs in .tools.
    # Copy only preview sources, then use the dependencies already cached locally.
    & $flutterCommand.Source pub get --offline
    if ($LASTEXITCODE -ne 0) {
        throw 'Preview dependencies are missing from the local pub cache.'
    }
    $previewArgs = @('widget-preview', 'start', '--offline')
    if ($WebServer) { $previewArgs += '--web-server' }
    if ($Machine) { $previewArgs += '--machine' }
    & $flutterCommand.Source @previewArgs
    if ($LASTEXITCODE -ne 0) {
        throw 'Widget Preview did not start. Check the Flutter output above.'
    }
} finally {
    Pop-Location
}
