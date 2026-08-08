# MorphOS — APK module contract

| Field | Value |
|-------|--------|
| Name | MorphOS |
| Slug | `morphos` |
| Kind | `other` (personal adaptive environment layer) |
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
| Blurb | Personal adaptive environment — shapes, spaces, intelligence, morph packs. |
| Version | **`0.7.1+10`** |
| Launcher icon | Custom ziBashu brand mark (`assets/brand/morphos_launcher_1024.png`) — not Flutter default |

## Product identity

> MorphOS sits between the user and the phone.  
> **Android gives apps. MorphOS gives environments.**

Canonical product design: **`docs/morphos-product-vision.md`** (12 questions + five fundamentals).

## Five fundamentals

| Question | Feature | In 0.7 |
|----------|---------|--------|
| How does my phone look? | Customization | themes · wallpaper · icons · rename · layouts |
| How does my phone behave? | Modes | full Morph environments |
| How does it change shape? | Orientation engine | profile + optional system morph |
| How does it adapt? | Context system | auto / ask / advanced rules |
| How do I create my own? | Morph Creator | store + morphpack share |

## Environments (device shapes)

| Morph | Shape |
|-------|--------|
| Pocket | Pocket device |
| Gaming | Gaming console |
| Desktop | Mini computer |
| Reading | Book reader |
| Dashboard (car) | Dashboard |
| Work / Relax / Study / Travel | Situation spaces |

## Intelligence modes

- **Beginner · Auto** — open game → Gaming Morph
- **Ask first** — “Switch to desktop?”
- **Advanced · Rules** — IF/THEN context + per-app only

## Product line (build phases)

**Appearance → Behavior → Intelligence → Environment → Ecosystem → Platform**

| Phase | Status |
|-------|--------|
| 0–6 | Done (APK track) |
| 0.7 Vision alignment | Study/Travel, intelligence modes, context rules, vision UI |
| 0.7.1 Phone connection | Device app detect + rename/icon · system rotation permissions + test |
| 6+ Custom ROM | Long-term vision (not this APK) |

## Hardening

- [x] No secrets in client
- [x] Package `com.zibashu.morphos` only
- [x] HOME + LAUNCHER intents (Flutter-safe activity flags)
- [x] minSdk ≥ 24
- [x] Cleartext traffic disabled + `network_security_config`
- [x] allowBackup=false + data extraction excludes
- [x] Exported services permission-gated (a11y, QS tile)
- [x] Boot receiver local-only reapply (no network)
- [x] from ziBashu chrome on major surfaces
- [x] Custom MorphOS launcher icon (ziBashu forest/cream + brand mark)
- [x] Demo/offline when device APIs fail
- [x] analyze / unit tests / harden_check
- [x] Warehub upload **v0.7.1** — https://zibashu4.com/hub/warehub/morphos
- [x] Dual signed release (upload keystore): warehub APK + Play AAB in `dist/`
- [ ] Play Console upload (AAB ready; Internal track when requested)

## References

`docs/morphos-product-vision.md` · `docs/morphos-reference-notes.md` · `C:\Users\syxMa\ANDROID-reference`
