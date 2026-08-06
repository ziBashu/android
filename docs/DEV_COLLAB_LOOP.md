# Mature dev loop: you + agent + emulator

You do **not** need to wire the agent into Android Studio’s UI APIs.
Android Studio is for **you** (emulator, optional visual debug).
The agent works from: **source files + terminal + screenshots + your words**.

```text
You (Android Studio / phone / eyes)
   |  start emulator, describe bugs, paste errors
   v
Agent
   |  edits Dart, runs flutter/analyze/test
   |  adb install / flutter run
   |  screenshots/latest.png
   v
Emulator (visible app)
   |
   +--> you look  OR  agent reads screenshot
   |
   v
You write result in DEV_FEEDBACK.md  (or chat)
   |
   v
Agent fixes next pass
```

---

## What the agent can “see”

| Source | Can agent use it? | How |
|--------|-------------------|-----|
| Project files | Yes | read/edit `apps/**`, `packages/**` |
| Build errors | Yes | `flutter run`, `flutter analyze` terminal output |
| Emulator screen | Yes (indirect) | `.\scripts\screenshot.ps1` → PNG in `screenshots/` |
| Your words | Yes | chat, or `DEV_FEEDBACK.md` |
| Android Studio window | No | agent cannot see Studio chrome, inspectors, or mouse |
| Live hot-reload `r` key | Partial | agent runs CLI; you can hot-reload in a terminal you keep open |

---

## Recommended mature workflow (day to day)

### A. You keep the emulator running

Android Studio → Device Manager → start AVD (e.g. Medium Phone).  
Leave it running.

### B. Start a coding session

```powershell
cd C:\Users\syxMa\ANDROID
. .\scripts\env.ps1
flutter devices
```

Tell the agent (chat or paste):

```text
Follow docs/NEXT_AGENT_STANDARD_WORKFLOW.md and docs/DEV_COLLAB_LOOP.md.
Target app: apps/seru (or hub / new slug).
Emulator is running.
After each meaningful UI change: rebuild/run if needed, screenshot, stop.
I will write results in DEV_FEEDBACK.md (or reply in chat).
```

### C. Edit loop (one feature at a time)

1. **Agent** changes code for a small goal.
2. **Agent** verifies:
   ```powershell
   cd apps\<slug>
   flutter analyze
   flutter run -d emulator-5554   # or install release APK
   ```
   From repo root:
   ```powershell
   .\scripts\screenshot.ps1 -Out screenshots\latest.png
   ```
3. **You** look at the emulator **or** open `screenshots\latest.png`.
4. **You** report result (pick one):
   - Chat: “Login button too low / crash on send / looks good”
   - Or edit **`DEV_FEEDBACK.md`** (template below) and say “read DEV_FEEDBACK”
5. **Agent** reads feedback → next edit.

Do **not** batch ten UI changes before feedback. Short cycles win.

### D. When you edit in Android Studio yourself

That is fine. After **your** edit:

1. Save files.
2. Either:
   - tell agent: “I changed X in Android Studio, pull latest files and screenshot”, or
   - hot-reload if *you* have `flutter run` open (`r`).
3. Write what you see in chat / `DEV_FEEDBACK.md`.
4. Agent continues from disk (always re-read files; do not assume Studio state).

Agent and Studio both edit the **same folder**. Avoid simultaneous conflicting edits on the same file without saving.

### E. Ship pass (when a feature is good)

```powershell
.\scripts\harden_check.ps1 -App <slug>
.\scripts\build_apk.ps1 -App <slug>
# commit + push per NEXT_AGENT_STANDARD_WORKFLOW.md
```

---

## `DEV_FEEDBACK.md` (you fill this)

Path: repo root `DEV_FEEDBACK.md` (gitignored — local only).

After each agent edit, update it:

```markdown
## Status
- App: seru
- Goal: login screen spacing
- Result: FAIL | PASS | PARTIAL

## What I see
- ...

## Errors (paste)
```
...
```

## Next ask
- ...
```

Then tell the agent: **“Read DEV_FEEDBACK.md and fix.”**

That is the simplest “agent can ready from dev screen + my result after each edit” channel.

---

## Two modes (choose)

### Mode 1 — Agent drives CLI (best for AI)

- Agent runs `flutter run` / install / screenshot.
- You only judge and write feedback.
- Best when agent has shell access (this environment).

### Mode 2 — You drive Studio/CLI (best for you)

- You run app in Studio or `flutter run`.
- Agent only edits code.
- After each change you: hot reload → look → paste result to agent.
- Best when you want full control of the emulator.

**Hybrid (recommended):** Agent edits + screenshot; you confirm in Studio eyes + short chat note.

---

## What is *not* natural / not needed

- Plugin that “connects Claude into Android Studio”
- Agent controlling Studio mouse/Layout Inspector
- Expecting agent to see your physical screen without a screenshot file

Flutter CLI + adb + feedback file **is** the mature bridge.

---

## Quick commands cheat sheet

| Action | Command |
|--------|---------|
| Env | `. .\scripts\env.ps1` |
| Devices | `flutter devices` |
| Run app | `cd apps\<slug>; flutter run -d emulator-5554` |
| Stop app | `adb shell am force-stop com.zibashu.<slug>` |
| Screenshot | `.\scripts\screenshot.ps1 -Out screenshots\latest.png` |
| Analyze | `flutter analyze` |
| Harden | `.\scripts\harden_check.ps1 -App <slug>` |
| APK | `.\scripts\build_apk.ps1 -App <slug>` |

---

## Example dialogue

**You:** Emulator is up. Improve Seru login title spacing.  
**Agent:** edits → run → screenshot → “done, see screenshots/latest.png”  
**You:** (looks) Title still too close to top. Updated DEV_FEEDBACK.  
**Agent:** reads DEV_FEEDBACK → adjusts padding → screenshot again  
**You:** PASS. Commit.  
**Agent:** harden → commit (push if you asked)

That loop is the mature setup.
