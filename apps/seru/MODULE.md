# Seru — APK module contract

| Field | Value |
|-------|--------|
| Name | Seru |
| Slug | `seru` |
| Kind | `messaging` |
| Surface | `messaging` |
| applicationId | `com.zibashu.seru` |
| Folder | `apps/seru` |
| Auth | demo mode default; live Sanctum via `POST /api/mobile/login` |
| Guest behavior | login required |
| Backend routes | `/api/mobile/login` (planned), Seru realtime later |
| Local storage | secure token; messages local-first (demo inbox now) |
| Permissions | INTERNET |
| Distribution | warehub, Play later |
| Web fallback | `/seru` |

## Hardening

- [x] No secrets in client
- [x] Min permissions
- [ ] Live auth endpoint on Laravel when leaving demo mode
- [x] `.\scripts\harden_check.ps1 -App seru`
