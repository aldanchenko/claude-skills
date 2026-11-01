import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// A floating Liquid Glass sheet [height] points tall at the default text
/// size; it grows with Dynamic Type up to 90 % of the screen, and the form
/// inside scrolls past that. The glass is denser than the bars so whatever
/// is behind the sheet doesn't compete with it.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required double height,
  required WidgetBuilder builder,
}) {
  final grown = MediaQuery.textScalerOf(context).scale(height);
  final fitted = math.min(grown, MediaQuery.sizeOf(context).height * 0.9);
  final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
  final material =
      isDark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light;
  final body = CupertinoColors.systemGroupedBackground.resolveFrom(context);

  return GlassModalSheet.show<T>(
    context: context,
    halfSize: math.max(height, fitted),
    settings: material.copyWith(glassColor: body.withValues(alpha: 0.82)),
    builder: builder,
  );
}

/// iOS 26+ sheet header: a round close button, the title, and a round
/// checkmark that confirms (dimmed while [onConfirm] is null).
class SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  const SheetHeader({
    super.key,
    required this.title,
    required this.onCancel,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: 'Cancel',
          color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          iconColor: CupertinoColors.label.resolveFrom(context),
          onTap: onCancel,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.headline,
          ),
        ),
        _RoundButton(
          icon: CupertinoIcons.checkmark_alt,
          semanticLabel: 'Done',
          color: onConfirm == null
              ? CupertinoColors.tertiarySystemFill.resolveFrom(context)
              : CupertinoDynamicColor.resolve(AppColors.accent, context),
          iconColor: onConfirm == null
              ? CupertinoColors.tertiaryLabel.resolveFrom(context)
              : CupertinoColors.white,
          onTap: onConfirm,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(44),
        onPressed: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
