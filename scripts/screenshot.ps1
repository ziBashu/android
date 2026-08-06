# Capture the focused emulator/device screen for agent UI review.
# Usage:
#   . .\scripts\env.ps1
#   .\scripts\screenshot.ps1
#   .\scripts\screenshot.ps1 -Out screenshots\hub.png -Serial emulator-5554

param(
    [string]$Out = "",
    [string]$Serial = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RepoRoot

. (Join-Path $RepoRoot "scripts\env.ps1")

$shotDir = Join-Path $RepoRoot "screenshots"
New-Item -ItemType Directory -Path $shotDir -Force | Out-Null

if (-not $Out) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Out = Join-Path $shotDir "screen-$stamp.png"
} elseif (-not [System.IO.Path]::IsPathRooted($Out)) {
    $Out = Join-Path $RepoRoot $Out
}

$adbArgs = @()
if ($Serial) {
    $adbArgs += @("-s", $Serial)
}

$line = (& adb @adbArgs devices) | Select-String "device$"
if (-not $line) {
    Write-Error "No adb device online. Start the Android emulator first."
}

# Pull via device filesystem — PowerShell mangles binary pipes from exec-out.
$remote = "/sdcard/zibashu-agent-screen.png"
& adb @adbArgs shell screencap -p $remote
if ($LASTEXITCODE -ne 0) {
    Write-Error "screencap failed"
}
& adb @adbArgs pull $remote $Out | Out-Host
& adb @adbArgs shell rm $remote | Out-Null

if (-not (Test-Path $Out)) {
    Write-Error "Failed to write $Out"
}

$len = (Get-Item $Out).Length
Write-Host "Wrote $Out ($len bytes)" -ForegroundColor Green
Write-Output $Out
