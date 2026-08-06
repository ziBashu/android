# Warehub packaging

WareHub is the ziBashu **public** multi-device download shelf on the production site. This monorepo **builds** APKs/metadata; **hosting** is on the VPS under Laravel `WarehubApp`.

**Full agent procedure (SSH, paths, offline vs online, backup sync):**  
→ [AGENT_SERVER_AND_SHIP_WORKFLOW.md](./AGENT_SERVER_AND_SHIP_WORKFLOW.md)

| Surface | URL |
|---------|-----|
| Storefront | https://zibashu4.com/hub/warehub |
| Admin publish | https://zibashu4.com/admin/warehub (URL only) |
| Server files | `/www/wwwroot/ziBashu4.com/storage/app/public/warehub/` |

## Naming

| Field | Rule |
|-------|------|
| applicationId | `com.zibashu.<slug>` |
| Local APK file | `<slug>-v<versionName>.apk` or `*-warehub.apk` |
| Local metadata | `<slug>-v<versionName>.json` |
| Server package file | `warehub/packages/zibashu/android-<unix>-<rand>.apk` |
| Listing slug | URL-safe (e.g. `neon-chronos`) |

## Metadata schema (local dist JSON)

```json
{
  "slug": "seru",
  "name": "Seru",
  "packageId": "com.zibashu.seru",
  "versionName": "0.1.0",
  "versionCode": 1,
  "minSdk": 24,
  "family": "ziBashu",
  "surface": "messaging",
  "apk": "seru-v0.1.0.apk",
  "website": "https://zibashu4.com",
  "route": "/seru",
  "blurb": "Private messaging for the ziBashu system."
}
```

`scripts/build_apk.ps1` / `build_neon_dual.ps1` write this next to the APK under `dist/`.  
Production listing fields live in MySQL table `warehub_apps` (see workflow doc).

## Signing

- Public warehub stable + Play: upload keystore under `signing/` (gitignored).
- Do **not** reuse the Play upload keystore from `android-ziBashu` unless you explicitly choose to.
- Users must enable “install unknown apps” for warehub sideloads.

## Version bumps

1. Edit `apps/<slug>/pubspec.yaml` → `version: x.y.z+code`
2. Rebuild with `.\scripts\build_apk.ps1 -App <slug>` or dual-build script
3. Upload APK (+ icon) to server warehub storage and upsert `warehub_apps`
4. Smoke https://zibashu4.com/hub/warehub/`<listing-slug>`
