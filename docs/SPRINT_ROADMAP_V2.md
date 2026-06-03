# Streak It — Sprint Roadmap V2
> Post-first-user-feedback iteration. Focused, surgical, no bloat.

## Operating Rules for this Roadmap
1. **Docs-first context** — every sprint reads MISTAKE_LOG.md + USER_FEEDBACK.md before touching code
2. **CAD-RAG approach** — context is loaded from .md files only, not from scanning all 47 dart files
3. **One sprint = one concern** — no mixing UI and logic in the same sprint
4. **After every sprint** — update MISTAKE_LOG.md with any new bugs found/fixed
5. **Zip immediately after .g.dart writes** — never gap between write and zip (see BUILD-006)
6. **No dependency upgrades mid-sprint** — lock versions, ship stable

---

## Sprint A — Notifications: Actually Make Them Work
**Files touched:** `notification_service.dart` only
**Goal:** Reminders fire reliably on Android

### Root cause (from RUNTIME-001 in MISTAKE_LOG):
- `tz.setLocalLocation(tz.UTC)` hardcodes UTC → reminders fire at wrong time
- Missing `uiLocalNotificationDateInterpretation` param in `zonedSchedule()`
- No channel creation verification before scheduling
- No permission check before scheduling attempt

### What we'll do:
1. Fix timezone: use `tz_data.initializeTimeZones()` + detect device local timezone properly
2. Add the missing `uiLocalNotificationDateInterpretation` param (confirmed fix from MISTAKE_LOG)
3. Add a "test notification" button in Settings → fires in 5 seconds → user can verify
4. Add permission check + request flow before any scheduling
5. Add `debugPrint` trail so we can see exactly what's being scheduled

### Acceptance criteria:
- Set a reminder → it fires at the correct local time
- Test button in settings → notification appears within 5 seconds
- Works across phone restarts (boot receiver already in AndroidManifest)

---

## Sprint B — Home Screen: Streak as the Hero
**Files touched:** `home_screen.dart`, `habit_card.dart`
**Goal:** First thing user sees is their streak. Progress first. Tasks second.

### What we'll do:
**New home screen structure (top to bottom):**
```
┌─────────────────────────────┐
│  Good morning, [time]       │  ← small, muted
│                             │
│  🔥 47                      │  ← MASSIVE. SpaceGrotesk 80px. Violet glow.
│  day streak                 │  ← small label under it
│                             │
│  ──────────────────────     │  ← thin divider
│                             │
│  [Progress ring] 2/3 done   │  ← medium, not hero
│                             │
│  ──────────────────────     │
│                             │
│  Today's Habits             │  ← section label
│  [Habit card]               │
│  [Habit card]               │
└─────────────────────────────┘
```

**Habit card redesign:**
- Streak number below habit name, larger font, colored
- Milestone countdown badge more prominent
- Check button right side, bigger hit area

### Acceptance criteria:
- Streak number is the visual anchor on open
- Habit list is clearly secondary to progress
- Cards feel substantial, not thin

---

## Sprint C — Typography: Real Hierarchy
**Files touched:** `app_typography.dart`, `app_theme.dart`, `home_screen.dart`, `habit_card.dart`
**Goal:** Nothing should feel "the same size". Every text element has a role.

### What we'll do:
**New type scale philosophy:**
- Hero stat (streak number): SpaceGrotesk 72–80px Bold — the attention anchor
- Screen titles: Inter 28px Bold, tight letter-spacing
- Section labels: Inter 11px SemiBold, UPPERCASE, tracked out, muted color
- Habit name: Inter 16px SemiBold
- Streak sub-label: Inter 12px Medium, colored (not muted)
- Body / description: Inter 14px Regular, muted
- Captions / timestamps: Inter 11px Regular, very muted

**The key insight:** Fonts "all one style" means we're not using weight contrast enough.
Current: everything is Medium/SemiBold at 13-16px
Required: 11px muted captions ↔ 80px hero numbers — THAT range is personality

### Acceptance criteria:
- Streak number immediately dominates visual field
- Section labels feel like they're guiding you, not shouting
- Habit name is readable but clearly not the hero

---

## Sprint D — Onboarding: Strip It Down
**Files touched:** `onboarding_screen.dart`
**Goal:** Human. Simple. Classic. No AI smell.

### What's wrong now:
- 3-page gradient carousel feels like a SaaS marketing page
- Animated entrance effects feel over-engineered
- "Build habits. Break limits." tagline feels ChatGPT-generated
- The whole thing tries too hard

### What we'll build instead:
**Single flow, 3 steps, no page swipe:**
```
Step 1: "What's your name?" (optional, personalizes greeting)
Step 2: "What's one habit you want to build?" (text input, freeform)
Step 3: "When should we remind you?" (time picker, or "no reminders")
→ Done. App opens.
```

**Design rules:**
- White/dark background only, no gradients
- No hero illustrations
- Inter font, left-aligned text
- One primary action button per step
- Back button available
- Skip all option

**The test:** Would a real indie developer building their first app make this? Yes. Does it feel like a $50M startup template? No. That's correct.

### Acceptance criteria:
- Onboarding takes < 30 seconds
- No "AI smell" — no marketing copy, no gradient overlays
- Name is used in the home screen greeting ("Good morning, Zarrar")
- First habit created during onboarding appears immediately on home

---

## Sprint E — Polish Pass
**Files touched:** misc UI files
**Goal:** Tighten everything after A-D are done

### What we'll do:
- Consistent padding/spacing audit (16/20/24dp rhythm)
- Card border-radius consistency
- Loading states (no raw CircularProgressIndicator — custom subtle pulse)
- Empty state on home screen (no habits yet) — warm, not clinical
- Color usage audit — are we using the accent color deliberately or randomly?

---

## Sprint F — Build & Ship
**Goal:** Clean APK after all fixes

### What we'll do:
1. Write all .g.dart files
2. Zip immediately
3. User runs: `flutter pub get` → `flutter build apk --release`
4. Transfer APK → install → verify notifications work in the wild

---

## Context Loading Protocol (CAD-RAG)
Before any coding sprint starts, load ONLY these files:
```
docs/MISTAKE_LOG.md        → what broke before and why
docs/USER_FEEDBACK.md      → what the user actually needs
docs/SPRINT_ROADMAP_V2.md  → what this sprint does
```
Then load ONLY the specific dart files being touched in that sprint.
Never load all 47 files at once. Never.

---

## Mistake Log Update Protocol
After every sprint, add to MISTAKE_LOG.md:
```markdown
## [SPRINT-X-NNN] Short title
- **Error:** what the error message said
- **Cause:** why it happened
- **Fix:** exact change made
```

---

## Current Status
| Sprint | Status |
|---|---|
| A — Notifications | 🔲 Planned |
| B — Home Hero | 🔲 Planned |
| C — Typography | 🔲 Planned |
| D — Onboarding | 🔲 Planned |
| E — Polish | 🔲 Planned |
| F — Build | 🔲 Planned |
