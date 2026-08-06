# Architecture — ziBashu Android monorepo

## Intent

Ship **many distinct APKs** that serve the ziBashu system. Each app is its own product, clearly branded **from ziBashu**, and packaged for **warehub** sideload distribution.

The production Play WebView shell (`com.zibashu.app` in `android-ziBashu`) remains separate.

## Layout

```text
packages/          Shared Dart libraries (path deps)
  zibashu_core/    API config, HTTP, catalog models
  zibashu_ui/      Brand theme + chrome widgets
  zibashu_auth/    Sanctum token storage + login client

apps/              One Flutter application = one APK
  zibashu_hub/     Family catalog / launcher
  seru/            Messaging specialty sample

templates/         Scaffold for new apps
scripts/           env, bootstrap, new_app, build_apk
docs/              Contracts and runbooks
dist/              Built APKs + warehub metadata (gitignored)
```

## Rules

1. **One product per app module.** Do not turn hub into a mega-app that embeds every tool.
2. **Shared code lives in packages/** — themes, auth, API base URL, warehub metadata types.
3. **Package IDs** always `com.zibashu.<slug>`.
4. **No provider secrets** in clients. Keys stay on Laravel.
5. **Backend is optional for UI work** — demo mode keeps apps runnable offline.
6. New apps are added via `scripts/new_app.ps1` and must fill `docs/apk-module-contract.md`.

## Dependency direction

```text
apps/*  →  zibashu_auth → zibashu_core
        →  zibashu_ui   → zibashu_core
```

Apps never depend on each other.

## Backend relationship

| Concern | Owner |
|---------|--------|
| Accounts, Sanctum tokens | Laravel (`ziBashu/zibashu`) |
| Seru realtime | Soketi + Echo (site); mobile MVP may lag |
| Tool logic (Lumen, Comfy, …) | Prefer deep-link to web or dedicated APIs later |
| APK hosting | ziBashu warehub (future); this repo only builds artifacts |

## Adding a third APK

1. Run `.\scripts\new_app.ps1 -Slug lumen -Name "Lumen" -Surface lab`
2. Implement UI under `apps/lumen`
3. Register entry in hub catalog (`zibashu_core` family catalog)
4. `.\scripts\build_apk.ps1 -App lumen`
5. Upload `dist/lumen-v*.apk` + JSON to warehub
