# Design tokens

The numbers behind the look. The templates in `assets/core/` already encode them; read this
when building something the templates don't cover, or when checking a screen against iOS.

## Contents

1. Colors: tints, semantic colors, tint recipes
2. Typography
3. Layout and sizes
4. Motion and haptics
5. Glass material (including the 1.14 fallback)

## 1. Colors

### Tints: the iOS 26/27 palette

Flutter's `CupertinoColors.systemBlue`, `systemRed` and the rest still carry the iOS 13–18
hues (`systemBlue` is `#007AFF`). iOS 26 moved every tint; using the new ones is a large part
of why the app reads as current iOS instead of "Flutter Cupertino". `AppColors` has them:

| Name | Light | Dark | Typical meaning |
|---|---|---|---|
| red | `#FF383C` | `#FF4245` | destructive, stop, errors |
| orange | `#FF8D28` | `#FF9230` | warnings, overtime, streaks |
| yellow | `#FFCC00` | `#FFD600` | paused, "almost there" (fill only; text uses `yellowText` `#B07A00`) |
| green | `#34C759` | `#30D158` | running, on track, start |
| teal | `#00C3D0` | `#00D2E0` | calm idle state, days off |
| blue | `#0088FF` | `#0091FF` | default accent, links, "done" |
| indigo | `#6155F5` | `#6D7CFF` | secondary background glow, info |
| purple | `#CB30E0` | `#DB34F2` | rare extra category |

Mint, cyan, pink and brown are not in the template. If a design needs one, take the iOS 26
values from Apple's Human Interface Guidelines color table and add them the same way; don't
fall back to the `CupertinoColors` versions.

One accent per app (`AppColors.accent`). Other tints carry status, never decoration.

### Semantic colors (from `CupertinoColors`, unchanged in iOS 26/27)

| Role | Color |
|---|---|
| Screen background | `systemGroupedBackground` |
| Card and row surface | `secondarySystemGroupedBackground` |
| Surface nested in a card | `tertiarySystemGroupedBackground` |
| Primary text | `label` |
| Secondary text, section headers and footers | `secondaryLabel` |
| Disabled text, chevrons, empty-state glyphs, page dots | `tertiaryLabel` |
| Hairlines | `separator` |
| Pressed row highlight | `systemFill` |
| Inactive round buttons, value capsules, day toggles | `tertiarySystemFill` |
| Chart tracks, empty bars | `quaternarySystemFill` |
| Text on a dark tooltip | `systemBackground` |
| Neutral status dot | `systemGrey3` |

Resolve with `.resolveFrom(context)` (or `CupertinoDynamicColor.resolve(c, context)`)
**before** `.withValues(alpha: …)`. Calling `withValues` on an unresolved
`CupertinoDynamicColor` returns its light color, so dark mode quietly breaks.

### Tint recipes

- **Icon in a soft circle** (info cards, stat cards): circle filled with the tint at 15 %
  alpha, glyph in the full tint. 40 pt circle with a 20 pt glyph, or 48 / 26 for a stat card.
- **Settings tile** (`RowIcon`): 30 pt continuous-corner square, radius 8, full tint, white
  18 pt glyph.
- **Progress tracks**: the tint at 16 % (light) or 24 % (dark) for rings, 18 % for capsule bars.
- **Status dot** before a row title: 7–9 pt circle in the tint; `systemGrey3` when neutral.
- **Tinted glass button**: white glyph and label. **Plain glass button**: `label` color.
- **Charts**: today/current in the full tint, other bars at 55 % alpha, goal reached in a
  second tint (e.g. blue), tracks in `quaternarySystemFill`.

## 2. Typography

`AppText` is Apple's text-style ramp at the default Dynamic Type size, with SF Pro tracking.
The tracking matters as much as the sizes: Flutter's default letter spacing is what makes a
Cupertino UI look slightly off.

| Style | Family | Size | Weight | Tracking | Use |
|---|---|---|---|---|---|
| largeTitle | Display | 34 | 700 | 0.40 | screen titles (`GlassLargeTitle` draws it), onboarding titles |
| title1 | Display | 28 | 700 | 0.38 | the number a card is about ("96:30") |
| title2 | Display | 22 | 700 | −0.26 | stat values, document titles |
| title3 | Display | 20 | 600 | −0.45 | empty-state titles, picker rows |
| headline | Text | 17 | 600 | −0.43 | card titles, emphasized rows, button labels |
| body | Text | 17 | 400 | −0.43 | row titles, paragraphs |
| callout | Text | 16 | 400 | −0.31 | secondary paragraphs |
| subheadline | Text | 15 | 400 | −0.23 | sublines under titles and numbers |
| footnote | Text | 13 | 400 | −0.08 | section headers (UPPERCASE) and footers, hints |
| caption1 | Text | 12 | 400 | 0 | chart and ring labels |
| caption2 | Text | 11 | 400 | 0.06 | axis labels, goal-line labels |
| hero | Display | 48 | 700 | −0.6 | the one big number of a screen (tabular) |

Rules:

- Use `AppText` styles and `copyWith(color:, fontWeight:)`. A raw `TextStyle(fontSize: 16)`
  loses both the font family and the tracking.
