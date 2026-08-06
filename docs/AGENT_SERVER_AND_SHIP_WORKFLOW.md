# Agent workflow: ship APKs, server, offline vs online, backups

**Read this before deploying anything to ziBashu production or claiming a release is live.**

| Item | Value |
|------|--------|
| Android monorepo | `C:\Users\syxMa\ANDROID` → `git@github.com:ziBashu/android.git` |
| Laravel site (prod) | `root@167.179.82.99` → `/www/wwwroot/ziBashu4.com` |
| Public site | `https://zibashu4.com` |
| WareHub storefront | `https://zibashu4.com/hub/warehub` |
| Admin publish UI | `https://zibashu4.com/admin/warehub` (URL-only; no nav link) |
| Local full-server mirror | **`C:\Users\syxMa\ziBashu`** (see §6) |
| Do not touch | `C:\Users\syxMa\android-ziBashu` (Kotlin Play WebView shell) |

Standard multi-APK product rules: [NEXT_AGENT_STANDARD_WORKFLOW.md](./NEXT_AGENT_STANDARD_WORKFLOW.md).  
Release dual-build (this app): [neon-chronos-release.md](./neon-chronos-release.md).  
Rebuild-from-backup details: `C:\Users\syxMa\ziBashu\server_backups\DEPLOY_INSTRUCTIONS.md`.

---

## 0. Product modes (critical for later agents)

ziBashu ships **many distinct APKs**. They fall into two operational classes:

### A. Offline product (no server runtime required)

Examples: **Neon Chronos** (Temporal OS / clock tool), pure offline mini-games, local utilities.

| Trait | Rule |
|-------|------|
| Network | Optional or unused; app must work with airplane mode |
| Auth / API | Demo or fully local; never hard-fail if Laravel is down |
| Ship path | Build **warehub APK** (+ optional **Play AAB**); upload APK to WareHub |
| Server work | **Only** host the APK + listing on WareHub — no game backend |
| SSH | Only for file upload / DB listing register / nginx if needed — **not** for game config |

**Neon Chronos status (2026-08-06):** offline Temporal OS, `com.zibashu.neon_chronos`, **v3.0.1 (versionCode 4)**.

- Warehub listing: https://zibashu4.com/hub/warehub/neon-chronos  
- Android download: https://zibashu4.com/hub/warehub/neon-chronos/download/android  
- Local artifacts: `dist/neon_chronos-v3.0.1-warehub.apk`, `dist/neon_chronos-v3.0.1-play.aab`

### B. Online product (server-backed game / realtime / multiplayer)

Examples (future): multiplayer card game, realtime match, shared lobby, scoreboards that need Laravel/Docker services.

| Trait | Rule |
|-------|------|
| Network | Required for core loops |
| Server | Agent **must SSH into** `167.179.82.99`, configure env, services, routes, DB, firewall |
| Client | APK still ships via WareHub / Play, but points at prod APIs (no secrets in client) |
| Backup | After any server change, **sync `~/ziBashu` (local mirror)** — see §6 |

When implementing an online game, document in that app’s `MODULE.md`:

1. Server paths (compose, systemd unit, Laravel routes)
2. Env keys (names only; values live in server `.env` / secrets)
3. Ports and nginx vhost snippets
4. How to smoke-test from outside
5. How to roll back

---

## 1. Dual release artifacts (every shippable Android app)

From monorepo root after `. .\scripts\env.ps1`:

```powershell
# Preferred for Neon Chronos (signed APK + AAB)
.\scripts\build_neon_dual.ps1

# Generic single-app warehub APK + JSON
.\scripts\build_apk.ps1 -App <slug>
```

| Channel | Artifact | Use |
|---------|----------|-----|
| **Normal / WareHub** | `dist/<slug>-vX.Y.Z-warehub.apk` (+ `.json`) | Sideload store on zibashu4.com |
| **Play Store** | `dist/<slug>-vX.Y.Z-play.aab` (+ `.json`) | Google Play Console upload |

Signing lives only under `signing/` (gitignored). Never commit JKS or `keystore.properties`.  
Play checklist: upload AAB, enable Play App Signing, privacy/data safety, same `applicationId`.

---

## 2. Ship offline app to WareHub (procedure)

### 2.1 Server layout (production)

```text
/www/wwwroot/ziBashu4.com/
  storage/app/public/warehub/
    apks/                          # legacy / empty ok
    icons/                         # listing icons (public disk)
    packages/zibashu/              # android-*.apk packages
  public/storage -> storage/app/public   # storage:link
```

Laravel model: `App\Models\WarehubApp`  
Public routes: `/hub/warehub`, `/hub/warehub/{slug}`, `/hub/warehub/{slug}/download/{platform?}`  
Admin: `/admin/warehub` (auth admin only)

Platforms JSON (Android file example):

