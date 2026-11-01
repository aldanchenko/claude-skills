# Moving an existing Material app to the iOS 27 look

Most Flutter apps start as `MaterialApp`. This is the order that keeps the app running at every
step, and the mapping for the widgets you will meet.

## Decide the target first

Ask the user only what the code can't tell you:

- **Platforms.** If the app ships on Android (or Windows, web) or is planned to, the iOS look
  applies there too: liquid_glass_widgets renders on every platform, and indie apps commonly
  ship one design everywhere. The alternative, Material on Android and Cupertino on iOS,
  doubles the UI work; suggest it only if the user wants Android to feel native.
- **Brand.** Custom fonts and brand colors: keep the brand color as `AppColors.accent`; keep a
  brand font for the logo or hero moments only, because the iOS look depends on SF Pro and its
  tracking.

Default (no answer needed): full switch to `CupertinoApp`, no Material widgets left.

## Order of work

Run `flutter analyze` after each step and keep the app launching.

1. **Foundation.** Add `liquid_glass_widgets` (1.15+), copy `assets/core/` into `lib/core/`,
   set `AppColors.accent`. In `main()`: `await LiquidGlassWidgets.initialize()` and
   `LiquidGlassWidgets.wrap(theme: AppTheme.glass, …)`. While `MaterialApp` is still the root,
   pass `brightnessResolver: Theme.maybeBrightnessOf` to `wrap`, or glass follows the system
   brightness instead of the app's theme mode.
2. **Root.** `MaterialApp` → `CupertinoApp` (`MaterialApp.router` → `CupertinoApp.router`),
   `theme: AppTheme.cupertino`. Keep localization: pass the same `localizationsDelegates` and
   `supportedLocales` (gen-l10n's `AppLocalizations.localizationsDelegates` already includes
   the Material, Cupertino and Widgets delegates). Material widgets still on screen now need a
   `Material` ancestor; wrap a screen's body in `Material(type: MaterialType.transparency)`
   temporarily rather than fixing everything at once.
3. **Shell.** Replace the `Scaffold` + `BottomNavigationBar`/`NavigationBar` root with
   `AppShell`, one `ShellTab` per destination. Move each tab's `AppBar` actions to
   `ShellTab.actions`.
4. **Screens, one at a time.** Convert each screen to `TabPage` (tabs) or the detail-screen
   recipe (pushed), then swap its widgets with the table below.
5. **Clean up.** `grep -rn "package:flutter/material.dart" lib` should come back empty (or
   with a short, deliberate list); remove the temporary `Material` wrappers, the old
   `ThemeData`, and `Theme.of(context)` calls.

## Widget mapping

