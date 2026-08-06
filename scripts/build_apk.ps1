# Build release APK(s) and write warehub metadata into dist/
# Usage:
#   . .\scripts\env.ps1
#   .\scripts\build_apk.ps1 -App all
#   .\scripts\build_apk.ps1 -App hub
#   .\scripts\build_apk.ps1 -App seru

param(
    [ValidateSet("all", "hub", "seru")]
    [string]$App = "all"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RepoRoot

. (Join-Path $RepoRoot "scripts\env.ps1")

$dist = Join-Path $RepoRoot "dist"
New-Item -ItemType Directory -Path $dist -Force | Out-Null

$apps = @{
    hub  = @{
        dir         = "apps\zibashu_hub"
        slug        = "hub"
        name        = "ziBashu Hub"
        packageId   = "com.zibashu.hub"
        surface     = "hub"
        route       = "/"
        blurb       = "Directory of ziBashu apps on your device and the web."
    }
    seru = @{
        dir         = "apps\seru"
        slug        = "seru"
        name        = "Seru"
        packageId   = "com.zibashu.seru"
        surface     = "messaging"
        route       = "/seru"
        blurb       = "Private messaging for the ziBashu system."
    }
}

$targets = if ($App -eq "all") { @("hub", "seru") } else { @($App) }

function Get-PubspecVersion([string]$pubspecPath) {
    $text = Get-Content $pubspecPath -Raw
    if ($text -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)') {
        return @{ name = $Matches[1]; code = [int]$Matches[2] }
    }
    throw "Could not parse version from $pubspecPath"
}

foreach ($key in $targets) {
    $meta = $apps[$key]
    $appDir = Join-Path $RepoRoot $meta.dir
    Write-Host "`n=== Building $($meta.name) ===" -ForegroundColor Cyan
    Set-Location $appDir

    flutter pub get | Out-Host
    flutter build apk --release | Out-Host

    $apkSrc = Join-Path $appDir "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apkSrc)) {
        throw "APK not found at $apkSrc"
    }

    $ver = Get-PubspecVersion (Join-Path $appDir "pubspec.yaml")
    $apkName = "$($meta.slug)-v$($ver.name).apk"
    $apkDest = Join-Path $dist $apkName
    Copy-Item $apkSrc $apkDest -Force

    $json = @{
        slug        = $meta.slug
        name        = $meta.name
        packageId   = $meta.packageId
        versionName = $ver.name
        versionCode = $ver.code
        minSdk      = 24
        family      = "ziBashu"
        surface     = $meta.surface
        apk         = $apkName
        website     = "https://zibashu4.com"
        route       = $meta.route
        blurb       = $meta.blurb
    } | ConvertTo-Json

    $jsonPath = Join-Path $dist "$($meta.slug)-v$($ver.name).json"
    Set-Content -Path $jsonPath -Value $json -Encoding UTF8

    Write-Host "Wrote $apkDest" -ForegroundColor Green
    Write-Host "Wrote $jsonPath" -ForegroundColor Green
}

Set-Location $RepoRoot
Write-Host "`nDone. Artifacts in dist\" -ForegroundColor Green
