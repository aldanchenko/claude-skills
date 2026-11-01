# Screen recipes

Patterns from a shipped app, built on the templates in `assets/core/`. Snippets assume the
templates are in `lib/core/` and use their names (`AppText`, `AppColors`, `ContentCard`,
`GroupedSection`, `GroupedRow`, `RowIcon`, `GlassPillButton`, `showAppSheet`, `SheetHeader`,
`AppShell`, `TabPage`, `ProgressRing`, `CapsuleProgress`, `AppBackground`, `AppLayout`).

## Contents

1. Bootstrap
2. Tab app
3. Hero / dashboard tab
4. Info card
5. Settings
6. Lists: rows, swipe to delete or undo, empty, loading and error states
7. Form in a sheet
8. Pushed detail screen
9. Full-screen moment and onboarding
10. Alerts
11. Charts (fl_chart)
12. Navigation-bar chip
13. Text input
14. iPad and Mac
15. Copy

## 1. Bootstrap

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize(); // pre-warms the shaders
  runApp(
    ProviderScope( // if the app uses Riverpod
      child: LiquidGlassWidgets.wrap(theme: AppTheme.glass, child: const App()),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'My App',
      theme: AppTheme.cupertino,
      debugShowCheckedModeBanner: false,
      home: const Root(),
    );
  }
}
```

First launch → app: switch the root with `AnimatedSwitcher(duration: 450 ms)` and give each
child a `ValueKey`; while settings load, show a plain `ColoredBox` in
`systemGroupedBackground` (no spinner flash).

## 2. Tab app

```dart
AppShell(
  tint: AppColors.teal, // or a state color: green while running, blue when done
  tabs: [
    ShellTab(
      title: 'Today',
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      wash: 1, // the hero tab gets the full background wash
      builder: (largeTitle) => TodayTab(largeTitle: largeTitle),
    ),
    ShellTab(
      title: 'History',
      icon: CupertinoIcons.list_bullet,
      builder: (largeTitle) => HistoryTab(largeTitle: largeTitle),
      actions: (context) => [
        GlassIconButton(
          icon: const Icon(CupertinoIcons.add),
          semanticLabel: 'Add entry',
          onPressed: () => showEntrySheet(context),
        ),
      ],
    ),
    ShellTab(
      title: 'Settings',
      icon: CupertinoIcons.gear_alt,
      activeIcon: CupertinoIcons.gear_alt_fill,
      builder: (largeTitle) => SettingsTab(largeTitle: largeTitle),
    ),
  ],
)
```

Each tab page is a `TabPage(title:, largeTitle:, children: […])` (or `sliver:` for long lazy
lists). Three to five tabs; outline icons with `_fill` variants for the selected state. To make
the wash follow app state, build `AppShell` inside a widget that watches that state and passes
`tint:`; the background cross-fades by itself.

## 3. Hero / dashboard tab

One thing the screen is about, big, then the action, then supporting cards.

```dart
TabPage(
  title: 'Today',
  subtitle: formatLongDate(today), // "Saturday, 25 October"
  largeTitle: largeTitle,
  children: [
    Center(
      child: ProgressRing(
        progress: progress,
        color: AppColors.green,
        size: size, // math.min(availableWidth - 40, 290.0).clamp(220.0, 290.0)
        strokeWidth: size * 0.095,
        // One sentence for VoiceOver instead of the three texts inside.
        semanticsLabel: 'Today, ${formatDurationSpoken(total)} of 8 hours',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            statusLabel, // subheadline w600 in the status color, 7 pt dot when live
            const SizedBox(height: 2),
            Text(formatDuration(total), style: AppText.hero),
            Text('of 8 h', style: AppText.subheadline.copyWith(color: secondary)),
          ],
        ),
      ),
    ),
    const SizedBox(height: 28),
    Center(
      child: GlassPillButton(
        icon: CupertinoIcons.play_fill,
        label: 'Start',
        tint: AppColors.green,
        width: 208,
        onTap: start,
      ),
    ),
    const SizedBox(height: 32),
    // supporting ContentCards, 16 apart
  ],
)
```

While something runs, show two 148-wide pills 12 apart: the pause action in plain glass (no
tint) and the stop action tinted red. Size the pair to its longest label, so a translation
fits ("Продолжить" needs about 173 where "Resume" fits in 148) and the pills don't change
width between Pause and Resume:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final needed = [pauseLabel, resumeLabel, stopLabel]
        .map((label) => GlassPillButton.widthFor(context, label))
        .reduce(math.max);
    final width = math.min(math.max(needed, 148.0), (constraints.maxWidth - 12) / 2);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassPillButton(/* pause or resume */ width: width, ...),
        const SizedBox(width: 12),
        GlassPillButton(/* stop, tint: AppColors.red */ width: width, ...),
      ],
    );
  },
)
```

