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
| Local storage | SharedPreferences `morphos_state_v2` |
| Permissions | INTERNET, VIBRATE, RECEIVE_BOOT_COMPLETED, QUERY_ALL_PACKAGES, SET_WALLPAPER, SET_WALLPAPER_HINTS |
| Distribution | warehub (Play later) |
| Web fallback | `/hub` |
| Blurb | Transformable phone interface — adaptive launcher and morph profiles. |
| Version | **`0.3.0+3`** |

## Product line

**Appearance → Behavior → Intelligence → Environment → Ecosystem → Platform**

| Phase | Status in 0.3.0 |
|-------|-----------------|
| 0 Foundation | Done |
| 1 Identity | Done + hardened |
| 2 Morph Engine (packs, rules, gestures) | Done (in-app) |
| **3 Adaptive Environment** | **Done (time / charge / category + device apps)** |
| 2+/3+ system-wide orientation (Accessibility) | Roadmap |
| 4 Desktop external display | Roadmap |
| 5–6 Ecosystem / ROM | Roadmap |

## Phase 3 behavior

- **Device app catalog** via `installed_apps` (fallback to demo grid)
- **Launch** real packages from home/drawer
- **Category adaptive morph** (game/nav/work/media/read heuristics)
- **Charge → Desktop Morph** (`battery_plus`), restore previous morph on unplug
- **Time-based morph** (optional, 5‑min tick)
- Explicit per-app rules still override category

## References

`docs/morphos-reference-notes.md` · `C:\Users\syxMa\ANDROID-reference`

## Hardening

- [x] No secrets
- [x] HOME + LAUNCHER intents (Flutter-safe activity flags)
- [x] minSdk ≥ 24
- [x] analyze / unit tests
- [ ] Warehub upload when requested
