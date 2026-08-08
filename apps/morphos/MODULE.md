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
| Permissions | INTERNET, VIBRATE, RECEIVE_BOOT_COMPLETED, QUERY_ALL_PACKAGES, SET_WALLPAPER, SET_WALLPAPER_HINTS, WRITE_SETTINGS, SYSTEM_ALERT_WINDOW, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, WAKE_LOCK, Accessibility, QS tile |
| Distribution | warehub (Play later) |
| Web fallback | `/hub` |
| Blurb | Transformable phone environment — platform layer, morph packs, desktop, system orientation. |
| Version | **`0.6.0+7`** |

## Product line

**Appearance → Behavior → Intelligence → Environment → Ecosystem → Platform**

| Phase | Status in 0.6.0 |
|-------|-----------------|
| 0 Foundation | Done |
| 1 Identity | Done |
| 2 Morph Engine | Done |
| 2+ System Morph (Accessibility) | Done |
| 3 Adaptive Environment | Done |
| 4 Desktop Mode | Done |
| 5 Ecosystem (Store / Creator / share) | Done |
| **6 Platform Layer** | **Done (control plane on stock Android)** |
| 6+ Custom ROM | Long-term vision (not this APK) |

## Phase 6 behavior

- **Platform Control** screen — readiness score, hook consent
- **Default home** role / settings entry
- **QS tile** “MorphOS Morph” cycles system orientation
- **Boot receiver** reapplies system morph after reboot
- **Battery unrestricted** request for survival
- **System UI chrome** follows morph palette (immersive edge-to-edge)
- **Keep screen on** in Desktop Morph / external display
- Honest roadmap: full MorphOS ROM is future; this is the platform layer

## Phase 5 (retained)

Morph Store · Creator · morphpack/v1 community share

## References

`docs/morphos-reference-notes.md` · `C:\Users\syxMa\ANDROID-reference`

## Hardening

- [x] No secrets
- [x] HOME + LAUNCHER intents (Flutter-safe activity flags)
- [x] minSdk ≥ 24
- [x] analyze / unit tests
- [ ] Warehub upload when requested
