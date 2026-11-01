import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../theme/app_text.dart';

/// Capsule Liquid Glass button with an icon and a label. With a [tint] the
/// color floods the glass, like iOS 27's `.glassProminent` buttons.
class GlassPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;
  final double? width;
  final double height;

  const GlassPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
    this.width,
    this.height = 56,
  });

  static const _padding = 24.0;
  static const _iconSize = 19.0;
  static const _gap = 8.0;

  /// How wide a button must be to show [label] at full size.
  static double widthFor(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: AppText.headline),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return 2 * _padding + _iconSize + _gap + width;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final tint = this.tint == null
        ? null
        : CupertinoDynamicColor.resolve(this.tint!, context);
    final foreground = tint == null
        ? CupertinoColors.label.resolveFrom(context)
        : CupertinoColors.white;
    final material =
        isDark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light;

    return GlassButton.custom(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      label: label,
      width: width,
      height: height,
      shape: LiquidRoundedSuperellipse(borderRadius: height / 2),
      style: tint == null ? GlassButtonStyle.filled : GlassButtonStyle.prominent,
      settings: tint == null
          ? null
          : material.copyWith(glassColor: tint.withValues(alpha: 0.9)),
      glowColor: tint?.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        // A label too long for the button shrinks rather than spill out.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: _iconSize, color: foreground),
              const SizedBox(width: _gap),
              Text(label, style: AppText.headline.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
