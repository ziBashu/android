# AI agent + Flutter + emulator loop

This monorepo does **not** need a special Android Studio plugin for the agent.
The agent talks to **Flutter CLI + adb**; Android Studio mainly hosts the emulator.

```text
AI Agent (this terminal)
       |
       | edits lib/**, packages/**
       v
Flutter project (apps/zibashu_hub, apps/seru, …)
       |
       | flutter run -d emulator-5554
       v
Android Emulator (Device Manager in Android Studio)
       |
       v
Visible app
```

## Session checklist

### 1. Emulator running

In Android Studio: **Device Manager → start AVD** (keep it open).

Or from a shell (Studio SDK path on this machine):

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone
```

### 2. Load monorepo env

```powershell
cd C:\Users\syxMa\ANDROID
. .\scripts\env.ps1
```

`env.ps1` points Flutter at `android-toolchain` JDK/SDK and puts `adb` / `flutter` on PATH.

### 3. Confirm the device

```powershell
flutter devices
adb devices -l
```

Expect something like:

```text
sdk gphone… (mobile) • emulator-5554 • android-x64
```

### 4. Run an app

```powershell
cd apps\zibashu_hub
flutter run -d emulator-5554
```

Seru:

```powershell
cd apps\seru
flutter run -d emulator-5554
```

Hot reload in the `flutter run` session: press `r`. Full restart: `R`.

### 5. Let the agent “see” the UI

Terminal agents do not see the emulator window. Capture a PNG:

```powershell
.\scripts\screenshot.ps1 -Out screenshots\latest.png
```

Or raw adb:

```powershell
adb exec-out screencap -p > screenshots\latest.png
```

Then open/read that image in the agent session.

### 6. Build warehub APKs (no emulator required)

```powershell
.\scripts\build_apk.ps1 -App all
# → dist\hub-v*.apk, dist\seru-v*.apk + JSON
```

## Agent prompt (paste when starting a coding session)

```text
This is the ziBashu Flutter multi-app monorepo at C:\Users\syxMa\ANDROID.
Load env with: . .\scripts\env.ps1
Apps: apps/zibashu_hub (com.zibashu.hub), apps/seru (com.zibashu.seru).
Shared packages: packages/zibashu_core, zibashu_ui, zibashu_auth.
Android emulator is already running — use flutter run -d emulator-5554.
After UI changes, rebuild/run and capture a screenshot with scripts\screenshot.ps1.
Do not modify C:\Users\syxMa\android-ziBashu (Kotlin Play shell).
```

## Optional: DevTools

```powershell
dart pub global activate devtools
# ensure Pub Cache bin is on PATH
flutter pub global run devtools
```

Use for widget tree, performance, and memory while `flutter run` is attached.

## Optional: stronger UI automation later

- `integration_test` package in each app
- Maestro / Appium / Flutter Driver for scripted flows

Not required for day-to-day agent edits + screenshot verify.

## What Android Studio is for

| Studio | Agent bridge |
|--------|----------------|
| Emulator AVD | `flutter run` / `adb` |
| Layout inspector / debugger | optional human use |
| SDK Manager (if you install system images) | `ANDROID_HOME` for builds |

No Android Studio API connection is needed.
