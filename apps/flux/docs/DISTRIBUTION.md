# Flux Android distribution

See also Windows: `~/WINDOWS/projects/Flux/docs/DISTRIBUTION.md`.

| Channel | Artifact | Destination |
|---------|----------|-------------|
| WareHub | `flux-v*-warehub.apk` | **Public** — WareHub listing `slug=flux` |
| Play | `flux-v*-play.aab` | **Play Console** (+ private server archive) |
| Vault | optional APK/AAB copy | Internal ops only |

Build:

```powershell
cd C:\Users\syxMa\ANDROID
. .\scripts\env.ps1
.\scripts\build_flux_dual.ps1
.\scripts\publish_flux_warehub.ps1   # upload APK + register/update listing
```
