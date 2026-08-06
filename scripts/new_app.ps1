# Scaffold a new ziBashu specialty Flutter APK (game, tool, lab, studio, ...).
# Usage:
#   . .\scripts\env.ps1
#   .\scripts\new_app.ps1 -Slug playforge -Name "PlayForge" -Kind game -Register
#   .\scripts\new_app.ps1 -Slug netkit -Name "NetKit" -Kind tool -Blurb "Network tools" -WebRoute "/hub" -Register

param(
    [Parameter(Mandatory = $true)][string]$Slug,
    [Parameter(Mandatory = $true)][string]$Name,
    [ValidateSet("hub", "messaging", "tool", "game", "lab", "studio", "social", "other")]
    [string]$Kind = "tool",
    [string]$Surface = "",
    [string]$PackageId = "",
    [string]$Blurb = "",
    [string]$WebRoute = "",
    [string]$AccentHex = "0xFF2F6F4E",
    [switch]$Register
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RepoRoot

. (Join-Path $RepoRoot "scripts\env.ps1")

$Slug = $Slug.ToLowerInvariant() -replace '[^a-z0-9_]', '_'
if (-not $PackageId) { $PackageId = "com.zibashu.$Slug" }
if (-not $Surface) { $Surface = $Kind }
if (-not $Blurb) { $Blurb = "$Name — a ziBashu $Kind for the family of apps." }
if (-not $WebRoute) { $WebRoute = "/" }

$appDir = Join-Path $RepoRoot "apps\$Slug"
if (Test-Path $appDir) {
    Write-Error "App already exists: $appDir"
}

$safeClass = ($Name -replace '[^A-Za-z0-9]', '')
if ([string]::IsNullOrWhiteSpace($safeClass)) { $safeClass = "ZiBashuApp" }
if ($safeClass -notmatch '^[A-Za-z]') { $safeClass = "App$safeClass" }

$iconByKind = @{
    hub       = "Icons.apps_outlined"
    messaging = "Icons.forum_outlined"
    tool      = "Icons.build_outlined"
    game      = "Icons.sports_esports_outlined"
    lab       = "Icons.science_outlined"
    studio    = "Icons.palette_outlined"
    social    = "Icons.people_outline"
    other     = "Icons.extension_outlined"
}
$icon = $iconByKind[$Kind]

Write-Host "Creating Flutter app $Name ($PackageId) kind=$Kind ..." -ForegroundColor Cyan
flutter create --org com.zibashu --project-name $Slug --platforms=android $appDir | Out-Host

# Patch applicationId / namespace
$gradleKts = Join-Path $appDir "android\app\build.gradle.kts"
$gradleGroovy = Join-Path $appDir "android\app\build.gradle"
if (Test-Path $gradleKts) {
    $g = Get-Content $gradleKts -Raw
    $g = $g -replace 'applicationId\s*=\s*"[^"]+"', "applicationId = `"$PackageId`""
    $g = $g -replace 'namespace\s*=\s*"[^"]+"', "namespace = `"$PackageId`""
    # Prefer JDK 21 + modest heap (see monorepo convention)
    Set-Content $gradleKts $g -NoNewline
} elseif (Test-Path $gradleGroovy) {
    $g = Get-Content $gradleGroovy -Raw
    $g = $g -replace 'applicationId\s+"[^"]+"', "applicationId `"$PackageId`""
    $g = $g -replace 'namespace\s+"[^"]+"', "namespace `"$PackageId`""
    Set-Content $gradleGroovy $g -NoNewline
}

# Gradle properties: force toolchain JDK 21
$gp = Join-Path $appDir "android\gradle.properties"
@"
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=256m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.java.home=C:/Users/syxMa/android-toolchain/jdk21
org.gradle.daemon=true
android.useAndroidX=true
android.newDsl=false
android.builtInKotlin=false
"@ | Set-Content $gp

# Manifest label + INTERNET
$manifest = Join-Path $appDir "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifest) {
    $m = Get-Content $manifest -Raw
    if ($m -notmatch 'android.permission.INTERNET') {
        $m = $m -replace '<manifest([^>]*)>', "<manifest`$1>`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
    }
    $m = $m -replace 'android:label="[^"]+"', "android:label=`"$Name`""
    Set-Content $manifest $m -NoNewline
}

# Move MainActivity package folder if needed (flutter create uses org+name)
$ktRoot = Join-Path $appDir "android\app\src\main\kotlin"
$desiredPkgPath = Join-Path $ktRoot ($PackageId -replace '\.', '\')
$existingMain = Get-ChildItem $ktRoot -Recurse -Filter MainActivity.kt -ErrorAction SilentlyContinue | Select-Object -First 1
if ($existingMain) {
    New-Item -ItemType Directory -Path $desiredPkgPath -Force | Out-Null
    $newMain = Join-Path $desiredPkgPath "MainActivity.kt"
    @"
package $PackageId

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
"@ | Set-Content $newMain
    if ($existingMain.FullName -ne $newMain) {
        Remove-Item $existingMain.FullName -Force
        # prune empty dirs best-effort
        $parent = $existingMain.Directory
        while ($parent -and $parent.FullName -like "$ktRoot*") {
            if (@(Get-ChildItem $parent.FullName -Force).Count -eq 0) {
                $next = $parent.Parent
                Remove-Item $parent.FullName -Force -ErrorAction SilentlyContinue
                $parent = $next
            } else { break }
        }
    }
}

# pubspec path deps
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
    # ensure version form
    if ($pub -notmatch 'version:\s*\d+\.\d+\.\d+\+\d+') {
        $pub = $pub -replace 'version:\s*[^\r\n]+', 'version: 0.1.0+1'
    }
    Set-Content $pubspec $pub -NoNewline
}

# Starter main.dart
$main = @"
import 'package:flutter/material.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ${safeClass}App());
}

class ${safeClass}App extends StatelessWidget {
  const ${safeClass}App({super.key});

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
          message:
              'Distinct $Kind APK for the ziBashu system. Replace this shell with real product UI.',
          icon: $icon,
        ),
      ),
    );
  }
}
"@
Set-Content (Join-Path $appDir "lib\main.dart") $main

# MODULE.md contract
$module = @"
# $Name — APK module contract

| Field | Value |
|-------|--------|
| Name | $Name |
| Slug | ``$Slug`` |
| Kind | ``$Kind`` |
| Surface | ``$Surface`` |
| applicationId | ``$PackageId`` |
| Folder | ``apps/$Slug`` |
| Auth | none / optional / required (edit) |
| Guest behavior | (edit) |
| Backend routes | (edit) |
| Local storage | (edit) |
| Permissions | INTERNET (add only what you need) |
| Distribution | warehub (Play later) |
| Web fallback | ``$WebRoute`` |
| Blurb | $Blurb |

## Hardening

- [ ] No secrets in client
- [ ] Min permissions
- [ ] Version bumped for release
- [ ] ``flutter analyze`` / ``flutter test`` / release APK
- [ ] ``.\scripts\harden_check.ps1 -App $Slug``
- [ ] Emulator smoke + screenshot

## Notes

(edit)
"@
Set-Content (Join-Path $appDir "MODULE.md") $module

# Widget test smoke
$test = @"
import 'package:flutter_test/flutter_test.dart';
import 'package:$Slug/main.dart';

void main() {
  testWidgets('$Name boots', (tester) async {
    await tester.pumpWidget(const ${safeClass}App());
    expect(find.textContaining('$Name'), findsWidgets);
  });
}
"@
Set-Content (Join-Path $appDir "test\widget_test.dart") $test

if ($Register) {
    $registryPath = Join-Path $RepoRoot "apps\registry.json"
    $reg = Get-Content $registryPath -Raw | ConvertFrom-Json
    $exists = @($reg.apps | Where-Object { $_.slug -eq $Slug -or $_.key -eq $Slug })
    if ($exists.Count -gt 0) {
        Write-Host "Registry already has $Slug — skip append" -ForegroundColor Yellow
    } else {
        $entry = [ordered]@{
            key          = $Slug
            slug         = $Slug
            name         = $Name
            dir          = "apps/$Slug"
            packageId    = $PackageId
            kind         = $Kind
            surface      = $Surface
            route        = $WebRoute
            blurb        = $Blurb
            available    = $true
            accentHex    = $AccentHex
            distribution = @("warehub")
        }
        $list = [System.Collections.ArrayList]@($reg.apps)
        [void]$list.Add([pscustomobject]$entry)
        $reg.apps = $list.ToArray()
        $reg | ConvertTo-Json -Depth 8 | Set-Content $registryPath -Encoding UTF8
        Write-Host "Registered in apps/registry.json" -ForegroundColor Green
    }

    # Append catalog entry if missing (insert before final ]; of kFamilyCatalog list)
    $catalog = Join-Path $RepoRoot "packages\zibashu_core\lib\src\family_catalog.dart"
    $catText = Get-Content $catalog -Raw
    if ($catText -notmatch "slug:\s*'$Slug'") {
        $blurbEsc = $Blurb -replace "'", "\\'"
        $snippet = @"
  FamilyApp(
    slug: '$Slug',
    name: '$Name',
    packageId: '$PackageId',
    surface: '$Surface',
    blurb: '$blurbEsc',
    webRoute: '$WebRoute',
    available: true,
    accentHex: $AccentHex,
  ),

"@
        $marker = "const List<FamilyApp> kFamilyCatalog"
        $start = $catText.IndexOf($marker)
        if ($start -lt 0) {
            Write-Host "Could not find kFamilyCatalog — add FamilyApp manually" -ForegroundColor Yellow
        } else {
            $close = $catText.LastIndexOf('];')
            if ($close -gt $start) {
                $catText = $catText.Substring(0, $close) + $snippet + $catText.Substring($close)
                Set-Content $catalog $catText -NoNewline
                Write-Host "Catalog entry appended to family_catalog.dart" -ForegroundColor Green
            } else {
                Write-Host "Could not locate catalog list end — add FamilyApp manually" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "`nScaffolded apps\$Slug ($Kind)" -ForegroundColor Green
Write-Host "Next (standard workflow — docs/NEXT_AGENT_STANDARD_WORKFLOW.md):"
Write-Host "  1. Implement product UI under apps\$Slug\lib"
Write-Host "  2. flutter analyze / test / run -d emulator-5554"
Write-Host "  3. .\scripts\harden_check.ps1 -App $Slug"
Write-Host "  4. .\scripts\build_apk.ps1 -App $Slug"
Write-Host "  5. git commit + git push origin main (or feature branch PR)"
