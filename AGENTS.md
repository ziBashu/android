# Agent guide — ziBashu ANDROID monorepo

## What this repo is

Flutter multi-app monorepo for **distinct ziBashu-branded APKs** distributed via warehub.

Do **not** modify `C:\Users\syxMa\android-ziBashu` (Kotlin Play WebView shell).

## Session start

```powershell
cd C:\Users\syxMa\ANDROID
. .\scripts\env.ps1
```

## Layout

- `packages/zibashu_core` — API config, catalog, warehub models
- `packages/zibashu_ui` — theme + chrome
- `packages/zibashu_auth` — Sanctum token store / login
- `apps/zibashu_hub` — family launcher (`com.zibashu.hub`)
- `apps/seru` — messaging sample (`com.zibashu.seru`)

## Add a new APK

```powershell
.\scripts\new_app.ps1 -Slug mytool -Name "MyTool" -Surface tool
```

Then:

1. Implement under `apps/mytool`
2. Register in `family_catalog.dart`
3. Add build target in `scripts/build_apk.ps1`
4. Fill apk-module-contract fields in docs

## Build

```powershell
.\scripts\build_apk.ps1 -App all
# outputs: dist/<slug>-v<version>.apk + .json
```

## Rules

- Package IDs: `com.zibashu.<slug>` only
- Every UI should show “from ziBashu”
- No secrets in clients
- Prefer demo mode for UI work when API is missing
- Prefer path deps on shared packages over copy-paste
