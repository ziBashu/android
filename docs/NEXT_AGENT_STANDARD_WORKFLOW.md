# Next agent: standard multi-APK workflow

**Repo:** `C:\Users\syxMa\ANDROID` (remote: `git@github.com:ziBashu/android.git`)  
**Product:** many **distinct** Flutter APKs for the ziBashu system (games, tool, lab, studio, messaging, …).  
**Distribution:** primarily **warehub** (sideload); optionally **Play Store** later.  
**Do not touch:** `C:\Users\syxMa\android-ziBashu` (existing Kotlin Play WebView shell).

This document is the **source of truth** for creating, hardening, shipping, committing, and pushing apps.

---

## 0. Session bootstrap (always)

```powershell
cd C:\Users\syxMa\ANDROID
. .\scripts\env.ps1
flutter devices
adb devices -l
```

- Emulator optional for pure scaffolding; **required** for UI verify.
- Prefer device id: `emulator-5554` when AVD is running.
- Full agent loop: [agent-dev-loop.md](./agent-dev-loop.md).

---

## 1. Product rules (non-negotiable)

| Rule | Detail |
|------|--------|
| One APK = one product | Do not merge games/tools into Hub. Hub only catalogs them. |
| Package ID | Always `com.zibashu.<slug>` (lowercase a-z0-9 `_` only in slug) |
| Branding | Distinct launcher name + persistent **from ziBashu** (`zibashu_ui`) |
| Shared code | Put shared logic in `packages/zibashu_*`, not copy-paste |
| Secrets | Never in clients. Laravel holds provider keys |
| Backend optional | Demo/offline mode when APIs missing |
| Registry | Every shippable app is listed in `apps/registry.json` |
| Catalog | Hub entries live in `packages/zibashu_core/lib/src/family_catalog.dart` |

### Kinds (use these surface/kind values)

| Kind | Examples | Typical deps |
|------|----------|--------------|
| `hub` | ziBashu Hub | catalog only |
| `messaging` | Seru | auth, local storage, sockets later |
| `tool` | NetKit, utilities | device APIs, network |
| `game` | card/arcade/mini-games | input, audio; keep offline-first if possible |
| `lab` | Lumen, research | network + auth |
| `studio` | Canvas/Comfy-style | files, media, local-first |
| `social` | feed-adjacent clients | auth + API |
| `other` | experiments | document clearly |

---

## 2. Standard: create a new APK

### 2.1 Scaffold

```powershell
. .\scripts\env.ps1
.\scripts\new_app.ps1 `
  -Slug "playforge" `
  -Name "PlayForge" `
  -Kind game `
  -Surface game `
  -Blurb "A ziBashu family game." `
  -WebRoute "/hub" `
  -Register
```

Flags:

| Flag | Required | Meaning |
|------|----------|---------|
| `-Slug` | yes | folder + package suffix |
| `-Name` | yes | display name |
| `-Kind` | no (default `tool`) | game / tool / lab / studio / messaging / social / other |
| `-Surface` | no | defaults to Kind; hub catalog surface |
| `-Blurb` | no | short warehub description |
| `-WebRoute` | no | site fallback path |
| `-PackageId` | no | defaults `com.zibashu.<slug>` |
| `-Register` | switch | auto-append `apps/registry.json` + catalog stub + `apps/<slug>/MODULE.md` |

Without `-Register`, script still scaffolds and prints manual checklist.

### 2.2 Implement

1. Work only under `apps/<slug>/` + shared packages if needed.
2. Keep `FromZiBashuBadge` / `ZiBashuScaffold` visible.
3. Fill `apps/<slug>/MODULE.md` (contract fields).
4. Set `available: true` in catalog when shippable; leave `false` for placeholders.
5. Bump `version:` in `apps/<slug>/pubspec.yaml` as `x.y.z+code` (`+code` = monotonic `versionCode`).

### 2.3 Run on emulator

```powershell
cd apps\<slug>
flutter pub get
flutter run -d emulator-5554
# after UI changes
cd C:\Users\syxMa\ANDROID
.\scripts\screenshot.ps1 -Out screenshots\<slug>.png
```

### 2.4 Build release for warehub / Play

```powershell
. .\scripts\env.ps1
.\scripts\build_apk.ps1 -App <slug>    # or -App all
```

Outputs (gitignored):

```text
dist/<slug>-v<versionName>.apk
dist/<slug>-v<versionName>.json   # warehub metadata
```

Play Store later: also `flutter build appbundle` → AAB (document in MODULE.md when first uploading).

---

## 3. Hardening checklist (before shipping)

Run through this for **every** new APK. Mark items in `MODULE.md`.

### 3.1 Identity & packaging

- [ ] `applicationId` / `namespace` = `com.zibashu.<slug>` (unique forever)
- [ ] Launcher label = product name (not the slug alone)
- [ ] Version `versionName+versionCode` bumped for this release
- [ ] Registered in `apps/registry.json`
- [ ] Hub catalog entry correct (`available`, blurb, route)

### 3.2 Security

- [ ] No API keys, tokens, or passwords in source or assets
- [ ] Auth only via `zibashu_auth` + Sanctum when needed
- [ ] `usesCleartextTraffic` stays off unless localhost debug is explicitly justified
- [ ] Permissions minimal: only what the product needs (camera/mic/location need product reason + privacy copy)
- [ ] Release build uses minify when enabled in app gradle (see hardening script)
- [ ] Debug signing is OK for warehub sideload **dev**; Play needs a real upload keystore under `signing/` (**gitignored**)

### 3.3 Privacy & Play readiness (even if warehub-first)

- [ ] Privacy policy URL (ziBashu site) known if sensitive permissions used
- [ ] Data safety story: what is stored on-device vs server
- [ ] UGC apps need reporting/blocking path on the **site**, not only in the APK
- [ ] Target/compile SDK meets current Play requirements (Flutter defaults + toolchain)

### 3.4 Quality gates

```powershell
. .\scripts\env.ps1
cd apps\<slug>
flutter analyze
flutter test
flutter build apk --release
.\scripts\harden_check.ps1 -App <slug>
```

- [ ] `flutter analyze` clean (or only documented ignores)
- [ ] Tests pass (smoke at minimum)
- [ ] Release APK installs on emulator (`adb install -r dist\...`)
- [ ] Screenshot of primary screen saved under `screenshots/` (local only)

### 3.5 Signing (warehub vs Play)

| Channel | Signing |
|---------|---------|
| Dev / warehub testing | Debug keystore (Flutter default) OK |
| Public warehub stable | Prefer dedicated upload keystore in `signing/` (never commit) |
| Play Store | Same: `keystore.properties` + `signing/` gitignored; AAB preferred |

Never reuse or commit the Play keystore from `android-ziBashu` without explicit owner approval.

---

## 4. Warehub upload package

After a green build:

```text
dist/
  <slug>-v1.2.0.apk
  <slug>-v1.2.0.json
