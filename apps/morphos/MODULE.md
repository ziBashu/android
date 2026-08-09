# MorphOS — APK module contract

| Field | Value |
|-------|--------|
| Name | MorphOS |
| Slug | `morphos` |
| Kind | `other` (personal adaptive environment layer / global launcher) |
| Surface | `other` |
| applicationId | `com.zibashu.morphos` |
| Folder | `apps/morphos` |
| Auth | none |
| Guest behavior | full offline + optional device app list |
| Backend routes | none (Phase 5 store offline; online later) |
| Local storage | SharedPreferences `morphos_state_v2` + native `morphos_system_v1` |
| Permissions | INTERNET, VIBRATE, RECEIVE_BOOT_COMPLETED, QUERY_ALL_PACKAGES, SET_WALLPAPER, SET_WALLPAPER_HINTS, WRITE_SETTINGS, SYSTEM_ALERT_WINDOW, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, READ_MEDIA_IMAGES, Accessibility, QS tile |
| Distribution | warehub (Play later) |
| Web fallback | `/hub` |
| Blurb | Personal adaptive environment — global home launcher, productivity widgets, morph packs. |
| Version | **`1.0.0+11`** |
| Launcher icon | Custom ziBashu brand mark (`assets/brand/morphos_launcher_1024.png`) — not Flutter default |

## Product identity

> MorphOS sits between the user and the phone.  
> **Android gives apps. MorphOS gives environments.**  
> **1.0.0:** first-class HOME launcher candidate with productivity chrome and full MorphOS-side customization.

Canonical product design: **`docs/morphos-product-vision.md`** (12 questions + five fundamentals).

## 1.0.0 highlights

| Area | Feature |
|------|---------|
| Global launcher | MAIN+HOME+DEFAULT · singleTask · “Set as Home” CTA on home + settings |
| Productivity | Battery widget · quick rotation · ranked quick app search |
| Search | Label-first ranking (`brave` → **Brave**) |
| Customization | Crop icon from photo · portrait + landscape wallpapers · icon scale / grid persist |
| Morph engine | Profiles, intelligence modes, packs, system orientation (prior work) |

## Five fundamentals

| Question | Feature | In 1.0 |
|----------|---------|--------|
| How does my phone look? | Customization | themes · dual wallpapers · icons from photos · rename · layouts · size |
| How does my phone behave? | Modes | full Morph environments |
| How does it change shape? | Orientation engine | profile + quick rotation + optional system morph |
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

**Appearance → Behavior → Intelligence → Environment → Ecosystem → Platform → 1.0 Launcher**

| Phase | Status |
|-------|--------|
| 0–6 | Done (APK track) |
| 0.7 Vision alignment | Study/Travel, intelligence modes, context rules, vision UI |
| 0.7.1 Phone connection | Device app detect + rename/icon · system rotation permissions |
| **1.0.0 Global launcher** | HOME role CTA · productivity strip · ranked search · dual wallpapers · icon crop |
| 6+ Custom ROM | Long-term vision (not this APK) |

## Hardening

- [x] No secrets in client
- [x] Package `com.zibashu.morphos` only
- [x] HOME + LAUNCHER intents (Flutter-safe activity flags; singleTask)
- [x] minSdk ≥ 24
- [x] Cleartext traffic disabled + `network_security_config`
- [x] allowBackup=false + data extraction excludes
- [x] Exported services permission-gated (a11y, QS tile)
- [x] Boot receiver local-only reapply (no network)
- [x] from ziBashu chrome on major surfaces
- [x] Custom MorphOS launcher icon (ziBashu forest/cream + brand mark)
- [x] Demo/offline when device APIs fail
- [x] analyze / unit tests / harden_check
- [x] Warehub upload **v1.0.0** — https://zibashu4.com/hub/warehub/morphos
- [x] Dual signed release (upload keystore): warehub APK + Play AAB in `dist/`
- [ ] Play Console upload (AAB ready; Internal track when requested)

## References

`docs/morphos-product-vision.md` · `docs/morphos-reference-notes.md` · `C:\Users\syxMa\ANDROID-reference`
