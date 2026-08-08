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
| Backend routes | none |
| Local storage | SharedPreferences `morphos_state_v2` + native `morphos_system_v1` |
| Permissions | INTERNET, VIBRATE, RECEIVE_BOOT_COMPLETED, QUERY_ALL_PACKAGES, SET_WALLPAPER, SET_WALLPAPER_HINTS, WRITE_SETTINGS, SYSTEM_ALERT_WINDOW, Accessibility service |
| Distribution | warehub (Play later) |
| Web fallback | `/hub` |
| Blurb | Transformable phone interface — adaptive launcher, system morph, desktop mode. |
| Version | **`0.4.0+4`** |

## Product line

**Appearance → Behavior → Intelligence → Environment → Ecosystem → Platform**

| Phase | Status in 0.4.0 |
|-------|-----------------|
| 0 Foundation | Done |
| 1 Identity | Done |
| 2 Morph Engine (packs, rules, gestures) | Done (in-app) |
| **2+ System Morph (Accessibility orientation)** | **Done (consent + service + WRITE_SETTINGS)** |
| 3 Adaptive Environment | Done (time / charge / category + device apps) |
| **4 Desktop Mode** | **Done (shell, floating tasks, display detect, pointer/keyboard)** |
| 5–6 Ecosystem / ROM | Roadmap |

## Phase 2+ behavior

- **MorphOrientationService** AccessibilityService (foreground package)
- **WRITE_SETTINGS** locks system rotation per morph profile / per-app package rules
- Consent path in Settings → enable Accessibility + modify system settings
- Flutter `SystemMorphBridge` channel `com.zibashu.morphos/system`

## Phase 4 behavior

- **Desktop layout** rail + workspace + taskbar when Desktop Morph (or external display)
- **Floating task windows** (long-press / Ctrl+tap)
- **DisplayManager** external display detection
- Mouse hover + keyboard presence chrome

## References

`docs/morphos-reference-notes.md` · `C:\Users\syxMa\ANDROID-reference`

## Hardening

- [x] No secrets
- [x] HOME + LAUNCHER intents (Flutter-safe activity flags)
- [x] minSdk ≥ 24
- [x] analyze / unit tests
- [ ] Warehub upload when requested
