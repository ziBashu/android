# Agent guide — ziBashu ANDROID monorepo

## Read this first

**Canonical multi-APK process (create → harden → commit → push):**

→ **[docs/NEXT_AGENT_STANDARD_WORKFLOW.md](docs/NEXT_AGENT_STANDARD_WORKFLOW.md)**

**Server ship, WareHub upload, offline vs online products, local backup mirror:**

→ **[docs/AGENT_SERVER_AND_SHIP_WORKFLOW.md](docs/AGENT_SERVER_AND_SHIP_WORKFLOW.md)**  
→ Local full-server rebuild mirror: **`C:\Users\syxMa\ziBashu`** (sync after production changes)

Emulator / UI verify loop:

→ **[docs/agent-dev-loop.md](docs/agent-dev-loop.md)**

Human + agent collab (feedback after each edit):

→ **[docs/DEV_COLLAB_LOOP.md](docs/DEV_COLLAB_LOOP.md)**  
→ User writes results in **`DEV_FEEDBACK.md`** (local, gitignored; template: `DEV_FEEDBACK.example.md`)

## What this repo is

Flutter multi-app monorepo for **distinct ziBashu-branded APKs** (games, tool, lab, studio, messaging, …) distributed via **warehub** (and later Play).

Do **not** modify `C:\Users\syxMa\android-ziBashu` (Kotlin Play WebView shell).

## Session start

```powershell
cd C:\Users\syxMa\ANDROID
. .\scripts\env.ps1
flutter devices
```

## Create another APK (game / tool / …)

```powershell
.\scripts\new_app.ps1 -Slug mygame -Name "MyGame" -Kind game -Register
.\scripts\harden_check.ps1 -App mygame
cd apps\mygame
flutter run -d emulator-5554
cd ..\..
.\scripts\build_apk.ps1 -App mygame
```

Registry of all shippable apps: `apps/registry.json`.

## Layout

- `packages/zibashu_core` — API config, catalog, warehub models
- `packages/zibashu_ui` — theme + **from ziBashu** chrome
- `packages/zibashu_auth` — Sanctum token store / login
- `apps/zibashu_hub` — family launcher (`com.zibashu.hub`)
- `apps/seru` — messaging sample (`com.zibashu.seru`)
- `apps/<slug>` — every new product APK

## Build

```powershell
.\scripts\build_apk.ps1 -App all
# → dist/<slug>-v<version>.apk + .json
```

## Hardening

```powershell
.\scripts\harden_check.ps1 -App all
```

## Commit and push

```powershell
git status
git add <sources only — never dist/, signing/, keystores>
git commit -m "Add <Name> (<kind>) APK for ziBashu family."
git pull --rebase origin main
git push origin main
```

Never force-push `main`. Prefer feature branches + PR for large work.

## Rules

- Package IDs: `com.zibashu.<slug>` only
- Every UI shows **from ziBashu**
- No secrets in clients
- Demo mode when API missing
- Path deps on shared packages — no copy-paste themes/auth