- `.tabular` for every number that changes in place: timers, counters, totals in rows, chart
  tooltips. Proportional digits make live values jitter.
- Multi-line secondary text: `height: 1.3`–`1.35`.
- Weights: 600 for emphasis at body sizes, 700 only for titles and hero numbers.
- Title Case for buttons, sheet titles and alert titles' actions ("Add Session", "Get
  Started"); sentence case for everything else. Section headers are UPPERCASE footnote.
- SF Pro is the system font on iOS and macOS, so nothing is bundled. Never ship SF Pro font
  files in an app: Apple's license limits them to Apple platforms. On Android the same styles
  fall back to the platform font, which is fine.

## 3. Layout and sizes

`AppLayout` holds the shared insets.

| What | Value |
|---|---|
| Content gutter | 16 pt; content stops at 640 pt wide and centers (iPad, Mac) |
| Large title inset | gutter + 4 |
| Top inset (content start) | safe area top + 44 (navigation bar) |
| Bottom inset (content end) | max(safe area bottom, 20) + 64 (tab bar) + 28 |
| Card | radius 26, continuous corners (`RoundedSuperellipseBorder`), padding 16, no shadow, no border |
| Gap between cards on a dashboard | 16 |
| Gap between settings sections | 32 |
| Hero block spacing | 28 above and below the ring, 32 before the first card |
| Title → subline | 2–4 |
| Grouped row | min height 52, padding 16 × 10, leading tile + 14 gap |
| Separator indent | 16 plain, 60 after a `RowIcon`, 44 after a status dot |
| Hairline | `1 / MediaQuery.devicePixelRatioOf(context)` |
| Section header | 20 pt side padding, 7 below; footer 7 above |
| Primary pill button | 56 high; 208 wide alone, 148 each in a pair (wider when a label needs it: `GlassPillButton.widthFor`), full width in onboarding |
| Secondary pill | 48–50 high (sheets, empty states) |
| Round sheet buttons | 44 pt, 20 pt glyph |
| Navigation-bar chip | 44 high, radius 22 |
| Minimum hit target | 44 × 44 |
| Icons | 18–20 in buttons and rows, 22 for list checkmarks, 54–72 for hero and empty states |
| Progress ring | stroke ≈ 9.5 % of the diameter; hero 220–290, mini rings 78 / 10 |
| Sheet content | 16 sides, 14 top, header then 20 gap |
| Full-screen moment / onboarding column | max width 440–460, padding 24 |

## 4. Motion and haptics

| What | Duration | Curve |
|---|---|---|
| Toggle, selection change | 180 ms | default |
| Pressed row: highlight on / off | 0 ms / 250 ms | default |
| Page dots, indicators | 250 ms | default |
| Page change (onboarding `PageView`) | 420 ms | `easeOutCubic` |
| Root switch (onboarding → app, `AnimatedSwitcher`) | 450 ms | default |
| Background tint cross-fade | 900 ms | `easeInOut` |
| Progress ring fill | 900 ms | `easeOutCubic` |

- Animate real changes only. A value that ticks every second must not restart a 900 ms
  animation each tick: animate jumps bigger than about 1 %, set the rest directly
  (`ProgressRing` does this).
- Spring and "jelly" motion belong to the glass controls, which the package animates. Don't add
  bounces to opaque content.
- `HapticFeedback.mediumImpact()` on primary pill buttons; `selectionClick()` on pickers,
  toggles and segmented changes; nothing on ordinary navigation taps.
- The package follows Reduce Motion and approximates Reduce Transparency by itself; the
  templates do the same for their own motion (`AppBackground`, `ProgressRing`) and translucency
  (`ScrollEdgeBar`).

## 5. Glass material

- **App-wide:** `LiquidGlassWidgets.wrap(theme: AppTheme.glass, …)` on liquid_glass_widgets
  1.15+: iOS 27's `glassEffect(.regular)` settings — denser frost, a lit rim instead of a drop
  shadow, light from the top in light mode and from the bottom in dark mode. Not
  `GlassThemeData.ios27()`: that preset also makes every glass widget premium (see SKILL.md,
  "Pitfalls already hit").
- **Sheets:** denser than the bars so the screen behind doesn't compete:
  `LiquidGlassSettings.ios27Light/ios27Dark.copyWith(glassColor: systemGroupedBackground at 82 %)`.
  `showAppSheet` does this.
- **Prominent buttons** (iOS 27 `.glassProminent`): `GlassButtonStyle.prominent`, the material
  with `glassColor` = tint at 90 %, `glowColor` = tint at 50 %. `GlassPillButton(tint:)` does
  this.
- **Hard scroll edge:** iOS 27 fills a frosted strip with a hairline behind the navigation bar as
  content scrolls under it. `GlassScaffold(edgeFade: false)` plus `ScrollEdgeBar` driven by
  `GlassLargeTitleController.collapseProgress`; `AppShell` wires it. The package's own soft
  edge doesn't cover the navigation bar, which is why the custom strip exists.

On liquid_glass_widgets 1.14.x, see `legacy-1.14.md`.
