import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart';

/// iOS 27's hard scroll edge: a frosted strip with a hairline that fills in
/// behind the navigation bar as content scrolls under it, keeping the inline
/// title legible. With Increase Contrast on (the package's stand-in for
/// Reduce Transparency too) the strip is opaque instead of frosted.
class ScrollEdgeBar extends StatelessWidget {
  /// 0 while content rests below the bar, 1 once it runs underneath.
  final double progress;
  final double height;

  const ScrollEdgeBar({
    super.key,
    required this.progress,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    final t = progress.clamp(0.0, 1.0);
    final tint = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final hairline = CupertinoColors.separator.resolveFrom(context);
    final opaque = MediaQuery.highContrastOf(context);

    final strip = Container(
      height: height,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: (opaque ? 1 : 0.75) * t),
        border: Border(
          bottom: BorderSide(
            color: hairline.withValues(alpha: hairline.a * t),
            width: 1 / MediaQuery.devicePixelRatioOf(context),
          ),
        ),
      ),
    );

    return IgnorePointer(
      child: opaque
          ? strip
          : ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24 * t, sigmaY: 24 * t),
                child: strip,
              ),
            ),
    );
  }
}
