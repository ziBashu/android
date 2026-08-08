# MorphOS — reference notes (ANDROID-reference)

Local folder: `C:\Users\syxMa\ANDROID-reference`

## Reference APKs (2026-08-08)

| File | Package | Role for MorphOS |
|------|---------|------------------|
| **`Launcher_OS_6.3.15_APKPure.apk`** | `com.babydola.launcherios` v6.3.15 | **Primary home/launcher reference** |
| `Launcher+OST_6.3.15_APKPure.xapk` | same family (bundle) | Full install bundle if split needed |
| `rotation-orientation-manager-29-3-4.apk` | `com.pranavpandey.rotation` | **Morph Engine / orientation** reference |
| `uptodown-com.launcheros.fastlauncher.apk` | `com.uptodown` | App store / package install UX (not a launcher) |

---

## Launcher OS (primary) — what to mirror

Label: **Launcher OS**. Built on **AOSP Launcher3** (`com.android.launcher3.*`) with iOS-style chrome.

### Home entry (must copy pattern)

```
Activity: com.android.launcher3.Launcher
  MAIN
  HOME
  DEFAULT
  MONKEY
  LAUNCHER_APP

Splash / app icon: com.android.launcher3.SplashActivity
  MAIN + LAUNCHER
```

MorphOS Flutter MainActivity must declare the same **HOME** intent filter so the user can set MorphOS as default home.

### Feature surfaces (product UX map)

| Surface | Activity / idea | MorphOS mapping |
|---------|-----------------|-----------------|
| Home workspace + dock | Launcher | Home + dock layouts |
| Theme packs | `theme.SplashThemePackActivity` | Theme engine (Phase 1) |
| Wallpaper | deep link `/wallpaper/home` | Wallpaper engine |
| Control center | `feature.control.SplashControlCenter` | Quick morph / settings sheet |
| Clock widget page | `feature.clock.SplashClockActivity` | Clock widget on home |
| Weather | `feature.weather.*` | Widget slot (later) |
| Gallery | `feature.gallery.*` | Wallpaper pick |
| Calculator | `feature.calculator.*` | Optional utility (not core) |
| AI bottom page | `bottompage.SplashAiPageActivity` | Skip for MorphOS (no AI first) |
| App pin / widgets | `dragndrop.AddItemActivity` | Long-press add (Phase 1–2) |
| Notifications | `notification.LauncherNotificationService` | Optional Phase 2+ |

### Permissions Launcher OS uses (curate for MorphOS)

**Phase 0 (minimal, MorphOS):**

- `QUERY_ALL_PACKAGES` — app drawer
- `RECEIVE_BOOT_COMPLETED` — restore launcher after reboot
- `VIBRATE` — feedback
- `SET_WALLPAPER` / `SET_WALLPAPER_HINTS` — wallpaper engine (Phase 1)
- `INTERNET` / `ACCESS_NETWORK_STATE` — only if remote themes later; avoid if offline-first

**Phase 1–2 (as needed, with UX copy):**

- `READ_MEDIA_IMAGES` — custom wallpaper from gallery
- `BIND_APPWIDGET` — system widgets (hard on Flutter; later)
- `PACKAGE_USAGE_STATS` — adaptive morph by app usage
- `REQUEST_DELETE_PACKAGES` — uninstall from drawer

**Do not blindly copy from Launcher OS:** contacts, calendar, fine location, camera — not needed for MorphOS core.

### Product differentiation (MorphOS vs Launcher OS)

| Launcher OS | MorphOS |
|-------------|---------|
| iOS-like skin on Launcher3 | Adaptive **morph profiles** + orientation personality |
| Theme store / packs | Themes + **Work / Gaming / Reading / Car / Desktop** morphs |
| Control center | Morph hub + orientation engine |
| Heavy optional sensors | Lean permissions first |

---

## Rotation (orientation reference)

Package: `com.pranavpandey.rotation`

How real per-app / forced orientation works in the wild:

| Piece | Detail |
|-------|--------|
| Core | `AccessibilityService` (`RotationService`) |
| Overlay | `SYSTEM_ALERT_WINDOW` |
| Settings write | `WRITE_SETTINGS` |
| QS tiles | Quick Settings for orientation |
| Boot | `RECEIVE_BOOT_COMPLETED` |
| App list | `QUERY_ALL_PACKAGES` + usage stats |

**MorphOS Phase 0–1:** only lock MorphOS activity orientation via Flutter `SystemChrome` per morph profile.  
**MorphOS Phase 2 (Morph Engine):** follow Rotation’s model (accessibility / overlay) for **system-wide / per-app** morphing — document consent screens carefully.

---

## MorphOS progress vs references

| Ref capability | MorphOS 0.4.0 |
|----------------|---------------|
| HOME launcher candidate | Yes (`MAIN`+`HOME`+`DEFAULT`) |
| Dock + workspace layouts | Yes (grid / minimal / spatial / cards / **desktop**) |
| Theme / wallpaper packs | Yes (5 themes · 7 wallpapers) |
| Control center | Yes (swipe down Morph Control) |
| Per-app behavior | Yes (in-app morph rules + package rules to native) |
| System-wide orientation | **Yes** — `MorphOrientationService` + WRITE_SETTINGS (consent) |
| Desktop mode | **Yes** — rail/workspace/floating tasks + external display detect |

---

## MorphOS AndroidManifest checklist (from references)

```xml
<!-- App icon -->
MAIN + LAUNCHER

<!-- Default home candidate -->
MAIN + HOME + DEFAULT

<!-- Drawer -->
QUERY_ALL_PACKAGES

<!-- Wallpaper -->
SET_WALLPAPER
SET_WALLPAPER_HINTS

<!-- Survive reboot as home -->
RECEIVE_BOOT_COMPLETED
```

Phase 2+ (0.4.0): accessibility service + WRITE_SETTINGS with in-app consent; optional overlay permission reserved.

---

## Install on emulator (agent)

```powershell
adb install -r C:\Users\syxMa\ANDROID-reference\Launcher_OS_6.3.15_APKPure.apk
adb install -r C:\Users\syxMa\ANDROID-reference\rotation-orientation-manager-29-3-4.apk
adb shell am start -n com.babydola.launcherios/com.android.launcher3.SplashActivity
```

Screenshots (local): `screenshots/launcheros_ref*.png`.
