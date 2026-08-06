# ziBashu Android monorepo - session environment
# Dot-source this in PowerShell:  . .\scripts\env.ps1

$ErrorActionPreference = "Stop"

$ToolchainRoot = if ($env:ZIBASHU_TOOLCHAIN) {
    $env:ZIBASHU_TOOLCHAIN
} else {
    "C:\Users\syxMa\android-toolchain"
}

$JavaHome = Join-Path $ToolchainRoot "jdk21"
$AndroidHome = Join-Path $ToolchainRoot "sdk"
$FlutterHome = Join-Path $ToolchainRoot "flutter"

if (-not (Test-Path (Join-Path $JavaHome "bin\java.exe"))) {
    Write-Error "JDK not found at $JavaHome. Expected android-toolchain\jdk21."
}
if (-not (Test-Path $AndroidHome)) {
    Write-Error "Android SDK not found at $AndroidHome."
}

$env:JAVA_HOME = $JavaHome
$env:ANDROID_HOME = $AndroidHome
$env:ANDROID_SDK_ROOT = $AndroidHome
$env:ZIBASHU_TOOLCHAIN = $ToolchainRoot

$pathsToPrepend = @(
    (Join-Path $JavaHome "bin"),
    (Join-Path $AndroidHome "platform-tools"),
    (Join-Path $AndroidHome "cmdline-tools\latest\bin"),
    (Join-Path $FlutterHome "bin")
)

foreach ($p in $pathsToPrepend) {
    if ((Test-Path $p) -and ($env:Path -notlike "*$p*")) {
        $env:Path = "$p;$env:Path"
    }
}

Write-Host "ziBashu ANDROID env ready" -ForegroundColor Green
Write-Host "  JAVA_HOME     = $env:JAVA_HOME"
Write-Host "  ANDROID_HOME  = $env:ANDROID_HOME"
Write-Host "  FLUTTER       = $FlutterHome"
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter --version 2>&1 | Select-Object -First 1
} else {
    Write-Host "  flutter not on PATH yet - run scripts\bootstrap.ps1" -ForegroundColor Yellow
}
