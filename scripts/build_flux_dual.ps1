param()
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RepoRoot
. (Join-Path $RepoRoot "scripts\env.ps1")

$appDir = Join-Path $RepoRoot "apps\flux"
$dist = Join-Path $RepoRoot "dist"
$signingProps = Join-Path $RepoRoot "signing\keystore.properties"
$signingJks = Join-Path $RepoRoot "signing\zibashu-upload.jks"

if (-not (Test-Path $appDir)) { Write-Error "Missing apps\flux" }
if (-not (Test-Path $signingJks) -or -not (Test-Path $signingProps)) {
    Write-Error "Missing release keystore. Expected:`n  $signingJks`n  $signingProps"
}

New-Item -ItemType Directory -Path $dist -Force | Out-Null

function Get-PubspecVersion([string]$pubspecPath) {
    $text = Get-Content $pubspecPath -Raw
    if ($text -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)') {
        return @{ name = $Matches[1]; code = [int]$Matches[2] }
    }
    throw "Could not parse version from $pubspecPath"
}

$ver = Get-PubspecVersion (Join-Path $appDir "pubspec.yaml")
$base = "flux-v$($ver.name)"
Write-Host "`n=== Flux $($ver.name)+$($ver.code) dual build (HULK foundation) ===" -ForegroundColor Cyan

Set-Location $appDir
flutter pub get | Out-Host

# Flutter/Java may write warnings to stderr; do not treat as terminating errors.
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'

Write-Host "`n[1/2] Building warehub release APK..." -ForegroundColor Yellow
& flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed ($LASTEXITCODE)" }
$apkSrc = Join-Path $appDir "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkSrc)) { throw "APK missing: $apkSrc" }
Copy-Item $apkSrc (Join-Path $dist "$base-warehub.apk") -Force
Copy-Item $apkSrc (Join-Path $dist "$base.apk") -Force

Write-Host "`n[2/2] Building Play Store App Bundle (AAB)..." -ForegroundColor Yellow
& flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { throw "flutter build appbundle failed ($LASTEXITCODE)" }
$aabSrc = Join-Path $appDir "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $aabSrc)) { throw "AAB missing: $aabSrc" }
Copy-Item $aabSrc (Join-Path $dist "$base-play.aab") -Force

$ErrorActionPreference = $prevEap

$common = @{
    slug = "flux"
    name = "Flux"
    packageId = "com.zibashu.flux"
    versionName = $ver.name
    versionCode = $ver.code
    family = "ziBashu"
    kind = "tool"
    blurb = "Flux VPN - ziBashu-linked private network (foundation, locked)."
    website = "https://zibashu4.com"
    codename = "HULK"
    locked = $true
    signed = $true
}

$warehubMeta = $common.Clone()
$warehubMeta.channel = "warehub"
$warehubMeta.artifact = "$base-warehub.apk"
$warehubMeta.format = "apk"
($warehubMeta | ConvertTo-Json) | Set-Content (Join-Path $dist "$base-warehub.json") -Encoding UTF8

$playMeta = $common.Clone()
$playMeta.channel = "play"
$playMeta.artifact = "$base-play.aab"
$playMeta.format = "aab"
($playMeta | ConvertTo-Json) | Set-Content (Join-Path $dist "$base-play.json") -Encoding UTF8

Write-Host "`nDone:" -ForegroundColor Green
Write-Host "  $(Join-Path $dist "$base-warehub.apk")"
Write-Host "  $(Join-Path $dist "$base-play.aab")"
