# Neon Chronos — dual release artifacts

## Outputs

| Product | File | Use |
|---------|------|-----|
| **Normal (warehub)** | `dist/neon_chronos-vX.Y.Z-warehub.apk` | Sideload, warehub, device install |
| **Play Store** | `dist/neon_chronos-vX.Y.Z-play.aab` | Google Play Console upload |

Same `applicationId` (`com.zibashu.neon_chronos`), same version, same upload keystore.

## Build

```powershell
cd C:\Users\syxMa\ANDROID
. .\scripts\env.ps1
.\scripts\build_neon_dual.ps1
```

Requires (gitignored):

- `signing/zibashu-upload.jks`
- `signing/keystore.properties`

## Signing

- Alias: `zibashu_upload`
- **Never commit** keystore or passwords
- Back up offline before first Play upload
- Play App Signing: upload the AAB; Google may re-sign with the app signing key

## Play Console checklist

1. Create app `com.zibashu.neon_chronos` (or import)
2. Upload **AAB** to Internal testing
3. Store listing, graphics, content rating, target audience
4. Privacy policy if you declare data collection
5. Promote Internal → Closed → Production when ready

## Install warehub APK

```powershell
adb install -r dist\neon_chronos-v3.0.1-warehub.apk
```
