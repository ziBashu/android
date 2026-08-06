# ziBashu Hub — APK module contract

| Field | Value |
|-------|--------|
| Name | ziBashu Hub |
| Slug | `hub` |
| Kind | `hub` |
| Surface | `hub` |
| applicationId | `com.zibashu.hub` |
| Folder | `apps/zibashu_hub` |
| Auth | none |
| Guest behavior | full catalog browse |
| Backend routes | optional remote warehub JSON later |
| Local storage | none required |
| Permissions | INTERNET (open web / future catalog fetch) |
| Distribution | warehub, Play later |
| Web fallback | `/` |

## Hardening

- [x] No secrets in client
- [x] Catalog from `zibashu_core`
- [x] `.\scripts\harden_check.ps1 -App hub`
