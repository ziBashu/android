# Install Flutter into android-toolchain and verify Android toolchain.
# Run from repo root:  .\scripts\bootstrap.ps1

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RepoRoot

. (Join-Path $RepoRoot "scripts\env.ps1")

$ToolchainRoot = $env:ZIBASHU_TOOLCHAIN
$FlutterHome = Join-Path $ToolchainRoot "flutter"
$FlutterBat = Join-Path $FlutterHome "bin\flutter.bat"

function Ensure-Flutter {
    if (Test-Path $FlutterBat) {
        Write-Host "Flutter already present at $FlutterHome" -ForegroundColor Cyan
        return
    }

    Write-Host "Installing Flutter stable into $FlutterHome ..." -ForegroundColor Cyan
    Write-Host "This downloads ~1-2 GB. Leave the window open." -ForegroundColor Yellow

    $parent = Split-Path $FlutterHome -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    # Official stable clone (resumable / updateable via git pull + flutter upgrade)
    if (Get-Command git -ErrorAction SilentlyContinue) {
        git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FlutterHome
    } else {
        $zip = Join-Path $env:TEMP "flutter_windows_stable.zip"
        $url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.32.5-stable.zip"
        Write-Host "git not found; downloading zip from $url"
        Invoke-WebRequest -Uri $url -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $ToolchainRoot -Force
        if (-not (Test-Path $FlutterBat)) {
            Write-Error "Flutter zip extracted but bin\flutter.bat missing under $FlutterHome"
        }
    }
}

Ensure-Flutter

# Re-source PATH with flutter bin
. (Join-Path $RepoRoot "scripts\env.ps1")

Write-Host "Configuring Flutter Android SDK..." -ForegroundColor Cyan
& flutter config --android-sdk $env:ANDROID_HOME | Out-Host
& flutter config --no-analytics | Out-Host

Write-Host "Precaching Android artifacts (first run can take a while)..." -ForegroundColor Cyan
& flutter precache --android | Out-Host

Write-Host "Accepting Android licenses (best-effort)..." -ForegroundColor Cyan
$yes = ("y`n" * 20)
$yes | & flutter doctor --android-licenses 2>&1 | Out-Host

Write-Host "`n=== flutter doctor ===" -ForegroundColor Cyan
& flutter doctor -v | Out-Host

Write-Host "`nBootstrap complete. Next:" -ForegroundColor Green
Write-Host "  . .\scripts\env.ps1"
Write-Host "  melos bootstrap   # or: dart pub global activate melos; then melos bootstrap"
Write-Host "  .\scripts\build_apk.ps1 -App all"