```json
{
  "android": {
    "enabled": true,
    "source": "file",
    "url": null,
    "file_path": "warehub/packages/zibashu/android-<unix>-<rand>.apk",
    "channel": "apk",
    "label": "APK (warehub)",
    "distro": null
  },
  "windows": { "enabled": false, "source": "file", "file_path": null },
  "macos":   { "enabled": false, "source": "file", "file_path": null },
  "linux":   { "enabled": false, "source": "file", "file_path": null },
  "ios":     { "enabled": false, "source": "link", "url": null }
}
```

`apk_path` is the denormalized Android shortcut = `platforms.android.file_path`.

### 2.2 Upload + register (agent pattern)

SSH/SFTP as **root** to `167.179.82.99` (credentials: owner-provided; **never commit passwords**).

1. Build warehub APK + icon (app icon PNG).
2. SFTP APK →  
   `/www/wwwroot/ziBashu4.com/storage/app/public/warehub/packages/zibashu/android-<ts>-<rand>.apk`
3. SFTP icon →  
   `.../warehub/icons/<random>.png`
4. Optionally drop dist metadata JSON next to the APK for ops trail.
5. `chown www:www` on new files; mode `644`.
6. Insert/update `warehub_apps` via artisan/bootstrap PHP or admin UI:
   - `slug` (URL key, e.g. `neon-chronos`)
   - `package_name` = `com.zibashu.<slug>`
   - `version_name` / `version_code` match `pubspec`
   - `category` (e.g. `tools`, `games`)
   - `content_rating` (default `everyone`)
   - `is_active=1`, optional `is_featured=1`
   - `icon_path`, `apk_path`, `platforms`, `size_bytes`
7. Smoke:

```text
https://zibashu4.com/hub/warehub/<slug>          → 200 HTML
https://zibashu4.com/hub/warehub/<slug>/download/android → file download
https://zibashu4.com/storage/warehub/packages/zibashu/<file>.apk → 200, correct Content-Length
```

### 2.3 Neon Chronos published row (reference)

| Field | Value |
|-------|--------|
| id | 2 |
| slug | `neon-chronos` |
| package | `com.zibashu.neon_chronos` |
| version | 3.0.1 / code 4 |
| category | tools |
| apk | `warehub/packages/zibashu/android-1786024601-fbio06.apk` (~55 MB) |
| mode | **offline** — no server game config |

Re-publish: bump version → rebuild dual → upload new APK → update same `slug` row (leave old APK files until confirmed).

---

## 3. Online game later: SSH + config checklist

When the product is **online**, agents must treat the VPS as part of the deliverable.

### 3.1 Connect

```bash
ssh root@167.179.82.99
# Host: zibashu-server (Ubuntu 22.04-class, aaPanel, Nginx, PHP 8.1, MySQL 5.7, Docker)
```

Prefer key-based auth when available. Do not print production secrets into git commits or client apps.

### 3.2 Typical config surfaces

| Layer | Where |
|-------|--------|
| Laravel app | `/www/wwwroot/ziBashu4.com` |
| Env | `/www/wwwroot/ziBashu4.com/.env` |
| Nginx vhost | aaPanel paths under `/www/server/panel/...` (see backup `04_nginx`) |
| Docker stacks | compose under site / `/root` (Around, Scoutlens, helpers) |
| Realtime | Soketi, meeting-relay, orvu (systemd) |
| TURN | coturn (`turn.zibashu4.com`) |
| MySQL | host DB `zibashu` |
| aaPanel | port **11641** (restrict by IP when possible) |

### 3.3 Agent order for a new online game backend

1. Design API contract in Laravel (or dedicated Docker service); no secrets in Flutter.
2. SSH: create migrations/routes/config on server **or** deploy from git and migrate.
3. Open only needed ports; prefer HTTPS reverse proxy over raw public ports.
4. Wire app `ApiConfig` / base URL to production host.
5. Smoke: health endpoint, auth, match/create, reconnect.
6. Build + upload APK to WareHub (same as offline).
7. **Sync local backup** (`C:\Users\syxMa\ziBashu`) — §6.
8. Document `MODULE.md` + this workflow if paths change.

### 3.4 What not to do on server

- Do not delete `full_backup_*` / critical backups without owner approval.
- Do not force-push production git history.
- Do not store upload keystores on the VPS unless owner asks.
- Do not expose MySQL/Redis/Docker ports publicly.

---

## 4. Play Store path (separate from WareHub)

1. `dist/*-play.aab` from dual build (or `flutter build appbundle --release` with signing).
2. Play Console → app with `applicationId` `com.zibashu.<slug>`.
3. Play App Signing on; keep upload JKS only in local `signing/` + offline backup.
4. WareHub APK and Play AAB may share the **same upload key** (Neon Chronos does).

---

## 5. Git rules (Android monorepo)

**Never commit:**

- `dist/*.apk`, `dist/*.aab`
- `signing/**`, `*.jks`, `keystore.properties`
- SSH passwords, production `.env`, panel credentials

**Do commit:** source, scripts, docs (including this file), registry, packages.

