import 'package:flutter/cupertino.dart';

/// The iOS text style ramp (default Dynamic Type size) set in SF Pro.
///
/// Colors are left unset so text inherits the ambient label color; tracking
/// follows Apple's SF Pro tracking table. `CupertinoSystemDisplay` is SF Pro
/// Display (20 pt and up), `CupertinoSystemText` is SF Pro Text.
class AppText {
  AppText._();

  static const _text = 'CupertinoSystemText';
  static const _display = 'CupertinoSystemDisplay';
  static const _tabular = [FontFeature.tabularFigures()];

  static const largeTitle = TextStyle(
    fontFamily: _display,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.40,
  );
  static const title1 = TextStyle(
    fontFamily: _display,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.38,
  );
  static const title2 = TextStyle(
    fontFamily: _display,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.26,
  );
  static const title3 = TextStyle(
    fontFamily: _display,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.45,
  );
  static const headline = TextStyle(
    fontFamily: _text,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.43,
  );
  static const body = TextStyle(
    fontFamily: _text,
    fontSize: 17,
    letterSpacing: -0.43,
  );
  static const callout = TextStyle(
    fontFamily: _text,
    fontSize: 16,
    letterSpacing: -0.31,
  );
  static const subheadline = TextStyle(
    fontFamily: _text,
    fontSize: 15,
    letterSpacing: -0.23,
  );
  static const footnote = TextStyle(
    fontFamily: _text,
    fontSize: 13,
    letterSpacing: -0.08,
  );
  static const caption1 = TextStyle(
    fontFamily: _text,
    fontSize: 12,
  );
  static const caption2 = TextStyle(
    fontFamily: _text,
    fontSize: 11,
    letterSpacing: 0.06,
  );

  /// The one big number a screen is about, e.g. inside a progress ring.
  static const hero = TextStyle(
    fontFamily: _display,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    fontFeatures: _tabular,
  );
}

extension TabularFigures on TextStyle {
  /// Fixed-width digits for values that change in place.
  TextStyle get tabular => copyWith(fontFeatures: AppText._tabular);
}
