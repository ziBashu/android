# Pre-ship hardening checks for a registered app.
# Usage:
#   . .\scripts\env.ps1
#   .\scripts\harden_check.ps1 -App seru
#   .\scripts\harden_check.ps1 -App all

param(
    [string]$App = "all"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RepoRoot

$registryPath = Join-Path $RepoRoot "apps\registry.json"
if (-not (Test-Path $registryPath)) {
    Write-Error "Missing apps\registry.json"
}
$registry = Get-Content $registryPath -Raw | ConvertFrom-Json
$entries = @($registry.apps)
if ($App -ne "all") {
    $entries = @($entries | Where-Object { $_.key -eq $App -or $_.slug -eq $App })
    if ($entries.Count -eq 0) {
        Write-Error "App '$App' not found in registry.json"
    }
}

$failed = 0

function Fail([string]$msg) {
    Write-Host "  FAIL  $msg" -ForegroundColor Red
    $script:failed++
}
function Ok([string]$msg) {
    Write-Host "  OK    $msg" -ForegroundColor Green
}
function Warn([string]$msg) {
    Write-Host "  WARN  $msg" -ForegroundColor Yellow
}

foreach ($e in $entries) {
    Write-Host ""
    Write-Host "=== Harden: $($e.name) ($($e.slug)) ===" -ForegroundColor Cyan
    $appDir = Join-Path $RepoRoot ($e.dir -replace '/', '\')
    $pkg = $e.packageId

    if (-not (Test-Path $appDir)) {
        Fail "dir missing: $($e.dir)"
        continue
    }
    Ok "dir exists $($e.dir)"

    if ($pkg -notmatch '^com\.zibashu\.[a-z0-9_]+$') {
        Fail "packageId must match com.zibashu.<slug>: $pkg"
    } else {
        Ok "packageId $pkg"
    }

    $gradle = Join-Path $appDir "android\app\build.gradle.kts"
    if (-not (Test-Path $gradle)) {
        $gradle = Join-Path $appDir "android\app\build.gradle"
    }
    if (Test-Path $gradle) {
        $g = Get-Content $gradle -Raw
        if ($g -notmatch [regex]::Escape($pkg)) {
            Fail "applicationId/namespace may not match $pkg in gradle"
        } else {
            Ok "gradle references packageId"
        }
    } else {
        Fail "android app gradle missing"
    }

    $manifest = Join-Path $appDir "android\app\src\main\AndroidManifest.xml"
    if (Test-Path $manifest) {
        $m = Get-Content $manifest -Raw
        if ($m -match 'usesCleartextTraffic\s*=\s*"true"') {
            Fail "cleartext traffic enabled"
        } else {
            Ok "no cleartext traffic flag (or not true)"
        }
        if ($m -match 'android:label=') {
            Ok "launcher label set"
        }
    } else {
        Fail "AndroidManifest.xml missing"
    }

    $pubspec = Join-Path $appDir "pubspec.yaml"
    if (Test-Path $pubspec) {
        $p = Get-Content $pubspec -Raw
        if ($p -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)') {
            Ok ("version " + $Matches[1] + "+" + $Matches[2])
        } else {
            Fail "pubspec version must be x.y.z+code"
        }
        if ($p -match 'zibashu_ui') {
            Ok "depends on zibashu_ui"
        } else {
            Warn "no zibashu_ui path dep"
        }
    }

    $moduleMd = Join-Path $appDir "MODULE.md"
    if (Test-Path $moduleMd) {
        Ok "MODULE.md present"
    } else {
        Warn "MODULE.md missing - fill contract"
    }

    $dartFiles = Get-ChildItem $appDir -Recurse -Filter *.dart -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\.dart_tool\\|\\build\\' }
    $secretHits = @()
    foreach ($f in $dartFiles) {
        $c = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $c) { continue }
        $hit = $false
        if ($c -like '*BEGIN PRIVATE KEY*') { $hit = $true }
        if ($c -match 'sk-[A-Za-z0-9]{20}') { $hit = $true }
        if ($c -match 'api_key\s*=') { $hit = $true }
        if ($hit) { $secretHits += $f.FullName }
    }
    if ($secretHits.Count -gt 0) {
        Fail ("possible secrets in: " + ($secretHits -join "; "))
    } else {
        Ok "no obvious secrets in dart sources"
    }

    $ks = Get-ChildItem $appDir -Recurse -Include *.jks,*.keystore -ErrorAction SilentlyContinue
    if ($ks) {
        Fail "keystore files inside app tree (move to signing/)"
    } else {
        Ok "no keystore in app tree"
    }
}

Write-Host ""
if ($failed -gt 0) {
    Write-Host "HARDEN FAILED: $failed issue(s)" -ForegroundColor Red
    exit 1
}
Write-Host "HARDEN PASSED" -ForegroundColor Green
exit 0
