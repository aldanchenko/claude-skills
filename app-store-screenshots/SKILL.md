---
name: app-store-screenshots
description: Build localized App Store and Google Play screenshot sets from real device captures composed with a programmatic (Pillow) compositor — never AI-redrawn UI. Use when the user wants App Store / Google Play screenshots / marketing images / иллюстрации или скриншоты для App Store, wants them localized, needs an iPad or Play set, a Play feature graphic, or A/B test variants.
---

# App Store screenshots from real captures

Produce store-ready, localized screenshot sets: real app screenshots framed in a
drawn device mockup, with font-rendered captions. The screen content is pixel-real,
so UI text can never be mangled; captions live in per-locale string tables, so each
additional language is one more table.

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
     Seed once and idempotently, so relaunching per slide doesn't stack data.
   - Navigation without taps: in screenshot mode, read `"<locale> <slide>"` from
     `File('${Directory.systemTemp.path}/screenshot')` at startup, select that
     language, open the slide's screen (tab, sheet, scroll position) and skip
     onboarding. The capture script writes the file before each launch.
   - Other stacks: same idea — env flag + seeding at startup + a slide switch.
   Comment loudly that release builds must never ship with the flag on.

2. **Shoot real captures** on simulators whose screens match the slots (table
   below). Run from the terminal — IDE run buttons drop `--dart-define`s.
   - Automated (preferred): copy `capture_ios_template.sh` into the project, fill
     its CONFIG and run it once per simulator. It builds once, sets the 9:41 status
     bar, launches per locale × slide with `-AppleLanguages`, shoots into
     `captures/<locale>/<device>/NN.png` and warns when two locales came out
     identical (the locale switch failed).
   - By hand: `xcrun simctl status_bar booted override --time 9:41 --batteryState
     charged --batteryLevel 100 --wifiBars 3 --cellularBars 4` first, then
     `xcrun simctl io booted screenshot NN.png` per slide, `status_bar booted clear`
     after. Dark slide: `xcrun simctl ui booted appearance dark`.
   - Android: an emulator matching a Pixel (1080×2400), one build per locale, the
     status bar in demo mode (`adb shell settings put global sysui_demo_allowed 1`,
     then `am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0930`,
     `… battery -e level 100 -e plugged false`, `… notifications -e visible false`),
     `adb exec-out screencap -p > NN.png`, dark via `adb shell cmd uimode night yes`.
     Coordinate taps break with every layout change — prefer the slide switch.
     `input keyevent 4` on a root tab quits the app.
   Don't switch apps in the simulator: the "◀ Back to <app>" breadcrumb replaces
   the status-bar clock and ruins every frame.

3. **Triage the captures** before composing. Rate each Great / Usable / Retake.
   Retake: empty states, sparse lists, debug UI or banners, a sheet left over from
   the previous step, keyboard up without purpose, settings / login / onboarding
   screens as a slide. Only Great and Usable go on.

4. **Compositor.** Copy `compositor_template.py` from this skill's directory into
   the project (e.g. `tools/generate_app_store_screenshots.py`), then fill the
   `PROJECT CONFIG` block: accent color, logo letter/wordmark, slides, per-locale
   captions, Play feature-graphic lines, store locale codes. Needs Pillow
   (`python3 -m venv .venv && .venv/bin/pip install Pillow` if the system python
   lacks it). Then:
   - everything: `python tools/generate_app_store_screenshots.py --all --sheet --src captures`
   - one set: `… --locale ru --device ipad-13 --src captures/ru/ipad-13`
   - Play banner: `… --all --feature-graphic`
   The run stops on a headline that doesn't fit at the minimum size, a subtitle
   over two lines, a device over the caption, a glyph the font lacks, a missing
   caption, low caption contrast, or output the store would reject (size, alpha,
   count, stray files). Fix the copy or the config, never by loosening the check.

5. **Verify with your own eyes.** Open `app_store_screenshots/_review/<locale>-<slot>.png`
   first: all slides in a row plus a row at search-result size (~160 px wide). If a
   headline is unreadable in the small row, it won't be read in search. Then read
   every generated PNG: no side clipping of the device frame mid-edge (bottom bleed
   is intentional on "hero" slides), captions wrap sanely in every locale, the dark
   slide contrasts with its canvas, staged numbers look right. Fix, regenerate,
   re-look.

