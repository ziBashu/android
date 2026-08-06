# APK module contract

Mirror of the web [module contract](file:///C:/Users/syxMa/ziBashu/zibashu/docs/module-contract.md) for mobile apps in this monorepo.

Fill one of these before shipping a new APK.

## Required summary

| Field | Example |
|-------|---------|
| Module / app name | Seru |
| Slug | `seru` |
| Owner folder | `apps/seru` |
| applicationId | `com.zibashu.seru` |
| Primary surface | messaging / hub / lab / studio / tool |
| Auth requirement | none / optional / required |
| Guest behavior | browse-only / blocked |
| Backend routes used | `/api/mobile/login`, … |
| External services | Soketi, … |
| Local storage | messages in on-device DB |
| Cleanup needs | TTL for local messages |
| Rate-limit awareness | yes / n/a |
| Known security risks | token theft if device unlocked |
| Warehub listing | name, blurb, icon, minSdk |

## Rules

### Identity

- Distinct product name in the launcher.
- About / footer always includes **from ziBashu**.
- Link to `https://zibashu4.com` and privacy/terms when relevant.

### Storage

State whether data is:

- on-device only
- temporary server
- permanent server
- published content

Prefer on-device for private messaging (Seru model).

### Auth

- Use `zibashu_auth` only — no bespoke token files.
- Never embed API keys.

### Networking

- Base URL from `zibashu_core` `ApiConfig`.
- Support demo/offline mode when the API is unreachable.

### Versioning

- Bump `version` in app `pubspec.yaml` and Android `versionCode` every warehub upload.
- Artifact: `dist/<slug>-v<versionName>.apk`

### Cleanup

Any local cache must declare max size and optional purge path in About → Storage.
