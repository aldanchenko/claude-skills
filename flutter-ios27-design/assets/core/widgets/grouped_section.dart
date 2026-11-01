import 'package:flutter/cupertino.dart';
import '../theme/app_text.dart';
import 'content_card.dart';

/// iOS inset-grouped list section: optional header and footer around a
/// solid card of rows separated by hairlines.
class GroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;

  /// Leading inset of the separators; 60 lines them up after a [RowIcon].
  final double separatorIndent;

  const GroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.separatorIndent = 16,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final separator = Padding(
      padding: EdgeInsetsDirectional.only(start: separatorIndent),
      child: Container(
        height: 1 / MediaQuery.devicePixelRatioOf(context),
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 7),
            child: Text(
              header!.toUpperCase(),
              style: AppText.footnote.copyWith(color: secondary),
            ),
          ),
        ClipPath(
          clipper: const ShapeBorderClipper(shape: ContentCard.shape),
          child: ContentCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) separator,
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 7, 20, 0),
            child: Text(
              footer!,
              style: AppText.footnote.copyWith(color: secondary),
            ),
          ),
      ],
    );
  }
}

/// A row in a [GroupedSection]: icon, title, optional subtitle, and either a
/// [trailing] control or a [value] with a disclosure chevron.
class GroupedRow extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? value;
  final VoidCallback? onTap;
  final bool enabled;

  const GroupedRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.value,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<GroupedRow> createState() => _GroupedRowState();
}

class _GroupedRowState extends State<GroupedRow> {
  bool _pressed = false;

  bool get _tappable => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (_tappable && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final tertiary = CupertinoColors.tertiaryLabel.resolveFrom(context);
    // At accessibility text sizes (body above ~24 pt) iOS moves the value
    // under the title instead of squeezing both onto one line.
    final stacked = MediaQuery.textScalerOf(context).scale(17) > 24;
    final value = widget.value == null
        ? null
        : Text(
            widget.value!,
            style: AppText.body.tabular.copyWith(
              color: widget.enabled ? secondary : tertiary,
            ),
          );

    final row = AnimatedContainer(
      duration: Duration(milliseconds: _pressed ? 0 : 250),
      color: _pressed
          ? CupertinoColors.systemFill.resolveFrom(context)
          : const Color(0x00000000),
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppText.body.copyWith(
                    color: widget.enabled ? label : tertiary,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: AppText.footnote.copyWith(color: secondary),
                  ),
                ],
                if (value != null && stacked) ...[
                  const SizedBox(height: 2),
                  value,
                ],
              ],
            ),
          ),
          if (value != null && !stacked) ...[
            const SizedBox(width: 8),
            value,
          ],
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ] else if (_tappable) ...[
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_forward, size: 15, color: tertiary),
          ],
        ],
      ),
    );

    if (!_tappable) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: Semantics(button: true, child: row),
    );
  }
}

/// Settings-style rounded square icon: a white glyph on a colored tile.
class RowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const RowIcon(this.icon, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: CupertinoDynamicColor.resolve(color, context),
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      child: SizedBox.square(
        dimension: 30,
        child: Icon(icon, size: 18, color: CupertinoColors.white),
      ),
    );
  }
}