| Material | Replacement |
|---|---|
| `MaterialApp` | `CupertinoApp` + `AppTheme.cupertino` |
| `Scaffold` (tab root) | `AppShell` |
| `Scaffold` (pushed screen) | `GlassScaffold` + `GlassAppBar.pinned` (screens.md §8) |
| `AppBar` | `GlassAppBar` / `GlassAppBar.pinned`; large titles via `TabPage` |
| `BottomNavigationBar`, `NavigationBar` | `GlassTabBar.bottom` (inside `AppShell`) |
| `TabBar` (top) | `GlassSegmentedControl` above the content |
| `FloatingActionButton` | a `GlassIconButton(CupertinoIcons.add)` in the bar actions, or a `GlassPillButton` in the content |
| `ElevatedButton`, `FilledButton` | `GlassPillButton(tint:)` |
| `OutlinedButton` | `GlassPillButton` without tint |
| `TextButton` | `CupertinoButton` with `AppText.headline` in the accent color |
| `IconButton` | `GlassIconButton` in bars; `CupertinoButton` with an icon in content |
| `Card` | `ContentCard` |
| `ListTile` | `GroupedRow` inside a `GroupedSection` |
| `Divider` | the hairlines `GroupedSection` draws |
| `SwitchListTile`, `Switch` | `GroupedRow(trailing: GlassSwitch(useOwnLayer: true))` |
| `Slider` | `GlassSlider` (or `CupertinoSlider`) |
| `Checkbox` | `CupertinoIcons.checkmark_circle_fill` / `circle` icons on a tappable row |
| `Radio` group | rows with a trailing `CupertinoIcons.checkmark` on the selected one |
| `TextField`, `TextFormField` | `CupertinoTextField.borderless` in a card row; validation as a footnote |
| `DropdownButton`, `PopupMenuButton` | `GlassPullDownButton`, or a row that opens a picker |
| `showModalBottomSheet` | `showAppSheet` + `SheetHeader` |
| `AlertDialog`, `showDialog` | `GlassDialog.show` + `GlassDialogAction` |
| `SnackBar` | `GlassToast.show(context, message: …)`, or an inline status line |
| `showDatePicker`, `showTimePicker` | inline `CupertinoDatePicker` in a sheet (screens.md §7) |
| `CircularProgressIndicator` | `CupertinoActivityIndicator`; for progress values `ProgressRing` |
| `LinearProgressIndicator` | `CapsuleProgress` |
| `ExpansionTile` | rows that reveal more rows, or `GlassDisclosureGroup` (1.15+) |
| `Chip` | `GlassChip` (its `label` is a `String`) |
| `InkWell`, ripples | `GestureDetector` + pressed highlight (`GroupedRow` does it) or `CupertinoButton` |
| `MaterialPageRoute` | `CupertinoPageRoute` (edge swipe back; `fullscreenDialog: true` for modal pages) |
| `Icons.*` | `CupertinoIcons.*` (below) |
| `Theme.of(context).textTheme.x` | `AppText.x` |
| `Theme.of(context).colorScheme.*` | `AppColors.*` / `CupertinoColors.*`, resolved |

Common icons: `add` → `add`; `delete` → `trash`; `edit` → `pencil`; `settings` →
`gear_alt` / `gear_alt_fill`; `home` → `house` / `house_fill`; `search` → `search`; `share` →
`share`; `close` → `xmark`; `check` → `checkmark_alt`; `more_vert` → `ellipsis_circle`;
`notifications` → `bell` / `bell_fill`; `person` → `person` / `person_fill`; `bar_chart` →
`chart_bar` / `chart_bar_fill`; `favorite` → `heart` / `heart_fill`; `star` → `star` /
`star_fill`; `info` → `info_circle`; `calendar_today` → `calendar`; `list` → `list_bullet`.
When unsure a name exists, grep `packages/flutter/lib/src/cupertino/icons.dart` in the Flutter
SDK; SF Symbol names such as `square_and_arrow_up` are not all there.

## go_router

- `MaterialApp.router` → `CupertinoApp.router(routerConfig: router, theme: AppTheme.cupertino)`.
- Pages: `pageBuilder: (context, state) => CupertinoPage(child: …)` for the iOS push
  transition and swipe back.
- Pushed screens use `GlassAppBar.pinned(onBack: () => context.pop())`.
- Tabs: a `StatefulShellRoute.indexedStack` whose builder renders the shell around
  `navigationShell`, selecting with `navigationShell.currentIndex` and switching with
  `navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex)`.
  `AppShell` keeps its own index and `IndexedStack`, so adapt a copy of it: take the index and
  callback from `navigationShell`, use `navigationShell` as the body, and keep one
  `GlassLargeTitleController` per branch in the shell's state, handed to the branch screens
  through an `InheritedWidget` or a provider. Push detail routes on the root navigator
  (`parentNavigatorKey`) so they cover the tab bar. This wiring is not yet proven in a real app:
  check it on screenshots, including switching tabs and going back.

## Things that break quietly

- `Theme.of(context)` without a `MaterialApp` returns a default light `ThemeData`: dark mode
  shows light colors. Grep for it.
- `CupertinoDynamicColor` used unresolved with `.withValues(alpha:)` → the light color in
  dark mode.
- Material widgets left under a `CupertinoApp` throw "No Material widget found"; the temporary
  `Material` wrapper from step 2 hides it until the cleanup.
- `TextStyle`s copied from the old theme keep Roboto metrics; use `AppText`.
- Packages that bring Material UI (date pickers, image pickers' own screens, `flutter_colorpicker`)
  are fine as modal flows; don't restyle third-party screens by hand.
