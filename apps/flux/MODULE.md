# Flux (Android)

| Field | Value |
|-------|-------|
| Package | `com.zibashu.flux` |
| Kind | tool / VPN client |
| Version | 0.1.0+1 |
| Codename | HULK foundation |
| Mode | Online product (server-backed) but **VPN locked** |
| Account | ziBashu Sanctum (demo mode local) |
| Control | `GET https://zibashu4.com/api/flux/control` |
| Admin | `https://zibashu4.com/admin/flux` (auth+admin) |

## Foundation rules

- `FluxGate.localHardLock = true` — no tunnel
- Server always returns `enabled: false`
- No public users can use VPN yet

## Dual ship

```powershell
cd C:\Users\syxMa\ANDROID
. .\scripts\env.ps1
.\scripts\build_flux_dual.ps1
.\scripts\publish_flux_warehub.ps1
```

Artifacts:

- `dist/flux-v0.1.0-warehub.apk` → **WareHub** public
- `dist/flux-v0.1.0-play.aab` → Play Console (+ private server archive)

Public listing: https://zibashu4.com/hub/warehub/flux  
Windows bundles stay on **vault** (`/opt/windows-vault/flux`), not public WareHub.

## Server

Laravel:

- `App\Http\Controllers\FluxController`
- routes in `routes/api.php` + `routes/web.php`
- state file: `storage/app/flux/control.json`
- session issue: `POST /api/flux/session` (403 while locked)
