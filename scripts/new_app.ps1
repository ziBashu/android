# Scaffold a new ziBashu specialty Flutter app.
# Usage:
#   . .\scripts\env.ps1
#   .\scripts\new_app.ps1 -Slug lumen -Name "Lumen" -Surface lab

param(
    [Parameter(Mandatory = $true)][string]$Slug,
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$Surface = "tool",
    [string]$PackageId = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RepoRoot

. (Join-Path $RepoRoot "scripts\env.ps1")

$Slug = $Slug.ToLowerInvariant() -replace '[^a-z0-9_]', '_'
if (-not $PackageId) { $PackageId = "com.zibashu.$Slug" }

$appDir = Join-Path $RepoRoot "apps\$Slug"
if (Test-Path $appDir) {
    Write-Error "App already exists: $appDir"
}

Write-Host "Creating Flutter app $Name ($PackageId) ..." -ForegroundColor Cyan
flutter create --org com.zibashu --project-name $Slug --platforms=android $appDir | Out-Host

# Patch applicationId in build.gradle(.kts)
$gradleKts = Join-Path $appDir "android\app\build.gradle.kts"
$gradleGroovy = Join-Path $appDir "android\app\build.gradle"
if (Test-Path $gradleKts) {
    (Get-Content $gradleKts -Raw) `
        -replace 'applicationId\s*=\s*"[^"]+"', "applicationId = `"$PackageId`"" `
        -replace 'namespace\s*=\s*"[^"]+"', "namespace = `"$PackageId`"" |
        Set-Content $gradleKts -NoNewline
} elseif (Test-Path $gradleGroovy) {
    (Get-Content $gradleGroovy -Raw) `
        -replace 'applicationId\s+"[^"]+"', "applicationId `"$PackageId`"" `
        -replace 'namespace\s+"[^"]+"', "namespace `"$PackageId`"" |
        Set-Content $gradleGroovy -NoNewline
}

# Inject path deps into pubspec
$pubspec = Join-Path $appDir "pubspec.yaml"
$extra = @"

  zibashu_core:
    path: ../../packages/zibashu_core
  zibashu_ui:
    path: ../../packages/zibashu_ui
  zibashu_auth:
    path: ../../packages/zibashu_auth
"@
$pub = Get-Content $pubspec -Raw
if ($pub -notmatch 'zibashu_core:') {
    $pub = $pub -replace '(dependencies:\r?\n  flutter:\r?\n    sdk: flutter)', "`$1$extra"
    Set-Content $pubspec $pub -NoNewline
}

# Starter main.dart
$main = @"
import 'package:flutter/material.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ${Name -replace '[^A-Za-z0-9]', ''}App());
}

class ${Name -replace '[^A-Za-z0-9]', ''}App extends StatelessWidget {
  const ${Name -replace '[^A-Za-z0-9]', ''}App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$Name',
      debugShowCheckedModeBanner: false,
      theme: buildZiBashuTheme(),
      home: const ZiBashuScaffold(
        title: '$Name',
        body: EmptyState(
          title: '$Name',
          message: 'Specialty APK for the ziBashu system. Surface: $Surface.',
          icon: Icons.extension_outlined,
        ),
      ),
    );
  }
}
"@
Set-Content (Join-Path $appDir "lib\main.dart") $main

Write-Host "`nScaffolded apps\$Slug" -ForegroundColor Green
Write-Host "Next:"
Write-Host "  1. Add a FamilyApp entry in packages/zibashu_core/lib/src/family_catalog.dart"
Write-Host "  2. Fill docs/apk-module-contract.md fields for this app"
Write-Host "  3. Register in scripts/build_apk.ps1 targets"
Write-Host "  4. flutter pub get && flutter run  (from apps\$Slug)"
