# KEYLINE — APK module contract

| Field | Value |
|-------|--------|
| Name | KEYLINE |
| Slug | `keyline` |
| Kind | `tool` |
| Surface | `tool` |
| applicationId | `com.zibashu.keyline` |
| Folder | `apps/keyline` |
| Auth | none |
| Guest behavior | full keyboard, no account |
| Backend routes | none (offline product) |
| Local storage | SharedPreferences settings + bundled English dictionary |
| Permissions | `VIBRATE` only on release; debug/profile may add `INTERNET` for Flutter tooling |
| Distribution | warehub |
| Web fallback | `/hub/warehub/keyline` |
| Blurb | Offline-first English keyboard. Typing stays on the device. |

WareHub listing: https://zibashu4.com/hub/warehub/keyline

This is an **offline product**. WareHub hosts the APK and listing only. There is no IME backend.

## Hardening

- [x] No secrets in client
- [x] Min permissions
- [x] Version 1.0.0+1
- [x] `.\scripts\harden_check.ps1 -App keyline`
- [x] Emulator smoke + screenshot (`screenshots/keyline-setup.png`, `screenshots/keyline-qwerty.png`)

## Notes

Native `InputMethodService` is the keyboard. Flutter is the setup/privacy activity only.
See `docs/IME.md`.
