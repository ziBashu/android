# MorphOS — APK module contract

| Field | Value |
|-------|--------|
| Name | MorphOS |
| Slug | `morphos` |
| Kind | `other` (adaptive interface / launcher) |
| Surface | `other` |
| applicationId | `com.zibashu.morphos` |
| Folder | `apps/morphos` |
| Auth | none |
| Guest behavior | full offline + optional device app list |
| Backend routes | none (Phase 5 store offline; online later) |
| Local storage | SharedPreferences `morphos_state_v2` + native `morphos_system_v1` |
| Permissions | INTERNET, VIBRATE, RECEIVE_BOOT_COMPLETED, QUERY_ALL_PACKAGES, SET_WALLPAPER, SET_WALLPAPER_HINTS, WRITE_SETTINGS, SYSTEM_ALERT_WINDOW, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Accessibility, QS tile |
| Distribution | warehub (Play later) |
| Web fallback | `/hub` |
| Blurb | Transformable phone environment — platform layer, morph packs, desktop, system orientation. |
| Version | **`0.6.1+8`** |

## Product line

**Appearance → Behavior → Intelligence → Environment → Ecosystem → Platform**

| Phase | Status in 0.6.1 |
|-------|-----------------|
| 0–6 | Done (APK track) |
| 6+ Custom ROM | Long-term vision (not this APK) |

## Hardening (0.6.1)

- [x] No secrets in client
- [x] Package `com.zibashu.morphos` only
- [x] HOME + LAUNCHER intents (Flutter-safe activity flags)
- [x] minSdk ≥ 24
- [x] **Cleartext traffic disabled** + `network_security_config`
- [x] **allowBackup=false** + data extraction excludes
- [x] Exported services permission-gated (a11y, QS tile)
- [x] Boot receiver local-only reapply (no network)
- [x] from ziBashu chrome on major surfaces
- [x] Demo/offline when device APIs fail
- [x] analyze / unit tests / harden_check
- [ ] Warehub upload when requested
- [ ] Play upload keystore (still debug-signed for sideload)

## Phase summary

- **2+** Accessibility orientation + WRITE_SETTINGS  
- **3** Adaptive time/charge/category + device apps  
- **4** Desktop shell + floating tasks  
- **5** Morph Store / Creator / morphpack/v1  
- **6** Platform Control · QS tile · boot restore · chrome  

## References

`docs/morphos-reference-notes.md` · `C:\Users\syxMa\ANDROID-reference`
