import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Shared spacing for tab screens laid out under the floating glass bars.
class AppLayout {
  AppLayout._();

  /// Content stops growing past this width on iPad and macOS.
  static const maxContentWidth = 640.0;

  /// Height of the glass navigation bar below the status bar.
  static const navBarHeight = 44.0;

  /// Height of the floating glass tab bar capsule.
  static const tabBarHeight = 64.0;

  /// Horizontal margin that centers content in [maxContentWidth].
  static double gutter(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return math.max(16.0, (width - maxContentWidth) / 2);
  }

  /// Space the scroll content leaves for the navigation bar.
  static double topInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + navBarHeight;

  /// Space the scroll content leaves for the floating tab bar.
  static double bottomInset(BuildContext context) =>
      math.max(MediaQuery.paddingOf(context).bottom, 20.0) + tabBarHeight + 28;
}
