$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$signingDir=Join-Path $projectRoot '.signing'
$config=Join-Path $signingDir 'release.properties'
if(Test-Path -LiteralPath $config) { Write-Output 'Using existing local release signing key.'; return }
$keytool=Join-Path $env:JAVA_HOME 'bin\keytool.exe'
if(!(Test-Path -LiteralPath $keytool)) { throw 'Run through Build.ps1 or set JAVA_HOME first.' }
New-Item -ItemType Directory -Path $signingDir -Force | Out-Null
$keyfile=Join-Path $signingDir 'mailpilot-release.p12'
if(Test-Path -LiteralPath $keyfile) { throw 'Signing key exists without its properties file. Restore release.properties; do not overwrite the key.' }
$randomBytes=New-Object byte[] 32
$rng=[Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($randomBytes) } finally { $rng.Dispose() }
$password=[Convert]::ToBase64String($randomBytes)
$env:MAILPILOT_SIGNING_PASSWORD=$password
try {
    & $keytool '-genkeypair' '-keystore' $keyfile '-storetype' 'PKCS12' '-alias' 'mailpilot' '-keyalg' 'RSA' '-keysize' '3072' '-validity' '10000' '-dname' 'CN=MailPilot, OU=Android, O=MailPilot, C=CN' '-storepass:env' 'MAILPILOT_SIGNING_PASSWORD' '-keypass:env' 'MAILPILOT_SIGNING_PASSWORD'
    if($LASTEXITCODE -ne 0) { throw 'Release key generation failed.' }
    @('storeFile=.signing/mailpilot-release.p12',('storePassword='+$password),'keyAlias=mailpilot',('keyPassword='+$password)) | Set-Content -LiteralPath $config -Encoding ascii
    Write-Output 'Created .signing/release.properties and release key. Back up the .signing directory securely; do not commit it.'
} finally { Remove-Item Env:\MAILPILOT_SIGNING_PASSWORD -ErrorAction SilentlyContinue; $password=$null }
