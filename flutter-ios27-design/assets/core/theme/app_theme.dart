import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Brightness is left unset so the app follows the system appearance.
  static const cupertino = CupertinoThemeData(
    primaryColor: AppColors.accent,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
  );

  /// The iOS 27 Liquid Glass material — denser frost, a defined rim instead
  /// of a drop shadow — for every glass surface in the app. Needs
  /// liquid_glass_widgets 1.15+; for 1.14 see the skill's references/legacy-1.14.md.
  ///
  /// Not `GlassThemeData.ios27()`: that preset also makes every glass widget
  /// premium, which draws buttons in the screen's shared glass layer — their
  /// own tint is lost, neighbours melt together, and buttons from tabs
  /// hidden in an IndexedStack show through. The bars are premium anyway.
  static const glass = GlassThemeData(
    light: GlassThemeVariant(
      settings: GlassThemeSettings.ios27Light,
      glowColors: GlassGlowColors.fallback,
    ),
    dark: GlassThemeVariant(
      settings: GlassThemeSettings.ios27Dark,
      glowColors: GlassGlowColors.fallback,
    ),
  );
}
