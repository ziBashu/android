# Environment setup

## Prerequisites (already on this machine)

| Tool | Location |
|------|----------|
| JDK 21 | `C:\Users\syxMa\android-toolchain\jdk21` |
| Android SDK | `C:\Users\syxMa\android-toolchain\sdk` |
| Flutter (after bootstrap) | `C:\Users\syxMa\android-toolchain\flutter` |

The Kotlin Play shell at `C:\Users\syxMa\android-ziBashu` is **independent** — do not modify it from this monorepo.

## One-time bootstrap

```powershell
cd C:\Users\syxMa\ANDROID
.\scripts\bootstrap.ps1
```

This clones Flutter stable into the toolchain folder, points it at the local SDK, and runs `flutter doctor`.

## Every session

```powershell
cd C:\Users\syxMa\ANDROID
. .\scripts\env.ps1
```

## Verify

```powershell
java -version
adb version
flutter doctor
```

## Optional: Melos

```powershell
dart pub global activate melos
# ensure %LOCALAPPDATA%\Pub\Cache\bin is on PATH
melos bootstrap
```

Without Melos you can still `flutter pub get` inside each package/app.
