# KEYLINE IME

Offline-first English keyboard. Package `com.zibashu.keyline`.

## How Android IMEs work in this project

Android shows KEYLINE because the APK declares an `InputMethodService` with
`BIND_INPUT_METHOD` and `android.view.im` metadata (`res/xml/method.xml`).

The user enables it under **Settings → System → Languages & input → On-screen keyboard**.

Runtime path:

1. `KeylineImeService` is created (no Flutter engine).
2. `onCreateInputView` builds `KeyboardHostView`.
3. `onStartInput` / `onStartInputView` wrap `currentInputConnection` as `KeylineEditor`.
4. `InputController` decides what text to commit.
5. Hiding the keyboard calls `onFinishInputView` → composing text is committed.

The Flutter `MainActivity` is only the setup / privacy screen. It is not the keyboard.

The IME service uses `Theme.DeviceDefault.InputMethod` and always returns true from
`onEvaluateInputViewShown()` so the software keyboard still appears on emulators
(and phones) that expose a hardware keyboard.

## Architecture

| Layer | Role |
|-------|------|
| IME service | Lifecycle, InputConnection, view attachment |
| Keyboard UI | `KeyboardHostView`, `KeyboardPadView`, long-press popup |
| Input controller | Insert, delete, shift, layer switch, composing |
| Layout | Data-driven rows of `KeyDefinition` + `LayoutEngine` |
| Language pack | `LanguageProvider` / `EnglishProvider` |
| Dictionary | Offline word list + frequency |
| Suggestion engine | Prefix completions |
| Autocorrect | Conservative edit-distance-1 replacement |
| Settings | SharedPreferences snapshot |
| Theme | `KeylinePalette` tokens (light / dark) |

Do not put English layout or dictionary lookups in the IME service.

## Keyboard layout system

`KeyboardLayout` is a list of `KeyboardRow`. Each key has a **weight**.
`LayoutEngine.measure(layout, width, height, gap)` produces `KeyRect`s.
Geometry is proportional: never hardcoded screen coordinates.

English QWERTY lives in `EnglishLayouts.alphabet`. The number/symbol layer is
`EnglishLayouts.symbols`.

## Key definition system

`KeyDefinition` fields: id, label, output, alternates, type, weight,
contentDescription.

Long-press characters are **data on the key**, not a per-key UI fork.
The popup reads `key.alternates` and places itself with `PopupPlacement`.

## Language architecture

```
LanguageProvider
  EnglishProvider     ← V1
  ChinesePinyinProvider   ← do not implement yet
  JapaneseRomajiProvider  ← do not implement yet
```

`LanguageRegistry.get(id)` is how the IME picks a pack. A new language is a new
provider plus its layout + dictionary, registered in the list.

### How to add another language

1. Add `XxxProvider : LanguageProvider` with its layouts and dictionary.
2. Register it in `KeylineImeService` (`LanguageRegistry(listOf(EnglishProvider(...), XxxProvider(...)))`).
3. Expose the id in settings. Do not fork `InputController` for letters vs. CJK.

## Suggestion engine

`SuggestionEngine.suggest(prefix)` returns the highest-frequency dictionary
words that start with the prefix and are not the prefix itself.

Example: `hel` → hello, help, helpful.

Disabled by the Suggestions setting, and always off in password fields.

## Autocorrect

`Autocorrect.decide(typed)`:

- If the token is already a dictionary word → do nothing.
- Else consider Damerau-Levenshtein distance-1 neighbors.
- Silent replace only when the best neighbor is ≥ 10× more frequent than the next.
- Otherwise show suggestions; never guess.

Example: `teh` → `the`.

## Settings

Native `SettingsActivity` (also linked from IME metadata):

- Theme: System / Light / Dark
- Keyboard height: Compact / Normal / Tall
- Key size / spacing: Compact / Normal / Large
- Key vibration, key sound
- Suggestions, auto-correction, auto-capitalization
- Language: English (V1)

## Theme

`KeylinePalette` is the source of truth for keyboard colors.
`res/values/colors.xml` and `values-night/colors.xml` duplicate the same tokens
for the settings screen. Do not scatter product hex values in views.

## How to build the APK

From the ANDROID repo root:

```powershell
. .\scripts\env.ps1
.\scripts\build_apk.ps1 -App keyline
```

Artifact: `dist/keyline-v1.0.0.apk`

Unit tests (gating):

```powershell
cd apps\keyline\android
.\gradlew.bat :app:testDebugUnitTest
```

AGP 9 in this repo does not register `testReleaseUnitTest`; debug unit tests compile the same shipped Kotlin.

## How to install

```powershell
adb install -r dist\keyline-v1.0.0.apk
```

## How to enable KEYLINE

1. Install the APK.
2. Open the KEYLINE app, or Android **Settings → Keyboard / input method**.
3. Enable KEYLINE.
4. Switch the current input method to KEYLINE.
5. Focus a text field.

## Privacy

No analytics, ads, accounts, crash SDKs, or network on the typing path.
Release APK strips `INTERNET`. `VIBRATE` is the only extra permission (haptics).
Debug/profile manifests still include `INTERNET` for Flutter hot reload.

## Known limitations

- English only.
- Suggestions are prefix + frequency, not a language model.
- Autocorrect is conservative (distance 1, high dominance).
- No cursor-control gesture row.
- Third-party field matrix (Chrome, Messages, Notes, …) must be checked on a device.

See [V1_CHECKLIST.md](V1_CHECKLIST.md).
