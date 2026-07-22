---
name: app-store-screenshots
description: Build localized App Store screenshot sets from real device captures composed with a programmatic (Pillow) compositor — never AI-redrawn UI. Use when the user wants App Store screenshots / marketing images / иллюстрации или скриншоты для App Store, wants them localized, or needs an iPad set.
---

# App Store screenshots from real captures

Produce store-ready, localized screenshot sets: real app screenshots framed in a
drawn device mockup, with font-rendered captions. The screen content is pixel-real,
so UI text can never be mangled; captions live in per-locale string tables, so each
additional language is one CLI flag.

**Never** generate or upscale app UI with image-AI models: they redraw text and
corrupt it (observed: "casă" became "casa", dictionary sort order scrambled,
"pronunciation" became "prenunciation" after an AI upscale). In a content app the
target audience notices immediately. AI imagery is acceptable only for decorative
props that contain no text — and only pasted programmatically, never covering UI.

## Workflow

1. **Staged demo data.** Marketing captures must look lived-in: healthy streak,
   progress, no lock icons, no empty states, one-time hints suppressed. Add a
   compile-time screenshot mode to the app:
   - Flutter: `const kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE')`;
     when true, seed local storage in `main()` BEFORE providers/stores load, and
     short-circuit revenue/IAP init so the store can't overwrite the staged unlock.
     Optional `SCREENSHOT_LOCALE` define to preselect language and skip onboarding.
   - Other stacks: same idea — env flag + seeding at startup.
   Comment loudly that release builds must never ship with the flag on.

2. **Shoot real captures** on simulators whose screens match the required slots
   (see table). Run from the terminal — IDE run buttons drop `--dart-define`s.
   Verify staged data actually applied (streak visible, no locks) before shooting.
   Capture: `xcrun simctl io booted screenshot NN.png`, one file per slide,
   numbered `01.png…07.png`. Don't switch apps in the simulator: the
   "◀ Back to <app>" breadcrumb replaces the status-bar clock and ruins every frame.

3. **Compositor.** Copy `compositor_template.py` from this skill's directory into
   the project (e.g. `tools/generate_app_store_screenshots.py`), then fill the
   `PROJECT CONFIG` block: accent color, logo letter/wordmark, slides, per-locale
   captions. Needs Pillow (`python3 -m venv .venv && .venv/bin/pip install Pillow`
   if the system python lacks it). Run per locale/device:
   `python tools/generate_app_store_screenshots.py --locale ru --src <captures> [--device ipad]`

4. **Verify with your own eyes.** Read every generated PNG and check: no side
   clipping of the device frame mid-edge (bottom bleed is intentional on "hero"
   slides), captions fit and wrap sanely in every locale, dark-mode slide contrasts
   with the background, staged numbers look right. Fix, regenerate, re-look.

5. **Deliver** into `app_store_screenshots/<locale>/<slot>/NN-slug.png` and commit.
   File numbering = upload order in App Store Connect.

## Store slot requirements (portrait)

| Slot | Accepted sizes | Simulator to shoot on |
|---|---|---|
| iPhone 6.9" (required) | 1320×2868 or 1290×2796 | iPhone 16 Pro Max (or any 1206×2622-class device scaled by the compositor) |
| iPad 13" (required if iPad supported) | 2064×2752 or 2048×2732 | iPad Pro 13-inch (M4) |

The compositor accepts any capture within ~0.02 of the slot's aspect and scales it
into the frame, so a 1206×2622 (iPhone 17 sim) capture is fine for the 6.9" slot.

## Slide set that works (7 slides)

1. Home/progress screen with logo chip + wordmark and the core value headline
2. Content depth (theory/detail screen)
3. Interactive moment with visible positive feedback ("Correct!") — `float` layout
4. Browse/catalog screen
5. The differentiator feature (e.g. conjugation card) — `float` layout
6. Retention feature (mistakes/review), pre-filled by staged data
7. Dark mode (classic closing slide)

Max 10 slides; first 3 dominate search-result impressions. Captions: benefit-first,
2 lines, the punch line in accent color; don't repeat the same keyword across
consecutive headlines.

## Pitfalls checklist (each one bit us once)

- [ ] Staged mode actually on (locks gone, streak up) — else reshoot
- [ ] No "◀ Back to app" breadcrumb in any status bar
- [ ] Captures shot per locale (UI language must match the storefront)
- [ ] Aspect/size matches the slot table
- [ ] Every generated frame visually reviewed before commit
