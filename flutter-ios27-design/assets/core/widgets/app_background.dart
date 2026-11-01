import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

/// The calm backdrop the glass bars refract: the grouped background with a
/// soft wash of [tint] from the top corner and a fainter [glow] from the
/// opposite side. The tint cross-fades when it changes, e.g. from idle to
/// working; with Reduce Motion on it switches at once.
class AppBackground extends StatelessWidget {
  final Color tint;
  final Color glow;

  /// 0 = plain grouped background, 1 = full wash.
  final double intensity;

  const AppBackground({
    super.key,
    required this.tint,
    this.glow = AppColors.indigo,
    this.intensity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final base = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final accent = CupertinoDynamicColor.resolve(glow, context);

    return ColoredBox(
      color: base,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: CupertinoDynamicColor.resolve(tint, context)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, color, _) {
          final wash = (isDark ? 0.34 : 0.26) * intensity;
          return Stack(
            fit: StackFit.expand,
            children: [
              _Glow(
                center: const Alignment(-0.9, -1.05),
                radius: 1.25,
                color: color!.withValues(alpha: wash),
              ),
              _Glow(
                center: const Alignment(1.1, 0.35),
                radius: 1.1,
                color: accent.withValues(alpha: wash * 0.45),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Alignment center;
  final double radius;
  final Color color;

  const _Glow({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: radius,
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
