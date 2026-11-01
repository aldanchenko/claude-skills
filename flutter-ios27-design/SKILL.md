---
name: flutter-ios27-design
description: Build or restyle Flutter apps in the iOS 26/27 Liquid Glass look — CupertinoApp + liquid_glass_widgets, glass only on the controls layer, opaque grouped content, Apple's iOS 26 colors and SF Pro type ramp, a tinted background wash, the hard scroll edge, continuous corners — with ready Dart foundation files to copy. Use whenever the user wants a Flutter app (new or existing, including Material apps) to look like modern iOS, iOS 26/27, Liquid Glass or "как в нативных iOS-приложениях", asks for a redesign / редизайн / красивый дизайн в стиле iOS / жидкое стекло, or adds screens to an app that already uses liquid_glass_widgets, even without naming the package.
---

# iOS 27 design for Flutter apps

The look of a shipped iPhone and Mac app, packaged to repeat in other apps. It is a design
system on top of the `liquid_glass_widgets` package. The package ships its own agent guide for its API (see "Package API"); this skill covers what that guide
doesn't: the look to aim for, the exact numbers, and foundation code that already gets them
right. Tested with liquid_glass_widgets 1.15.0–1.16.0 on Flutter 3.41+.

## Why it reads as iOS and not as "Flutter Cupertino"

Keep these in mind on every screen; they explain the rules below.

1. **Real Liquid Glass.** Flutter's own Cupertino bars are iOS 18 blur. liquid_glass_widgets
   renders refraction, frost, a lit rim and spring "jelly" motion with shaders.
2. **The iOS 27 material at standard quality.** `AppTheme.glass` applies iOS 27's settings
   (denser frost, a rim instead of a drop shadow) to every glass widget; the bars get premium
   rendering from `GlassScaffold` anyway.
3. **Glass only on the controls layer.** Bars, tab bar, buttons, switches, sheets, dialogs.
   Content (cards, lists, charts, text) stays opaque: `secondarySystemGroupedBackground` cards on
   `systemGroupedBackground`. That is what iOS does; glass content is hard to read and turns a
   screen into a glass demo.
4. **Something for the glass to refract.** `AppBackground` lays two soft radial washes over the
   grouped background, tinted by app state and cross-faded. On flat white, glass looks like
   nothing.
5. **Apple's exact numbers.** The iOS 26 tints (Flutter's `CupertinoColors.systemX` are still
   the old ones), Apple's text ramp with SF Pro tracking, tabular figures, 44 pt targets,
   one-pixel hairlines, 16 pt gutters, 26 pt continuous corners.
6. **iOS 27 navigation details.** Large titles that collapse into the bar, a floating capsule
   tab bar, the hard scroll edge, round ✕ / ✓ sheet headers, tinted prominent glass buttons.
7. **Native patterns, not invented ones.** Inset grouped sections with UPPERCASE footnote
   headers and explanatory footers, settings tiles, Fitness-style rings, Health-style charts.
   For any screen, ask what Apple's own app does on the same kind of screen.
8. **Restraint.** One accent color; other tints mean status. One hero per screen. No shadows,
   borders or gradients on content.

## Workflow

Building or restyling: steps 1–5. Asked only to review or audit: "Review without changing"
below.

### 1. Read the project

- `pubspec.yaml` / `pubspec.lock`: liquid_glass_widgets and its version, state management,
  routing (go_router?), localization.
- Root widget: `MaterialApp` or `CupertinoApp`; how much Material is there
  (`grep -rln "package:flutter/material.dart" lib | wc -l`).
- Platforms (`android/`, `windows/`, `macos/` folders) and which of them ship.
- The iOS deployment target (`IPHONEOS_DEPLOYMENT_TARGET`, `ios/Podfile`). The package draws the
  glass itself, so users on iOS 18 and older also get iOS 27 bars inside an older system. Fine
  for most apps; tell the user when the target is below 26.
- If the app already has these foundation files (`lib/core/theme/app_text.dart`, …), extend
  them; never add a second copy.

### 2. Foundation

1. `flutter pub add liquid_glass_widgets` — 1.15 or newer (needs Flutter ≥ 3.41). On 1.14 use
   `references/legacy-1.14.md`. 2.0 removes `GlassCard` and makes `solid` the default surface
   of list sections: before moving to it, check the rules here against its changelog.
