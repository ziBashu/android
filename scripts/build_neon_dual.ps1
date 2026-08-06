# Build Neon Chronos as two release products:
#   1) Normal / warehub APK  -> dist/neon_chronos-vX.Y.Z-warehub.apk
#   2) Play Store AAB       -> dist/neon_chronos-vX.Y.Z-play.aab
#
# Usage:
#   . .\scripts\env.ps1
#   .\scripts\build_neon_dual.ps1

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RepoRoot
. (Join-Path $RepoRoot "scripts\env.ps1")

$appDir = Join-Path $RepoRoot "apps\neon_chronos"
$dist = Join-Path $RepoRoot "dist"
$signingProps = Join-Path $RepoRoot "signing\keystore.properties"
$signingJks = Join-Path $RepoRoot "signing\zibashu-upload.jks"

if (-not (Test-Path $appDir)) { Write-Error "Missing apps\neon_chronos" }
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
$base = "neon_chronos-v$($ver.name)"
Write-Host "`n=== Neon Chronos $($ver.name)+$($ver.code) dual build ===" -ForegroundColor Cyan
Write-Host "Signing: $signingJks"

Set-Location $appDir
flutter pub get | Out-Host

# 1) Normal / warehub APK (universal release APK)
Write-Host "`n[1/2] Building warehub release APK..." -ForegroundColor Yellow
flutter build apk --release | Out-Host
$apkSrc = Join-Path $appDir "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkSrc)) { throw "APK missing: $apkSrc" }
$apkDest = Join-Path $dist "$base-warehub.apk"
Copy-Item $apkSrc $apkDest -Force

# Also copy generic name for build_apk.ps1 compatibility
Copy-Item $apkSrc (Join-Path $dist "$base.apk") -Force

# 2) Play Store App Bundle
Write-Host "`n[2/2] Building Play Store App Bundle (AAB)..." -ForegroundColor Yellow
flutter build appbundle --release | Out-Host
$aabSrc = Join-Path $appDir "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $aabSrc)) { throw "AAB missing: $aabSrc" }
$aabDest = Join-Path $dist "$base-play.aab"
Copy-Item $aabSrc $aabDest -Force

# Metadata
$warehubMeta = [ordered]@{
    slug          = "neon_chronos"
    name          = "Neon Chronos"
    packageId     = "com.zibashu.neon_chronos"
    versionName   = $ver.name
    versionCode   = $ver.code
    channel       = "warehub"
    artifact      = "$base-warehub.apk"
    format        = "apk"
    family        = "ziBashu"
    kind          = "tool"
    blurb         = "Temporal OS - futuristic personal time environment."
    website       = "https://zibashu4.com"
    signed        = $true
    signingAlias  = "zibashu_upload"
    notes         = "Sideload / warehub release APK. Same upload key as Play AAB."
} | ConvertTo-Json

$playMeta = [ordered]@{
    slug          = "neon_chronos"
    name          = "Neon Chronos"
    packageId     = "com.zibashu.neon_chronos"
    versionName   = $ver.name
    versionCode   = $ver.code
    channel       = "play"
    artifact      = "$base-play.aab"
    format        = "aab"
    family        = "ziBashu"
    kind          = "tool"
    blurb         = "Temporal OS - futuristic personal time environment."
    website       = "https://zibashu4.com"
    signed        = $true
    signingAlias  = "zibashu_upload"
    playReady     = $true
    checklist     = @(
        "Upload AAB to Play Console (Internal testing first)",
        "Enable Play App Signing (Google holds app signing key)",
        "Complete store listing, screenshots, content rating",
        "Privacy policy URL required if collecting data",
        "Back up signing/zibashu-upload.jks + keystore.properties offline"
    )
    notes         = "Play Store upload bundle. Prefer Internal track before production."
} | ConvertTo-Json

Set-Content (Join-Path $dist "$base-warehub.json") $warehubMeta -Encoding UTF8
Set-Content (Join-Path $dist "$base-play.json") $playMeta -Encoding UTF8

# Sizes
$apkSize = [math]::Round((Get-Item $apkDest).Length / 1MB, 2)
$aabSize = [math]::Round((Get-Item $aabDest).Length / 1MB, 2)

Write-Host "`n=== Artifacts ===" -ForegroundColor Green
Write-Host "  WAREHUB APK : $apkDest  ($apkSize MB)"
Write-Host "  PLAY AAB    : $aabDest  ($aabSize MB)"
Write-Host "  Meta JSON   : dist\$base-warehub.json , dist\$base-play.json"
Write-Host "`nIMPORTANT: Keep signing\ private. Never commit the JKS or keystore.properties." -ForegroundColor Yellow

Set-Location $RepoRoot
