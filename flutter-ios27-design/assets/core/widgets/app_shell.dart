import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_background.dart';
import 'app_layout.dart';
import 'scroll_edge_bar.dart';

/// One tab of an [AppShell].
class ShellTab {
  final String title;
  final IconData icon;

  /// Filled variant shown while selected, e.g. `house_fill` for `house`.
  final IconData? activeIcon;

  /// Builds the tab's page; hand the controller to a [TabPage].
  final Widget Function(GlassLargeTitleController largeTitle) builder;

  /// Glass buttons in the navigation bar while this tab is selected.
  final List<Widget> Function(BuildContext context)? actions;

  /// Strength of the background wash: 1 on a hero tab, less on lists.
  final double wash;

  const ShellTab({
    required this.title,
    required this.icon,
    this.activeIcon,
    required this.builder,
    this.actions,
    this.wash = 0.55,
  });
}

/// Tab root: one glass navigation bar and tab bar shared by all tabs, each
/// tab keeping its own scroll position and large title.
class AppShell extends StatefulWidget {
  final List<ShellTab> tabs;

  /// Color of the background wash. Pass a state color (green while something
  /// runs, blue once done) and the backdrop follows the app's state.
  final Color tint;

  const AppShell({super.key, required this.tabs, this.tint = AppColors.accent});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selected = 0;
  late final List<GlassLargeTitleController> _largeTitles = List.generate(
    widget.tabs.length,
    (_) => GlassLargeTitleController(),
  );

  @override
  void dispose() {
    for (final controller in _largeTitles) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Tapping the selected tab again scrolls it to the top, as on iOS. As of
  /// liquid_glass_widgets 1.16, GlassTabBar reports the selected tab only
  /// when VoiceOver activates it, not on a finger tap.
  void _onTabSelected(int index) {
    if (index != _selected) {
      setState(() => _selected = index);
      return;
    }
    final scroll = _largeTitles[index].scrollController;
    if (scroll.hasClients) {
      scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tabs[_selected];
    final largeTitle = _largeTitles[_selected];

    // The status-bar tap scrolls the PrimaryScrollController found above the
    // scaffold (GlassScaffold builds a CupertinoPageScaffold), so the current
    // tab's controller goes here. Inside the body it is switched off again,
    // or every scroll view without its own controller would attach to it.
    return PrimaryScrollController(
      controller: largeTitle.scrollController,
      child: _scaffold(context, tab, largeTitle),
    );
  }

  Widget _scaffold(
    BuildContext context,
    ShellTab tab,
    GlassLargeTitleController largeTitle,
  ) {
    return GlassScaffold(
      background: AppBackground(tint: widget.tint, intensity: tab.wash),
      statusBarStyle: GlassStatusBarStyle.auto,
      // iOS 27 edges: a hard frosted bar on top, nothing above the tab bar.
      edgeFade: false,
      bodyOverlays: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ListenableBuilder(
            listenable: largeTitle,
            builder: (context, _) => ScrollEdgeBar(
              progress: largeTitle.collapseProgress,
              height: AppLayout.topInset(context),
            ),
          ),
        ),
      ],
      appBar: GlassAppBar(
        title: Text(tab.title),
        largeTitleController: largeTitle,
        actions: tab.actions?.call(context),
      ),
      bottomBar: GlassTabBar.bottom(
        tabs: [
          for (final t in widget.tabs)
            GlassTab(
              icon: Icon(t.icon),
              activeIcon: t.activeIcon == null ? null : Icon(t.activeIcon),
              label: t.title,
            ),
        ],
        selectedIndex: _selected,
        onTabSelected: _onTabSelected,
      ),
      body: PrimaryScrollController.none(
        child: IndexedStack(
          index: _selected,
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              widget.tabs[i].builder(_largeTitles[i]),
          ],
        ),
      ),
    );
  }
}

/// A tab's page under the shared glass bars: room for the navigation bar,
/// the large title, then the content inside the gutter, ending clear of the
/// floating tab bar.
class TabPage extends StatelessWidget {
  final String title;
  final GlassLargeTitleController largeTitle;

  /// Optional line under the large title, e.g. today's date.
  final String? subtitle;

  /// The content as box widgets…
  final List<Widget> children;

  /// …or as one sliver, for long lazily built lists.
  final Widget? sliver;

  const TabPage({
    super.key,
    required this.title,
    required this.largeTitle,
    this.subtitle,
    this.children = const [],
    this.sliver,
  });

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.gutter(context);
    final subtitle = this.subtitle;

    return CustomScrollView(
      controller: largeTitle.scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: AppLayout.topInset(context)),
        ),
        GlassLargeTitle(
          text: title,
          controller: largeTitle,
          padding: EdgeInsetsDirectional.fromSTEB(
            gutter + 4,
            0,
            gutter,
            subtitle == null ? 8 : 0,
          ),
        ),
        if (subtitle != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(gutter + 4, 0, gutter, 0),
              child: Text(
                subtitle,
                style: AppText.subheadline.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            subtitle == null ? 8 : 24,
            gutter,
            AppLayout.bottomInset(context),
          ),
          sliver: sliver ?? SliverList.list(children: children),
        ),
      ],
    );
  }
}
