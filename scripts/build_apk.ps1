# Build release APK(s) from apps/registry.json and write warehub metadata into dist/
# Usage:
#   . .\scripts\env.ps1
#   .\scripts\build_apk.ps1 -App all
#   .\scripts\build_apk.ps1 -App seru
#   .\scripts\build_apk.ps1 -App playforge

param(
    [string]$App = "all"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RepoRoot

. (Join-Path $RepoRoot "scripts\env.ps1")

$registryPath = Join-Path $RepoRoot "apps\registry.json"
if (-not (Test-Path $registryPath)) {
    Write-Error "Missing apps\registry.json"
}
$registry = Get-Content $registryPath -Raw | ConvertFrom-Json
$entries = @($registry.apps)

if ($App -ne "all") {
    $entries = @($entries | Where-Object { $_.key -eq $App -or $_.slug -eq $App })
    if ($entries.Count -eq 0) {
        $known = ($registry.apps | ForEach-Object { $_.slug }) -join ", "
        Write-Error "App '$App' not in registry. Known: $known"
    }
}

$dist = Join-Path $RepoRoot "dist"
New-Item -ItemType Directory -Path $dist -Force | Out-Null

function Get-PubspecVersion([string]$pubspecPath) {
    $text = Get-Content $pubspecPath -Raw
    if ($text -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)') {
        return @{ name = $Matches[1]; code = [int]$Matches[2] }
    }
    throw "Could not parse version from $pubspecPath (need x.y.z+code)"
}

foreach ($meta in $entries) {
    $appDir = Join-Path $RepoRoot ($meta.dir -replace '/', '\')
    if (-not (Test-Path $appDir)) {
        Write-Error "App dir missing: $appDir"
    }

    Write-Host "`n=== Building $($meta.name) [$($meta.kind)] ===" -ForegroundColor Cyan
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

    $json = [ordered]@{
        slug        = $meta.slug
        name        = $meta.name
        packageId   = $meta.packageId
        versionName = $ver.name
        versionCode = $ver.code
        minSdk      = 24
        family      = $registry.family
        kind        = $meta.kind
        surface     = $meta.surface
        apk         = $apkName
        website     = $registry.website
        route       = $meta.route
        blurb       = $meta.blurb
        distribution = @($meta.distribution)
    } | ConvertTo-Json

    $jsonPath = Join-Path $dist "$($meta.slug)-v$($ver.name).json"
    Set-Content -Path $jsonPath -Value $json -Encoding UTF8

    Write-Host "Wrote $apkDest" -ForegroundColor Green
    Write-Host "Wrote $jsonPath" -ForegroundColor Green
}

Set-Location $RepoRoot
Write-Host "`nDone. Artifacts in dist\" -ForegroundColor Green
