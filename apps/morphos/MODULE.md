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
| Permissions | INTERNET, VIBRATE, RECEIVE_BOOT_COMPLETED, QUERY_ALL_PACKAGES, SET_WALLPAPER, SET_WALLPAPER_HINTS, WRITE_SETTINGS, SYSTEM_ALERT_WINDOW, Accessibility service |
| Distribution | warehub (Play later) |
| Web fallback | `/hub` |
| Blurb | Transformable phone interface — morph packs, store, creator, desktop, system orientation. |
| Version | **`0.5.0+6`** |

## Product line

**Appearance → Behavior → Intelligence → Environment → Ecosystem → Platform**

| Phase | Status in 0.5.0 |
|-------|-----------------|
| 0 Foundation | Done |
| 1 Identity | Done |
| 2 Morph Engine | Done |
| 2+ System Morph (Accessibility) | Done |
| 3 Adaptive Environment | Done |
| 4 Desktop Mode | Done |
| **5 Ecosystem (Store / Creator / share)** | **Done (offline morphpack/v1)** |
| 6 Platform / ROM | Roadmap |

## Phase 5 behavior

- **Morph Store** — offline shelf of curated packs (theme / layout / mode / community)
- **My Modes** — installed + user-created pack library
- **Morph Creator** — capture current look → named pack without coding
- **Community share** — export/import `morphpack/v1` JSON via clipboard
- Same pack schema ready for future online warehub Morph Store

## Phase 2+ / 4 (retained)

- Accessibility system orientation + WRITE_SETTINGS consent
- Desktop shell, floating tasks, external display detect

## References

`docs/morphos-reference-notes.md` · `C:\Users\syxMa\ANDROID-reference`

## Hardening

- [x] No secrets
- [x] HOME + LAUNCHER intents (Flutter-safe activity flags)
- [x] minSdk ≥ 24
- [x] analyze / unit tests
- [ ] Warehub upload when requested
