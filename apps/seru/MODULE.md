# Seru — APK module contract

| Field | Value |
|-------|--------|
| Name | Seru |
| Slug | `seru` |
| Kind | `messaging` |
| Surface | `messaging` |
| applicationId | `com.zibashu.seru` |
| Folder | `apps/seru` |
| Auth | ziBashu device-code: `POST /api/mobile/auth/device` + poll; demo shell without a token |
| Guest behavior | login or Continue in demo |
| Backend | `https://zibashu4.com` — `/api/mobile/seru/*`, `/api/mobile/threads`, `/api/mobile/ziba/*` |
| Local storage | Sanctum token (secure); DM bodies on-device only |
| Permissions | INTERNET |
| Distribution | warehub, Play later |
| Web fallback | `/seru` |

## Server (online product)

| Item | Path |
|------|------|
| Laravel | `/www/wwwroot/ziBashu4.com` on `167.179.82.99` |
| Device approve page | `/seru/auth/device` |
| Pay codes table | `ziba_pay_codes` via `ZibaPayCodeService` → `ZibaService.transfer` |
| Realtime (web) | Soketi `:6001`; APK v1 posts envelopes and keeps bodies locally |
| Env | none new in the APK; Sanctum already on the site |

Smoke: `POST /api/mobile/auth/device` → 200 JSON with `user_code`; guest `GET /api/mobile/me` → 401.

## Hardening

- [x] No secrets in client
- [x] Min permissions
- [x] Live Sanctum device-code (not email/password)
- [x] Native Flutter shell (not a WebView of zibashu4.com)
- [x] `.\scripts\harden_check.ps1 -App seru`