Past that cap — a narrow phone, a large text size — `GlassPillButton` shrinks its icon and
label to fit instead of overflowing. A number in a card: `headline` title, `title1.tabular`
value, `subheadline` secondary line, then `CapsuleProgress(height: 8)` 12 below.

## 4. Info card

Status or advice with an optional inline action:

```dart
ContentCard(
  child: Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15), // color already resolved
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.headline),
            const SizedBox(height: 2),
            Text(detail, style: AppText.subheadline.copyWith(color: secondary)),
          ],
        ),
      ),
      if (action != null) ...[const SizedBox(width: 8), action],
    ],
  ),
)
```

The action is a text button: `CupertinoButton(padding: EdgeInsets.symmetric(horizontal: 4),
minimumSize: Size(44, 44), child: Text('Fix', style: AppText.headline.copyWith(color: accent)))`.

## 5. Settings

```dart
GroupedSection(
  header: 'Reminders',
  footer: 'A nudge when you reach your goal.', // say what the setting does
  separatorIndent: 60, // lines start after the icon tiles
  children: [
    GroupedRow(
      leading: const RowIcon(CupertinoIcons.bell_fill, color: AppColors.red),
      title: 'Notify when reached',
      trailing: GlassSwitch(
        value: reminders,
        onChanged: (v) => setState(() => reminders = v),
        useOwnLayer: true, // the row is opaque; the switch brings its own glass
        semanticLabel: 'Notify when reached',
      ),
    ),
    GroupedRow(
      leading: const RowIcon(CupertinoIcons.sun_max_fill, color: AppColors.orange),
      title: 'Daily goal',
      value: '8 h',
      onTap: pickGoal, // a tappable row gets the chevron automatically
    ),
  ],
)
```

- Sections 32 apart. Tile colors vary per row like iOS Settings, using tints from `AppColors`.
- Rows that depend on a toggle appear and disappear under it (`if (enabled) ...[…]`).
- Value pickers inline in a card: `ContentCard(padding: EdgeInsets.zero, child: SizedBox(height:
  150, child: CupertinoPicker.builder(itemExtent: 38, useMagnifier: true, magnification: 1.08,
  onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); … }, …)))`, items in
  `AppText.title3.tabular` with `FontWeight.w400`.
- About / legal at the end: rows with a `RowIcon` that push a detail screen (section 8).

## 6. Lists

Rows are `GroupedRow`s in one `GroupedSection` per group (per day, per category):

```dart
GroupedSection(
  footer: 'Tap an entry to edit it, or swipe left to delete it.',
  separatorIndent: 44, // after a status dot
  children: [
    for (final entry in entries)
      GroupedRow(
        key: ValueKey(entry.id),
        leading: StatusDot(color: entry.isActive ? AppColors.green : CupertinoColors.systemGrey3),
        title: '9:00 – 12:30',
        subtitle: entry.isActive ? 'In progress' : null,
        value: formatDuration(entry.duration), // tabular automatically
        onTap: () => showEntrySheet(context, entry: entry),
      ),
  ],
)
```

`StatusDot` is a 14-wide box with a 9 pt circle centered in it.

**Swipe to delete** (works on any package version):

```dart
Dismissible(
  key: ValueKey('entry_${entry.id}'),
  direction: DismissDirection.endToStart,
  background: Container(
    color: CupertinoDynamicColor.resolve(AppColors.red, context),
    alignment: AlignmentDirectional.centerEnd,
    padding: const EdgeInsetsDirectional.only(end: 24),
    child: const Icon(CupertinoIcons.trash_fill, color: CupertinoColors.white, size: 22),
  ),
  confirmDismiss: (_) => confirmDelete(context), // GlassDialog, section 10
  onDismissed: (_) => delete(entry),
  child: row,
)
```

Remove the item from state synchronously in `onDismissed`; a dismissed `Dismissible` that is
still in the tree throws. liquid_glass_widgets 1.15 adds `GlassSwipeActions` and
`GlassListTile.trailingSwipeActions`; they come with their own `GlassGroupedSection` /
`GlassListTile` rows, whose metrics differ from `GroupedRow`. Don't mix the two in one list;
compare screenshots before switching a list over.

