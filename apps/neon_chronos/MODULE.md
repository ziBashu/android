# Neon Chronos — Temporal OS

| Field | Value |
|-------|--------|
| Name | Neon Chronos |
| Version | **3.0.1+4** (UI polish final) |
| applicationId | `com.zibashu.neon_chronos` |
| Identity | Futuristic personal **time environment** (no AI) |

## Evolution

| Gen | Role |
|-----|------|
| v1 | Futuristic clock |
| v2 | Futuristic time tool |
| v3 | Futuristic time environment / Temporal OS |

## v3 features

- Chronos Home — rearrangeable cockpit modules
- Clock faces — Digital HUD, Orbital, Quantum, Custom
- Clock Builder — shape/glow/particles/anim + share codes `NC3:…`
- Theme Archive — Cyber City, Deep Space, Retro Terminal, Minimal White, Industrial
- Time Journey — day landscape viz
- Focus / Pomodoro + manual Time Map stats
- Wake Sequence — phased glow → sound → vibration
- Ambient Mode — desk clock; charging snackbar
- Home widget (from v2)

## Architecture

```
lib/
  app/
  core/engine clock_engine theme_engine storage sound widget
  features/
    home/ clock/ clock_faces/ themes/ alarm/ focus/
    statistics/ ambient/ viz/ more/ timer/ world_clock/ …
```

## Hardening

- [x] Offline-first, no AI, no cloud
- [x] Version 3.0.0+3
- [x] analyze / test / emulator smoke (`screenshots/neon_chronos-v3-home.png`)