6. **Deliver** into `app_store_screenshots/<locale>/<slot>/NN-slug.png`. File
   numbering = upload order. `--fastlane` also copies the sets where fastlane
   deliver and supply look for them (`fastlane/screenshots/<code>/`,
   `fastlane/metadata/android/<code>/images/`), mapped by `ASC_LOCALES` /
   `PLAY_LOCALES`. Upload, to App Store Connect or Play Console, only when the user
   asks for it.

## Store slot requirements (portrait)

Re-check before shooting — the required iPhone size has changed before:
[App Store specs](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications),
[Play specs](https://support.google.com/googleplay/android-developer/answer/9866151).

| Slot (`--device`) | Accepted sizes | Simulator to shoot on |
|---|---|---|
| iPhone 6.3" (`iphone-6.3`) — **required** | 1206×2622 or 1179×2556 | iPhone 17 / 16 Pro |
| iPhone 6.9" (`iphone-6.9`) — optional | 1320×2868, 1290×2796 or 1260×2736 | iPhone 16 Pro Max (a 6.3" capture scales into it) |
| iPad 13" (`ipad-13`) — required if the app runs on iPad | 2064×2752 or 2048×2732 | iPad Pro 13-inch (M4) |
| Play phone (`android`) | up to 8; 320–3840 px, long side ≤ 2× short; canvas 1440×2560 (9:16) | Pixel-class emulator, 1080×2400 |
| Play feature graphic | 1024×500, required | — (`--feature-graphic`) |

Up to 10 per App Store slot. Play needs at least 2 screenshots overall, and only
sets of 4+ in 9:16 at 1080×1920 or more are used in its recommendations — the
compositor warns otherwise. It accepts any capture within ~0.02 of the slot's
aspect and scales it into the frame. Output is RGB without alpha.

Optional, iOS 27+: the product page header art — 3840×1646 (21:9, JPEG or PNG),
or one universal 5244×2950 PNG for both the header and search results
([creative assets specs](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications/)).
Keep text and key art inside the safe area of Apple's template (x 1097–2743,
y 493–1154 on 3840×1646): iPhones show only a middle part (a developer forum
report describes the sides cut off). It is a wide illustration, not a
device frame, so render it separately (HTML in headless Chrome or Pillow) and
check it with the safe area drawn on.

## Slide set that works (7 slides)

1. Home/progress screen with logo chip + wordmark and the core value headline
2. Content depth (theory/detail screen)
3. Interactive moment with visible positive feedback ("Correct!") — `float` layout
4. Browse/catalog screen
5. The differentiator feature (e.g. conjugation card) — `float` layout
6. Retention feature (mistakes/review), pre-filled by staged data
7. Dark mode (classic closing slide) — `theme="dark"` gives it a dark canvas

Max 10 slides; first 3 dominate search-result impressions. Captions:
- benefit-first, 2 lines, the punch line in accent color, one idea per headline
  (an "and" means two slides);
- don't repeat the same keyword across consecutive headlines; put the app's #1
  search query (see the `aso` skill) in the first captions;
- translate the idea, not the words; German and French run 20–35% longer —
  shorten the copy before reaching for `head_scale`;
- a native speaker reads every hero headline before upload.

A/B tests (App Store product page optimization, Play store listing experiments):
add `"01@b"` captions and run with `--variant b`; it writes `<slot>@b/`. Test the
first slide first and one idea per treatment.

## Pitfalls checklist (each one bit us once)

- [ ] Staged mode actually on (locks gone, streak up) — else reshoot
- [ ] Status bar overridden to 9:41 / full battery; no "◀ Back to app" breadcrumb
- [ ] Captures shot per locale (UI language must match the storefront); no two
      locales identical
- [ ] Required iPhone slot is 6.3"; aspect/size matches the slot table
- [ ] Compositor run ended without ✗ lines; `·` lines (device moved down) looked at
- [ ] Review sheet and every generated frame visually checked before commit