Confirm or undo: a confirmation dialog on every swipe slows down a list people clean up often.
Where the item is cheap to restore (Notes, Reminders), delete at once and offer **Undo** for a
few seconds instead — a small glass toast or pill above the tab bar, `HapticFeedback` on delete
— and drop `confirmDismiss`. Keep the dialog for what can't come back (a whole day of entries,
an account).

**Summary above a list**: `title1.tabular` total plus a `subheadline` count ("3 sessions"),
inside the gutter, 20 above the first section.

**Empty state** (centered in the remaining space, 32 side padding):

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(CupertinoIcons.clock, size: 54, color: tertiaryLabel),
    const SizedBox(height: 16),
    const Text('No sessions yet today', style: AppText.title3),
    const SizedBox(height: 6),
    Text(
      'Start the timer on Today, or add time you forgot to track.',
      textAlign: TextAlign.center,
      style: AppText.subheadline.copyWith(color: secondary),
    ),
    const SizedBox(height: 22),
    GlassPillButton(icon: CupertinoIcons.add, label: 'Add Session', height: 48, onTap: add),
  ],
)
```

Use it inside `SliverFillRemaining(hasScrollBody: false, …)`. **Loading**: a centered
`CupertinoActivityIndicator` in the same sliver; with Riverpod `skipLoadingOnReload: true` so
lists don't flash on refresh.

**Error** (same place and layout as the empty state): `CupertinoIcons.exclamationmark_triangle`
in `secondaryLabel`, a `title3` that names what failed ("Couldn't load your sessions"), one
`subheadline` line with the way out ("Check the connection and try again."), and a plain
`GlassPillButton(label: 'Try Again')`. No apology, no error codes; keep showing data that
already loaded and put a footnote line above it instead of replacing the list.

## 7. Form in a sheet

```dart
Future<void> showEntrySheet(BuildContext context, {Entry? entry}) {
  return showAppSheet<void>(
    context,
    height: entry == null ? 560 : 640, // points at default text size; grows with Dynamic Type
    builder: (_) => EntryForm(entry: entry),
  );
}
```

The keyboard must never cover the field being edited or the ✓ button: the sheet's scroll view
gets `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`, the last field's
`TextInputAction.done` closes the keyboard, and the form is checked at the largest text size
with the keyboard up.

Inside the form:

- `SingleChildScrollView(padding: EdgeInsets.fromLTRB(16, 14, 16, 24))`.
- `SheetHeader(title: 'New Entry', onCancel: pop, onConfirm: valid ? save : null)`: round
  ✕ on the left, title, round ✓ on the right that stays dimmed until the form is valid. No
  "Save" text buttons.
- 20 below the header, a `GroupedSection` of fields. A date or time field is a `GroupedRow`
  whose trailing is a value capsule (`ShapeDecoration(color: tertiarySystemFill, shape:
  StadiumBorder())`, padding 12 × 6, `AppText.body.tabular`, accent-colored while open);
  tapping it opens an inline `CupertinoDatePicker` (height 200) right under the row.
- 10 below, one footnote line with 20 pt side padding: the validation problem in red, or a
  helpful summary ("Duration: 3 h 30 min") in `secondaryLabel`.
- For an existing item, a full-width red `GlassPillButton(height: 50)` at the bottom, 28
  below, behind a confirmation dialog.

## 8. Pushed detail screen

```dart
Navigator.of(context).push(
  CupertinoPageRoute<void>(builder: (_) => const DetailScreen()),
);

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.gutter(context);
    return GlassScaffold(
      background: const AppBackground(tint: AppColors.accent, intensity: 0.4),
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: const GlassAppBar.pinned(title: Text('Privacy Policy')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          gutter,
          AppLayout.topInset(context) + 16,
          gutter,
          MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: const [/* ContentCards */],
      ),
    );
  }
}
```

`GlassAppBar.pinned` shows the glass back button whenever the route can pop; with go_router
pass `onBack: () => context.pop()`. The body runs under the bar, so it pads itself by
`AppLayout.topInset`. `CupertinoPageRoute` gives the edge swipe back.

## 9. Full-screen moment and onboarding

A calm full-screen page for first launch, a finished goal, a paywall:

```dart
GlassScaffold(
  background: const AppBackground(tint: AppColors.teal),
  statusBarStyle: GlassStatusBarStyle.auto,
  body: SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          children: [
            Expanded(child: PageView(controller: pages, onPageChanged: …, children: […])),
            PageDots(count: 3, current: page),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: GlassPillButton(
                icon: last ? CupertinoIcons.checkmark_alt : CupertinoIcons.arrow_right,
                label: last ? 'Get Started' : 'Continue',
                tint: AppColors.accent,
                width: double.infinity,
                onTap: next, // nextPage(420 ms, easeOutCubic) or finish
              ),
            ),
          ],
        ),
      ),
    ),
  ),
)
```

- A page: `SingleChildScrollView(padding: EdgeInsets.fromLTRB(24, 40, 24, 16))` → hero (a
  `ProgressRing` 148–168 with an icon inside, or a 58–72 pt glyph in a tint) → 28 → centered
  `largeTitle` → 10 → centered `body` in `secondaryLabel`, `height: 1.35` → page controls.
- Page dots: `AnimatedContainer(250 ms)`, active 18 × 7 in `label`, others 7 × 7 in
  `tertiaryLabel`, radius 4, 4 apart.
- Present such a page modally with `CupertinoPageRoute(fullscreenDialog: true, …)`.

## 10. Alerts

```dart
final confirmed = await GlassDialog.show<bool>(
  context: context,
  title: 'Delete this session?',
  message: 'It will be removed from your totals. This can’t be undone.',
  actions: [
    GlassDialogAction(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
    GlassDialogAction(
      label: 'Delete',
      isDestructive: true,
      onPressed: () => Navigator.of(context).pop(true),
    ),
  ],
);
```

The title asks the question, the message states the consequence, Cancel comes first and the
destructive action is named with a verb.

## 11. Charts (fl_chart)

Health / Screen Time style bars:

- `gridData: FlGridData(show: false)`, `borderData: FlBorderData(show: false)`, no left, right
  or top titles.
- Bars 22 wide, radius 7, with a background rod to `maxY` in `quaternarySystemFill`;
  `maxY = max(values, goal) * 1.15`.
- The current day in the full tint, other days at 55 % alpha, days that reached the goal in a
  second tint.
- Goal: `HorizontalLine` 1 pt, `dashArray: [4, 4]`, `secondaryLabel` at 60 %, label
  "Goal 8 h" in `caption2` at the top right.
- Bottom titles: weekday initials in `footnote` w500 `secondaryLabel`; today w700 in the tint.
- Tooltip: `label` color at 85 % as the background, radius 10, padding 10 × 6, text
  `footnote.tabular` w600 in `systemBackground`.
- Put the chart in a `ContentCard` under a `headline` title and a `title1.tabular` total.

## 12. Navigation-bar chip

A small status in the bar (a streak, a count) that is also a button:

```dart
GlassButton.custom(
  onTap: onTap,
  label: '$days day streak', // accessibility label
  height: 44,
  shape: const LiquidRoundedSuperellipse(borderRadius: 22),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.flame_fill, size: 18, color: orange),
        const SizedBox(width: 5),
        Text('$days', style: AppText.headline.tabular.copyWith(color: label)),
      ],
    ),
  ),
)
```

## 13. Text input

Fields live in cards, without borders:

```dart
CupertinoTextField.borderless(
  controller: controller,
  placeholder: 'First thing tomorrow',
  padding: const EdgeInsets.symmetric(vertical: 10),
  style: AppText.body.copyWith(color: CupertinoColors.label.resolveFrom(context)),
  textCapitalization: TextCapitalization.sentences,
  textInputAction: last ? TextInputAction.done : TextInputAction.next,
)
```

Rows of fields go in a `ContentCard` with hairlines between them; the scroll view gets
`keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.

## 14. iPad and Mac

- `AppLayout.gutter` already centers content at 640 pt; full-screen moments use 440–460.
- macOS: the same UI; add keyboard shortcuts with `CallbackShortcuts` + `Focus(autofocus:
  true)` around the shell for the main actions (e.g. ⇧⌘S start/stop), behind
  `Platform.isMacOS`.

## 15. Copy

- Short, calm, second person: "Forgot to stop the timer? Set when you finished — nothing
  after that will count." Footers explain consequences, not the obvious.
- Typographic punctuation in UI strings: ’ “ ” – — and the ellipsis character.
- Title Case for buttons and sheet titles, sentence case elsewhere (see tokens.md).
- An action keeps one name through the flow: "Add Session" on the button, "New Session" as the
  sheet title, "Session added" after. Don't switch between add / create / new.
- Errors say what happened and what to do next, without "Oops", "Sorry" or codes. An empty
  screen invites the first action rather than describing absence.
