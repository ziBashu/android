# Warehub packaging

Warehub is the ziBashu site surface where users download family APKs. This monorepo **builds** APKs and metadata; it does not host them.

## Naming

| Field | Rule |
|-------|------|
| applicationId | `com.zibashu.<slug>` |
| APK file | `<slug>-v<versionName>.apk` |
| Metadata | `<slug>-v<versionName>.json` |

## Metadata schema

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

`scripts/build_apk.ps1` writes this next to the APK under `dist/`.

## Signing

- Dev/sideload keystore: generate under `signing/` (gitignored).
- Do **not** reuse the Play upload keystore from `android-ziBashu` unless you explicitly choose to.
- Users must enable “install unknown apps” for warehub sideloads.

## Version bumps

1. Edit `apps/<slug>/pubspec.yaml` → `version: x.y.z+code`
2. Rebuild with `.\scripts\build_apk.ps1 -App <slug>`
3. Upload both APK and JSON to warehub