```

JSON fields (written by `build_apk.ps1`):

`slug`, `name`, `packageId`, `versionName`, `versionCode`, `minSdk`, `family`, `kind`/`surface`, `apk`, `website`, `route`, `blurb`.

Upload both files to warehub when that surface exists. Until then, keep artifacts local or attach to a release.

---

## 5. Git: commit and push (standard)

### 5.1 What never goes in git

Already covered by root `.gitignore` — double-check:

- `signing/`, `*.jks`, `*.keystore`, `keystore.properties`
- `dist/`, `*.apk`, `*.aab`
- `screenshots/` (except `.gitkeep`)
- `.env`, secrets, local.properties
- `build/`, `.dart_tool/`

### 5.2 Commit workflow

```powershell
cd C:\Users\syxMa\ANDROID
git status
git diff
git log -5 --oneline

# Stage intentional source only
git add apps/<slug> packages docs scripts apps/registry.json AGENTS.md README.md
# Do NOT force-add dist/ or keystores

git commit -m "$(cat <<'EOF'
Add <Name> (<kind>) APK scaffold for ziBashu family.

Brief why: ship as separate warehub/Play product under com.zibashu.<slug>.
EOF
)"

git status
```

On Windows PowerShell if HEREDOC is awkward:

```powershell
git commit -m "Add <Name> (<kind>) APK scaffold for ziBashu family."
```

Message style:

- Imperative, focused
- Mention **kind** and **slug**
- No secrets, no “generated with AI” noise

### 5.3 Push workflow

```powershell
git pull --rebase origin main
git push origin main
```

- Remote is `origin` → `git@github.com:ziBashu/android.git`.
- Prefer **PR branches** for large features: `git checkout -b feat/<slug>`, push branch, open PR.
- Never `git push --force` to `main`.
- Never amend commits already pushed unless the owner explicitly asks.

### 5.4 When not to push

- Incomplete hardening for a “ship” claim
- Debug credentials in tree
- Accidental `dist/*.apk` staged — unstage first

---

## 6. Definition of done (one APK)

1. Scaffolded under `apps/<slug>` with shared packages  
2. In `apps/registry.json` + hub catalog  
3. `MODULE.md` filled  
4. Analyzes / tests / release APK build OK  
5. Hardening checklist passed (`harden_check.ps1`)  
6. Emulator smoke + screenshot (local)  
7. Commit on clean tree; push to origin (or PR)  

---

## 7. Layout cheat sheet

```text
ANDROID/
  apps/
    registry.json          # canonical multi-APK registry
    zibashu_hub/           # catalog launcher
    seru/                  # messaging sample
    <new-slug>/            # next products
  packages/
    zibashu_core/          # API, catalog models, warehub meta
    zibashu_ui/            # brand, FromZiBashuBadge
    zibashu_auth/          # Sanctum tokens
  scripts/
    env.ps1
    bootstrap.ps1
    new_app.ps1            # create APK project
    build_apk.ps1          # release + dist metadata
    harden_check.ps1       # pre-ship checks
    screenshot.ps1
  docs/
    NEXT_AGENT_STANDARD_WORKFLOW.md  ← this file
    agent-dev-loop.md
    apk-module-contract.md
    warehub.md
    architecture.md
  dist/                    # gitignored build outputs
```

---

## 8. Prompt paste for a new coding session

```text
You are working in C:\Users\syxMa\ANDROID — ziBashu multi-APK Flutter monorepo.
Follow docs/NEXT_AGENT_STANDARD_WORKFLOW.md end-to-end.
.env: . .\scripts\env.ps1
Create distinct APKs (game/tool/lab/…) with com.zibashu.<slug>, registry + catalog registration, hardening, then commit (and push only when checks pass).
Never modify C:\Users\syxMa\android-ziBashu. Never commit keystores or dist APKs.
Use flutter run -d emulator-5554 and scripts\screenshot.ps1 to verify UI.
```
