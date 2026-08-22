# KEYLINE V1 feature checklist

## Build

- [x] Project builds
- [x] Debug APK installs — device-dependent, see verification log
- [x] Release APK generated — see `dist/keyline-v1.0.0.apk`
- [x] App launches — emulator screenshot `screenshots/keyline-setup.png`
- [x] Keyboard appears in Android IME settings — `adb shell ime list -a` lists `com.zibashu.keyline/.ime.KeylineImeService`

## IME

- [x] InputMethodService + BIND_INPUT_METHOD + method XML declared
- [x] Insert / backspace / space / enter / selection delete / cursor insert (unit-tested)
- [x] Shift / Caps Lock / 123 layer (unit-tested)
- [x] Long-press table (unit-tested)
- [x] Hide commits composing (unit-tested)
- [x] Keyboard opens in Chrome search (emulator screenshot `screenshots/keyline-qwerty.png`)
- [ ] Keyboard closes / app-switch survival — NOT VERIFIED

## Text fields (device)

Mark NOT VERIFIED unless driven on a device:

- [ ] Notes-style field
- [ ] Browser search field
- [ ] Web form
- [ ] Messaging field
- [ ] Password field (unit-tested suppression; on-device behavior NOT VERIFIED)
- [ ] Multiline field
- [ ] Search field
- [ ] Long text field

## UI

- [x] Light / dark / system tokens
- [x] Height and key-spacing settings
- [x] Proportional layout, no overlap at 720 / 1080 / 1440 px (unit-tested)
- [x] Long-press popup clamped to edges (unit-tested)
- [ ] Small/large physical phones — NOT VERIFIED
- [x] Portrait emulator screenshot of QWERTY (`screenshots/keyline-qwerty.png`)

## Privacy

- [x] No analytics / ads / cloud / accounts in source
- [x] INTERNET removed from main/release manifest
- [x] App states that typing is not sent to a server
