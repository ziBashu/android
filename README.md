# ziBashu Android (Flutter monorepo)

Multi-app workspace for **distinct APKs** that serve the [ziBashu](https://zibashu4.com) system. Apps are branded **from ziBashu** and packaged for **warehub** distribution.

The existing Kotlin Play shell at `~/android-ziBashu` is **not** part of this repo and should stay untouched.

## Apps

| App | Package ID | Role |
|-----|------------|------|
| **ziBashu Hub** | `com.zibashu.hub` | Family catalog / launcher |
| **Seru** | `com.zibashu.seru` | Private messaging specialty (MVP + demo mode) |

Shared libraries live under `packages/` (`zibashu_core`, `zibashu_ui`, `zibashu_auth`).

## Quick start

```powershell
cd C:\Users\syxMa\ANDROID

# First time only (installs Flutter into android-toolchain if needed)
.\scripts\bootstrap.ps1

# Every session
. .\scripts\env.ps1

# Emulator must be running (Android Studio Device Manager)
flutter devices

# Run hub on emulator
cd apps\zibashu_hub
flutter pub get
flutter run -d emulator-5554

# Agent UI capture (repo root)
cd C:\Users\syxMa\ANDROID
.\scripts\screenshot.ps1 -Out screenshots\latest.png

# Or build release APKs for warehub
.\scripts\build_apk.ps1 -App all
```

Artifacts land in `dist/` as `<slug>-v<version>.apk` plus matching JSON metadata.

**Next agent / multi-APK standard (create → harden → commit → push):**  
[docs/NEXT_AGENT_STANDARD_WORKFLOW.md](docs/NEXT_AGENT_STANDARD_WORKFLOW.md)

AI agent loop (Flutter CLI + adb, not Android Studio APIs): [docs/agent-dev-loop.md](docs/agent-dev-loop.md).

### New product APK (game, tool, …)

```powershell
. .\scripts\env.ps1
.\scripts\new_app.ps1 -Slug mytool -Name "MyTool" -Kind tool -Register
.\scripts\harden_check.ps1 -App mytool
.\scripts\build_apk.ps1 -App mytool
```

Registry: `apps/registry.json`.

## Toolchain

| Tool | Path |
|------|------|
| JDK 21 | `C:\Users\syxMa\android-toolchain\jdk21` |
| Android SDK | `C:\Users\syxMa\android-toolchain\sdk` |
| Flutter | `C:\Users\syxMa\android-toolchain\flutter` |

See [docs/env-setup.md](docs/env-setup.md).

## Architecture

- [docs/architecture.md](docs/architecture.md)
- [docs/apk-module-contract.md](docs/apk-module-contract.md)
- [docs/warehub.md](docs/warehub.md)
- [AGENTS.md](AGENTS.md) — conventions for coding agents

## New specialty APK

```powershell
. .\scripts\env.ps1
.\scripts\new_app.ps1 -Slug lumen -Name "Lumen" -Surface lab
```

## Backend notes

- Seru ships in **demo mode** by default (`ApiConfig(demoMode: true)`).
- Live login expects `POST /api/mobile/login` on the Laravel site (Sanctum token). That endpoint is a small server follow-up if not present yet.
- Do not put provider API keys in these clients.

## Smoke checklist

- [ ] `. .\scripts\env.ps1` prints JAVA_HOME / ANDROID_HOME / flutter version
- [ ] `flutter doctor` shows Android toolchain
- [ ] Hub and Seru `flutter pub get` succeed
- [ ] `.\scripts\build_apk.ps1 -App all` produces two APKs under `dist/`
