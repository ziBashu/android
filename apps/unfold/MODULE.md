# Unfold — APK module contract

| Field | Value |
|-------|--------|
| Name | Unfold |
| Slug | `unfold` |
| Kind | `tool` |
| Surface | `tool` |
| applicationId | `com.zibashu.unfold` |
| Folder | `apps/unfold` |
| Auth | none |
| Guest behavior | full viewer/editor, no account |
| Backend routes | none (offline product) |
| Local storage | recents JSON in app documents; copies of opened files in cache |
| Permissions | none on release (`INTERNET` removed). Flutter debug/profile may add `INTERNET` for tooling. |
| Distribution | warehub |
| Web fallback | `/hub/warehub/unfold` |
| Blurb | Local-first file viewer. Open, read, and edit without leaving the device. |

WareHub listing: https://zibashu4.com/hub/warehub/unfold

This is an **offline product**. WareHub hosts the APK and listing only.

Tagline: **Open. Read. Edit.**

## Formats (V1)

| Kind | View | Edit | Extra |
|------|------|------|--------|
| PDF | yes | — | search, note annotation, rotate/delete/reorder pages, export |
| EPUB | yes | — | chapter view, export text |
| Markdown | yes | yes | preview, export `.md` / `.html` |
| TXT | yes | yes | export |
| HTML | yes | yes (source) | preview, export |
| DOCX | yes (text) | — | export text |
| DOC | yes (text) | — | export text |
| PNG/JPEG/WebP | yes | rotate | zoom, share, export PNG |
| ZIP | browse | — | extract, share entry |

## Hardening

- [x] No secrets in client
- [x] Min permissions
- [x] Version 1.0.0+1
- [x] `.\scripts\harden_check.ps1 -App unfold`

## Notes

Handler logic is pure Dart (`lib/core`) so tests open real constructed files without a device. Android `PdfRenderer` is used only as a raster fallback in the UI.