```powershell
cd C:\Users\syxMa\ANDROID
git add docs scripts apps packages AGENTS.md README.md
git commit -m "Document server ship workflow and WareHub offline publish path."
git pull --rebase origin main
git push origin main
```

---

## 6. Local mirror `C:\Users\syxMa\ziBashu` — mandatory backup discipline

### 6.1 What it is

**`C:\Users\syxMa\ziBashu`** is the **canonical off-server backup of production**. It is intended to **mirror everything needed to rebuild the same server completely** (site, env, DB dumps, nginx, certs, docker volumes/images, systemd, aaPanel snippets).

Layout (high level):

```text
C:\Users\syxMa\ziBashu\
  zibashu\                 # Laravel app git checkout (source)
  server_backups\          # full + critical tarballs, CHECKSUMS, DEPLOY_INSTRUCTIONS
    full_backup_*.tar.gz
    backup_critical_*.tar.gz
    critical_extracted\    # unpacked critical pack
    DEPLOY_INSTRUCTIONS.md # rebuild bible
    EXACT_RESTORE.md
    README_RESTORE.md
  cardhub\                 # misc hub samples
  database-backups\        # extra DB dumps if present
```

Production path mirrored by site code: `/www/wwwroot/ziBashu4.com`.

### 6.2 Agent rule: sync after server changes

Whenever you **SSH and change** production in a lasting way (env, nginx, docker, DB schema with data, warehub packages that matter for DR, new services), you **must refresh the local mirror** within the same work session or immediately after:

1. Prefer re-running the established backup scripts on the server (if present under `/root` or site `scripts/`), **or**
2. `rsync` / `scp` / SFTP the changed trees into `C:\Users\syxMa\ziBashu\` (site-critical paths + dumps), **or**
3. At minimum: update `server_backups` critical pack sections that changed (env, nginx, DB dump) and note the date in `server_backups/README_RESTORE.md`.

Also sync **periodically** even without a “big” change (owner guidance: **once in a while** so the mirror does not rot). Suggested cadence for agents:

| Trigger | Action |
|---------|--------|
| After any production deploy/config | Sync affected backup sections |
| After WareHub bulk package/DB changes | Include `storage/app/public/warehub` or DB dump of `warehub_apps` |
| Weekly / end of multi-day server work | Full critical backup refresh if feasible |
| Before risky migrations | Snapshot DB + `.env` into `server_backups` first |

Integrity: keep/update `CHECKSUMS_sha256.txt` when replacing tarballs. Full rebuild instructions stay in `DEPLOY_INSTRUCTIONS.md`.

### 6.3 Rebuild claim

If the VPS is lost, a competent agent should be able to rebuild from **`C:\Users\syxMa\ziBashu` alone** using `server_backups/DEPLOY_INSTRUCTIONS.md`. If your change is not in that mirror, **the backup is incomplete** — fix that before ending the session.

---

## 7. Session checklist (copy/paste)

### Offline APK (e.g. next Chronos version)

- [ ] Bump `pubspec` version + versionCode  
- [ ] Dual build → warehub APK + play AAB in `dist/`  
- [ ] SFTP APK + icon to `storage/app/public/warehub/...`  
- [ ] Upsert `warehub_apps` row; smoke public URLs  
- [ ] Commit docs/source only; push android.git  
- [ ] Play: upload AAB only if releasing to Play this cycle  
- [ ] If only files/DB listing changed, still note it; optional light backup sync  

### Online game (future)

- [ ] Design API; no secrets in client  
- [ ] SSH configure server (Laravel/Docker/nginx/systemd)  
- [ ] Smoke endpoints from outside  
- [ ] Build + WareHub (+ Play if needed)  
- [ ] **Sync `C:\Users\syxMa\ziBashu` backup**  
- [ ] Update this doc + app `MODULE.md`  

---

## 8. Quick reference URLs & IDs

| What | Value |
|------|--------|
| SSH | `root@167.179.82.99` |
| Site root | `/www/wwwroot/ziBashu4.com` |
| WareHub public | https://zibashu4.com/hub/warehub |
| Neon Chronos | https://zibashu4.com/hub/warehub/neon-chronos |
| Admin WareHub | https://zibashu4.com/admin/warehub |
| Local DR root | `C:\Users\syxMa\ziBashu` |
| Android monorepo | `C:\Users\syxMa\ANDROID` |

---

## 9. Prompt paste for next agent

```text
You are on the ziBashu stack.
- Android monorepo: C:\Users\syxMa\ANDROID — follow docs/NEXT_AGENT_STANDARD_WORKFLOW.md
- Server ship / offline vs online / backup: docs/AGENT_SERVER_AND_SHIP_WORKFLOW.md (read fully)
- Offline apps: build warehub APK (+ optional Play AAB), upload to WareHub on root@167.179.82.99
- Online games: SSH to server, configure services, then ship APK; never put secrets in the client
- C:\Users\syxMa\ziBashu is the full server rebuild mirror — sync it after server changes and periodically
- Never modify C:\Users\syxMa\android-ziBashu; never commit keystores or dist APKs
```