2. Copy the templates from this skill's `assets/core/` into `lib/core/`
   (`cp -R <skill-dir>/assets/core/. lib/core/`). Check for name clashes first and merge
   instead of overwriting.

   | File | What it gives |
   |---|---|
   | `theme/app_colors.dart` | iOS 26/27 tints with their Increase Contrast variants, `accent`, `yellowText` |
   | `theme/app_text.dart` | Apple's text ramp with SF Pro tracking, `.tabular` |
   | `theme/app_theme.dart` | `CupertinoThemeData` and the iOS 27 glass material |
   | `widgets/app_shell.dart` | `AppShell` + `ShellTab` (tab root with glass bars, large titles, scroll edge, status-bar tap to top), `TabPage` (a tab's scrolling page) |
   | `widgets/app_background.dart` | the tinted wash behind the glass |
   | `widgets/app_layout.dart` | gutters, max content width, insets for the floating bars |
   | `widgets/content_card.dart` | `ContentCard` (opaque, continuous corners), `CapsuleProgress` |
   | `widgets/grouped_section.dart` | `GroupedSection`, `GroupedRow`, `RowIcon` (inset grouped lists) |
   | `widgets/glass_pill_button.dart` | capsule glass button, tinted = prominent; a label too long shrinks to fit, `widthFor` sizes a pair to its longest label |
   | `widgets/app_sheet.dart` | `showAppSheet` (dense glass sheet), `SheetHeader` (✕ title ✓) |
   | `widgets/scroll_edge_bar.dart` | iOS 27 hard scroll edge |
   | `widgets/progress_ring.dart` | Fitness-style ring that laps past 100 %, with a spoken summary |

   The templates already follow Reduce Motion, Increase Contrast and accessibility text sizes;
   keep that when changing them.

3. Set `AppColors.accent` to the brand color if the app has one (blue otherwise).
4. Bootstrap: `await LiquidGlassWidgets.initialize()` in `main()`,
   `LiquidGlassWidgets.wrap(theme: AppTheme.glass, child: …)` above the app,
   `CupertinoApp(theme: AppTheme.cupertino)` (`references/screens.md` §1).

### 3. Structure

- Tab app: `AppShell` with one `ShellTab` per tab; each tab's page is a `TabPage`.
- Single-stack app or pushed screens: `GlassScaffold` + `GlassAppBar.pinned`
  (`references/screens.md` §8).
- Existing Material app: follow `references/migrate-material.md` (order of work, widget
  mapping, go_router).
- Bar items that morph between pushed routes: the package's `GlassNavigationShell`; a tab bar
  that shrinks to the selected tab on scroll: `GlassTabBar.minimizable`. The foundation code uses neither
  yet — take the API from the package guide and look at the result on the simulator.

### 4. Screens

Build each screen from `references/screens.md`: hero / dashboard, info cards, settings, lists
with swipe to delete and empty states, forms in sheets, detail screens, onboarding and other
full-screen moments, alerts, charts, text input. Use the template widgets first; reach for other
`Glass*` widgets only for what they don't cover, and take their API from the package guide.
Numbers for anything new are in `references/tokens.md`.

### 5. Verify on screen

Glass shows its problems only when rendered, so analysis alone doesn't finish the job.

- `flutter analyze` clean, and `bash <skill-dir>/scripts/check_look.sh` breaks no rule (it greps
  for Material leftovers, unresolved dynamic colors, raw font sizes, circular corners, glass
  content, the wrong theme and ungated debug switches; look at each warning).
- Run on an iOS 26+ simulator and look at every changed screen in light and dark:
  `xcrun simctl io booted screenshot s.png`, `xcrun simctl ui booted appearance dark`.
  Downscale before reading (`sips -Z 1000 s.png --out s_small.png`). A debug build launched
  without `flutter run` can stay blank for up to about 10 s; wait 12 s before capturing.
- `simctl` can't tap. To open a screen without tapping, write its name into the app's temp
  folder before launching (`echo settings > "$(xcrun simctl get_app_container booted
  <bundle-id> data)/tmp/shot"`) and read `File('${Directory.systemTemp.path}/shot')` in a
  debug-only switch that selects the tab, opens the sheet or scrolls. Environment variables via
  `SIMCTL_CHILD_*` did not reach `Platform.environment` in a Flutter debug build. Remove the
  switch, or keep it behind `kDebugMode`, before finishing. If the Dart and Flutter MCP server
  is connected, its app-driving tools (launch, tap, scroll, widget tree) can replace the switch;
  they need a driver-enabled entry point.
- Accessibility pass on the changed screens: the largest text size
  (`xcrun simctl ui booted content_size accessibility-extra-extra-extra-large`, back with
  `large`), Increase Contrast (`xcrun simctl ui booted increase_contrast enabled`, then
  `disabled`), Reduce Motion and Reduce Transparency in the simulator's Settings →
  Accessibility, and VoiceOver through Accessibility Inspector (Xcode → Open Developer Tool) on
  new controls, rings and charts. Nothing may clip, overlap or go unlabelled.
- Without a Mac, an Android emulator shows the same layout: `adb exec-out screencap -p > s.png`,
  `adb shell cmd uimode night yes`, `adb shell settings put system font_scale 2.0`.
- If the project has a screenshot tour script, use it.
- Go through the checklist at the end. When restyling an existing app, show the user before and
  after screenshots.

### Review without changing

When the user asks for a review or audit, don't edit. Run `flutter analyze` and
`scripts/check_look.sh`, capture the screens in light, dark and at the largest text size, then
report findings grouped by area — glass and material, color and type, layout and bars,
accessibility, native behavior — each ranked P0 (unreadable, broken, content hidden under
glass) to P3 (polish), with `file:line` and the rule from this skill it breaks. Offer the fixes
afterwards.

## Rules

- **Glass is for what you touch.** Content is `ContentCard` / `GroupedSection`, never a glass
  card. Inside opaque rows, glass controls bring their own layer:
  `GlassSwitch(useOwnLayer: true)`.
- **Never nest glass in glass** (a glass button in a glass card): double refraction, clipped
  animations, wasted GPU.
- **Colors** come from `AppColors` (tints) and `CupertinoColors` (labels, fills, backgrounds,
  separators), resolved with the context before any `.withValues(alpha:)`; unresolved dynamic
  colors give dark mode the light color.
- **Text** goes through `AppText`; anything that changes in place uses `.tabular`.
- **Corners** are continuous: `RoundedSuperellipseBorder` for content,
  `LiquidRoundedSuperellipse` for glass. A plain `BorderRadius` on a card is the circular arc
  that gives Flutter UIs away.
- **No Material leftovers**: ripples, elevation, Roboto metrics, `Icons.*`.
- **Layout**: content starts at `AppLayout.topInset` and ends at `AppLayout.bottomInset`, so
  nothing hides under the bars; `AppLayout.gutter` centers content at 640 pt on iPad and Mac.
- **Accessibility**: 44 × 44 pt targets; a semantic label on every icon-only button and switch;
  a spoken summary on rings (`ProgressRing(semanticsLabel:)`) and charts (`Semantics`); layouts
  that survive accessibility text sizes. Your own motion and translucency follow Reduce Motion
  (`MediaQuery.disableAnimationsOf`) and Increase Contrast (`MediaQuery.highContrastOf`), as the
  templates do; the package handles its glass widgets itself.
- **Sheets and alerts**: `showAppSheet` + `SheetHeader` and `GlassDialog.show`, never Material
  bottom sheets or `AlertDialog`.
- **Fonts**: never bundle SF Pro (Apple's license limits it to Apple platforms); the system
  provides it on iOS and macOS, and other platforms fall back to their own font.

## Pitfalls already hit

- **`GlassThemeData.ios27()` (1.15, unchanged in 1.16) is not the theme to use.** It also sets premium quality on
  every glass widget, which draws buttons in the screen's shared glass layer: a tinted button
  turns pale, neighbouring buttons melt together, and buttons from other tabs of an
  `IndexedStack` show through on the current one. `AppTheme.glass` takes the same iOS 27
  settings without the quality override.
- The package's soft scroll edge doesn't cover the navigation bar; `AppShell` sets
  `edgeFade: false` and draws `ScrollEdgeBar` instead.
- The status-bar tap scrolls the `PrimaryScrollController` found above `GlassScaffold` (it
  builds a `CupertinoPageScaffold`). Pages with their own controller never get it unless one is
  provided there; `AppShell` provides the current tab's, and wraps the body in
  `PrimaryScrollController.none` so nested lists don't attach to it too.
- `GlassTabBar` (1.16) doesn't report a finger tap on the tab that is already selected — only
  VoiceOver activation arrives in `onTabSelected` — so tap-again-to-scroll-up isn't possible yet.
- API names that are easy to get wrong: `GlassButton` uses `onTap`, `GlassIconButton` uses
  `onPressed`, `GlassAppBar` takes `actions:` (a list, no `trailing`), `GlassChip.label` is a
  `String`, `GlassBottomBar` no longer exists (`GlassTabBar.bottom`).
- With a `MaterialApp` root, `LiquidGlassWidgets.wrap` needs
  `brightnessResolver: Theme.maybeBrightnessOf`.
- A swiped-away `Dismissible` must leave the tree inside `onDismissed`, or Flutter throws.
- Apps built with the iOS 27 SDK crash at launch without UIScene adoption
  (`_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`): Info.plist needs
  `UIApplicationSceneManifest`. Flutter migrates an unmodified `AppDelegate` itself; with a
  customized one, register plugins in `didInitializeImplicitFlutterEngine`.

## Other platforms

The look works beyond Apple platforms: the glass renders on Android, Windows and the web
(`initialize()` skips preloading the heaviest shaders on Windows, Linux and web). Text falls back
to the platform font, haptics do nothing on desktop, and wide windows are handled by
`AppLayout.gutter`. Desktop shortcuts use ⌘ on macOS and Ctrl elsewhere
(`SingleActivator(key, meta: Platform.isMacOS, control: !Platform.isMacOS)`).

## Performance

Glass costs GPU, and the simulator says nothing about frame rate. Measure on devices: a profile
build (`flutter run --profile`) on the oldest supported iPhone and on a mid-range Android,
scrolling under the bars with `showPerformanceOverlay: true`, or a timeline from an integration
test's `traceAction`. If frames drop: `LiquidGlassWidgets.wrap(adaptiveQuality: true)` lets the
package lower quality on slow devices, `GlassQuality.minimal` suits glass in dense lists, and
premium stays on the bars, where `GlassScaffold` puts it.

## Package API

For exact parameters, read the guide that ships with the installed version. Find the package
folder from `.dart_tool/package_config.json` (works with FVM and a custom `PUB_CACHE`):

```bash
python3 -c "import json; print(next(p['rootUri'] for p in json.load(open('.dart_tool/package_config.json'))['packages'] if p['name'] == 'liquid_glass_widgets'))"
```

then read `<root>/skills/liquid-glass-widgets/SKILL.md` and `<root>/CHANGELOG.md`. Follow it on
API names, and this skill on the look. Where they differ on purpose:

- **Theme.** Its examples use `GlassThemeData.simple(…)`; this skill uses `AppTheme.glass`, the
  iOS 27 settings without `ios27()`'s premium override.
- **Content cards.** Both keep content opaque now. Its `GlassContainer.card` /
  `GlassGroupedSection(surfaceStyle: GlassSurfaceStyle.solid)` is nearly the same card (#FFFFFF
  / #1C1C1E, 26 pt continuous corners); this skill keeps `ContentCard` / `GroupedSection`
  because `GroupedRow`, `RowIcon` and the sheets are built on them. Don't mix both in one list.
- **Lists and pickers.** It says not to hand-roll `Dismissible` or date pickers;
  `references/screens.md` §6–7 still use them with `GroupedRow`, whose metrics the package's
  `GlassListTile` doesn't match. For a new list, `GlassListTile` with `trailingSwipeActions` in a
  solid `GlassGroupedSection` is a fine choice — compare screenshots with the rest of the app
  first.

## Done checklist

- [ ] `flutter analyze` is clean; `scripts/check_look.sh` breaks no rule.
- [ ] Every changed screen was looked at in light and dark mode on a simulator.
- [ ] …and at the largest accessibility text size and with Increase Contrast; rings and charts
      speak a summary in VoiceOver.
- [ ] Glass only on bars, buttons, switches, sheets and dialogs; content is opaque.
- [ ] No `package:flutter/material.dart` imports left, or a short deliberate list.
- [ ] Colors come from `AppColors` / `CupertinoColors`, resolved; text from `AppText`; live
      numbers are tabular.
- [ ] Content clears the navigation bar and the tab bar; nothing sits under glass by accident.
- [ ] Touch targets are at least 44 pt; icon-only buttons and switches have semantic labels.
- [ ] On iPad / Mac widths, content stays at 640 pt and centered.
- [ ] Verification switches are removed or debug-only.
