# MorphOS product vision

**Source of truth for product design.** Implementation tracks this document.

**Philosophy**

> Android gives users apps.  
> MorphOS gives users environments.

MorphOS is a **personal adaptive environment layer** that sits between the user and the phone. It does not need to replace Android immediately — it changes how users experience Android.

---

## Five fundamentals

| Question | Feature | Status (0.7) |
|----------|---------|--------------|
| How does my phone look? | Customization | **Shipped** — themes, wallpapers, icons, layouts, rename |
| How does my phone behave? | Modes / Morphs | **Shipped** — full environment packs per profile |
| How does my phone change shape? | Orientation engine | **Shipped** — profile orientation + optional system morph |
| How does my phone adapt? | Context system | **Shipped** — per-app, category, time, charge, context IF/THEN, intelligence modes |
| How do I create my own phone? | Morph creator | **Shipped** — Creator + Store + morphpack share |

---

## Twelve product questions

### 1. Identity — What is MorphOS?

**Answer:** Personal adaptive environment layer (not “just a launcher”, not a full custom ROM yet).

| Area | Status |
|------|--------|
| HOME + LAUNCHER role | Shipped |
| Morph profiles as environments | Shipped |
| Custom ROM / system image | Roadmap only |

### 2. Personalization — “This is my phone”

| Capability | Status |
|------------|--------|
| Change wallpaper | Shipped (engine gradients) |
| Change icons | Shipped (styles, scale, labels) |
| Rename apps | Shipped (long-press) |
| Redesign home | Shipped (layouts, dock, home ids) |
| Create themes | Shipped (theme engine + packs) |
| Change animations | Partial / next |
| Change sounds | Planned |
| Interaction style | Partial (gestures, quiet, large targets) |

### 3. Shape — Is a phone always a phone?

**Answer: No.**

| Shape | Morph | Status |
|-------|-------|--------|
| Pocket device | Pocket Morph | Shipped |
| Gaming console | Gaming Morph | Shipped |
| Mini computer | Desktop Morph | Shipped |
| Book reader | Reading Morph | Shipped |
| Dashboard | Dashboard Morph (car) | Shipped |
| Work / Relax / Study / Travel spaces | Environments | Shipped |

### 4. Orientation — Why rotate?

| Capability | Status |
|------------|--------|
| Profile → orientation | Shipped |
| System-wide orientation (a11y) | Shipped (opt-in) |
| Ask: “Switch to desktop?” | Shipped (Ask intelligence) |
| Accessory-aware (keyboard / external) | Partial (rules + bridge) |

### 5. Environments — One home for every moment?

| Space | Dock focus | Status |
|-------|------------|--------|
| Work | Mail, calendar, notes | Shipped |
| Relax | Music, cinema, gallery | Shipped |
| Study | Books, dictionary, timer | Shipped |
| Travel | Map, translate, camera, currency | Shipped |

### 6. Intelligence — Manual everything?

| Mode | Behavior | Status |
|------|----------|--------|
| Beginner · Auto | Silent context morphs | Shipped |
| Ask first | Propose then confirm | Shipped |
| Advanced · Rules | Explicit IF/THEN + per-app only | Shipped |

### 7. Interaction — Beyond icons

| Channel | Status |
|---------|--------|
| Control Center / Morph Hub | Shipped |
| QS tile / boot restore | Shipped |
| Gesture cycle morph | Shipped |
| Voice / edge / motion | Planned |

### 8. Visual world

| Direction | Status |
|-----------|--------|
| Icons + widgets style | Shipped (grid/cards) |
| Spatial layout | Shipped |
| Desktop multi-window shell | Shipped |
| Object-based activities (“Play music”) | Planned |

### 9. Creation

| Capability | Status |
|------------|--------|
| Morph Creator | Shipped |
| Morph Store (offline) | Shipped |
| Share morphpack JSON | Shipped |
| Online community | Later |

### 10. Hardware control

| Control | Status |
|---------|--------|
| Screen orientation | Shipped |
| Immersive chrome / keep-awake | Shipped |
| Brightness / refresh / audio / fold | Planned |

### 11. Social — Why share a Morph?

Because a Morph changes **behavior** (layout, apps, rules, orientation), not only color.

### 12. Ultimate question

> MorphOS knows how I use my device and transforms itself into the tool I need.

---

## Non-goals (current APK track)

- Full custom Android ROM / framework fork (long-term platform track)
- Replacing Play services
- Competing only on icon skins without morph intelligence

## Related

- `apps/morphos/MODULE.md` — module contract & version
- `docs/morphos-reference-notes.md` — Launcher OS / Rotation references
