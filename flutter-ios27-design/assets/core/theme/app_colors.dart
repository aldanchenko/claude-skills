import 'package:flutter/cupertino.dart';

/// iOS 26/27 system colors (light / dark, and the Increase Contrast variants
/// from Apple's HIG color table). Flutter's `CupertinoColors.systemX` still
/// hold the older iOS 13–18 hues, so tints come from here; labels, fills,
/// separators and backgrounds come straight from [CupertinoColors].
///
/// Resolve before changing opacity —
/// `CupertinoDynamicColor.resolve(color, context).withValues(alpha: 0.15)` —
/// or dark mode silently gets the light color.
class AppColors {
  AppColors._();

  static const red = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFFFF383C),
    darkColor: Color(0xFFFF4245),
    highContrastColor: Color(0xFFE9152D),
    darkHighContrastColor: Color(0xFFFF6165),
  );
  static const orange = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFFFF8D28),
    darkColor: Color(0xFFFF9230),
    highContrastColor: Color(0xFFC55300),
    darkHighContrastColor: Color(0xFFFFA056),
  );
  static const yellow = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFFFFCC00),
    darkColor: Color(0xFFFFD600),
    highContrastColor: Color(0xFFA16A00),
    darkHighContrastColor: Color(0xFFFEDF43),
  );
  static const green = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFF34C759),
    darkColor: Color(0xFF30D158),
    highContrastColor: Color(0xFF008932),
    darkHighContrastColor: Color(0xFF4AD968),
  );
  static const teal = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFF00C3D0),
    darkColor: Color(0xFF00D2E0),
    highContrastColor: Color(0xFF008198),
    darkHighContrastColor: Color(0xFF3BDDEC),
  );
  static const blue = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFF0088FF),
    darkColor: Color(0xFF0091FF),
    highContrastColor: Color(0xFF1E6EF4),
    darkHighContrastColor: Color(0xFF5CB8FF),
  );
  static const indigo = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFF6155F5),
    darkColor: Color(0xFF6D7CFF),
    highContrastColor: Color(0xFF564ADE),
    darkHighContrastColor: Color(0xFFA7AAFF),
  );
  static const purple = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFFCB30E0),
    darkColor: Color(0xFFDB34F2),
    highContrastColor: Color(0xFFB02FC2),
    darkHighContrastColor: Color(0xFFEA8DFF),
  );

  /// The app's one tint: links, toggles, selected states, the primary button.
  static const accent = blue;

  /// Yellow is unreadable as text on white, so yellow text uses a deeper amber.
  static const yellowText = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color(0xFFB07A00),
    darkColor: Color(0xFFFFD600),
    highContrastColor: Color(0xFFA16A00),
    darkHighContrastColor: Color(0xFFFEDF43),
  );
}
