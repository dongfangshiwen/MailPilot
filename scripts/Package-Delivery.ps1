$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
& (Join-Path $PSScriptRoot 'Package-Source.ps1')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
. (Join-Path $PSScriptRoot 'Zip-Helpers.ps1')
$appVersion=[regex]::Match((Get-Content pubspec.yaml -Raw),'(?m)^version:\s*([^+\s]+)').Groups[1].Value
if(!$appVersion) { throw 'pubspec.yaml 缺少版本号' }
$names=@("MailPilot-$appVersion-flutter-release.apk","MailPilot-$appVersion-flutter-source.zip")
foreach($name in $names) {
    $file=Join-Path $projectRoot "artifacts\$name"
    $expected=((Get-Content -LiteralPath ($file+'.sha256') -Raw).Trim() -split '\s+')[0]
    if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) { throw "Checksum mismatch: $name" }
}
$output=Join-Path $projectRoot "artifacts\MailPilot-$appVersion-flutter-delivery.zip"
$stream=[IO.File]::Open($output,[IO.FileMode]::Create)
try {
    $zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach($name in $names) {
            foreach($suffix in @('','.sha256')) {
                Add-ZipFile -Archive $zip -Source (Join-Path $projectRoot "artifacts\$name$suffix") -EntryName ($name+$suffix)
            }
        }
        Add-ZipFile -Archive $zip -Source (Join-Path $projectRoot 'README.md') -EntryName 'README.md'
        foreach($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'docs') -File -Recurse) {
            $relative=$file.FullName.Substring($projectRoot.Length+1).Replace('\','/')
            Add-ZipFile -Archive $zip -Source $file.FullName -EntryName $relative
        }
    } finally { $zip.Dispose() }
} finally { $stream.Dispose() }
$hash=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath ($output+'.sha256') -Value ($hash+'  '+(Split-Path -Leaf $output)) -Encoding ascii
Write-Output "Delivery archive: $output"
