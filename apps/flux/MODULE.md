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
```

Artifacts:

- `dist/flux-v0.1.0-warehub.apk`
- `dist/flux-v0.1.0-play.aab`

## Server

Laravel:

- `App\Http\Controllers\FluxController`
- routes in `routes/api.php` + `routes/web.php`
- state file: `storage/app/flux/control.json`
